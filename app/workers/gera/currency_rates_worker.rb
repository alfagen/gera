module GERA
  #
  # Строит текущие базовые курсы на основе источников и методов расчета
  #
  class CurrencyRatesWorker
    include Sidekiq::Worker
    include AutoLogger

    Error = Class.new StandardError

    def perform
      logger.info 'start'

      CurrencyRate.transaction do
        @snapshot = create_snapshot

        CryptoMath::CurrencyPair.all.each do |pair|
          create_rate pair
        end
      end

      logger.info 'finish'

      # Запускаем перерасчет конечных курсов
      #
      DirectionsRatesWorker.perform_async

      true
    end

    private

    attr_reader :snapshot

    def create_snapshot
      CurrencyRateSnapshot.create! currency_rate_mode_snapshot: Universe.currency_rate_modes_repository.snapshot
    end

    def create_rate pair
      crm =  Universe.currency_rate_modes_repository.find_currency_rate_mode_by_pair pair

      logger.debug "build_rate(#{pair}, #{crm || :default})"

      crm ||= CurrencyRateMode.new(currency_pair: pair, mode: :auto).freeze

      cr = crm.build_currency_rate

      raise Error, "Не смог посчитать курс #{pair} для режима '#{crm.try :mode}'" unless cr.present?

      cr.snapshot = snapshot
      cr.save!
    rescue => err
      raise err if !err.is_a?(Error) && Rails.env.test?
      logger.error err
      Rails.logger.error err if Rails.env.development?
      Bugsnag.notify err do |b|
        b.meta_data = { pair: pair }
      end if defined? Bugsnag
    end
  end
end
