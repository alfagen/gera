module GERA
  # Загрузка курсов из EXMO
  #
  class BitfinexRatesWorker
    include Sidekiq::Worker
    include AutoLogger

    prepend RatesWorker

    # Stolen from: https://api.bitfinex.com/v1/symbols
    TICKERS = %i(neousd neobtc neoeth neoeur)

    private

    def rate_source
      @rate_source ||= RateSourceBitfinex.get!
    end

    # {"mid":"8228.25",
    # "bid":"8228.2",
    # "ask":"8228.3",
    # "last_price":"8228.3",
    # "low":"8055.0",
    # "high":"8313.3",
    # "volume":"13611.826947359996",
    # "timestamp":"1532874580.9087598"}
    def save_rate(ticker, data)
      currency_pair = pair_from_ticker ticker
      create_external_rates currency_pair, data, sell_price: data['high'], buy_price: data['low']
    end

    def pair_from_ticker(ticker)
      ticker = ticker.to_s
      CurrencyPair.new ticker[0,3], ticker[3,3]
    end

    def load_rates
      TICKERS.each_with_object({}) { |ticker, ag| ag[ticker] = BitfinexFetcher.new(ticker: ticker).perform }
    end
  end
end
