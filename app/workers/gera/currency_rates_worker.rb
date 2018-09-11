# Строит текущие базовые курсы на основе источников и методов расчета

module GERA
  class CurrencyRatesWorker
    include Sidekiq::Worker
    include AutoLogger

    Error = Class.new StandardError

    def perform
      logger.info 'start'

      GERA::CurrencyRate.transaction do
        @snapshot = create_snapshot

        CryptoMath::CurrencyPair.all.each do |pair|
          create_rate pair
        end
      end

      logger.info 'finish'

      if Rails.env.development? || Rails.env.test?
        DirectionsRatesWorker.new.perform
      else
        DirectionsRatesWorker.perform_async
      end

      true
    end

    private

    attr_reader :snapshot

    def create_snapshot
      GERA::CurrencyRateSnapshot.create! currency_rate_mode_snapshot: GERA::Universe.currency_rate_modes_repository.snapshot
    end

    def create_rate pair
      crm =  GERA::Universe.currency_rate_modes_repository.find_currency_rate_mode_by_pair pair

      logger.debug "build_rate(#{pair}, #{crm || :default})"

      crm ||= GERA::CurrencyRateMode.new(currency_pair: pair, mode: :auto).freeze

      cr = crm.build_currency_rate

      raise Error, "Не смог посчитать курс #{pair} для режима '#{crm.try :mode}'" unless cr.present?

      cr.snapshot = snapshot
      cr.save!
    rescue => err
      logger.error err
      Rails.logger.error err if Rails.env.development?
      Bugsnag.notify err do |b|
        b.meta_data = { pair: pair }
      end
    end
  end
end
