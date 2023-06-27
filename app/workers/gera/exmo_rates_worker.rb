# frozen_string_literal: true

module Gera
  # Import rates from EXMO
  #
  class ExmoRatesWorker
    include Sidekiq::Worker
    include AutoLogger

    prepend RatesWorker

    sidekiq_options lock: :until_executed

    private

    def rate_source
      @rate_source ||= RateSourceExmo.get!
    end

    # data contains
    # {"buy_price"=>"8734.99986728",
    # "sell_price"=>"8802.299431",
    # "last_trade"=>"8789.71226599",
    # "high"=>"9367.055011",
    # "low"=>"8700.00000001",
    # "avg"=>"8963.41293922",
    # "vol"=>"330.70358291",
    # "vol_curr"=>"2906789.33918745",
    # "updated"=>1520415288},

    def save_rate(currency_pair, data)
      create_external_rates(currency_pair, data, sell_price: data['sell_price'], buy_price: data['buy_price'])
    end

    def load_rates
      ExmoFetcher.new.perform
    end
  end
end
