# frozen_string_literal: true

module Gera
  # Загрузка курсов из EXMO
  #
  class BitfinexRatesWorker
    include Sidekiq::Worker
    include AutoLogger

    prepend RatesWorker

    # Stolen from: https://api.bitfinex.com/v1/symbols
    AVAILABLE_TICKETS = %i[btcusd ltcusd ltcbtc ethusd ethbtc etcbtc etcusd rrtusd rrtbtc zecusd zecbtc xmrusd xmrbtc dshusd dshbtc btceur btcjpy xrpusd xrpbtc iotusd iotbtc ioteth eosusd eosbtc eoseth sanusd sanbtc saneth omgusd omgbtc omgeth neousd neobtc neoeth etpusd etpbtc etpeth qtmusd qtmbtc qtmeth avtusd avtbtc avteth edousd edobtc edoeth btgusd btgbtc datusd datbtc dateth qshusd qshbtc qsheth yywusd yywbtc yyweth gntusd gntbtc gnteth sntusd sntbtc snteth ioteur batusd batbtc bateth mnausd mnabtc mnaeth funusd funbtc funeth zrxusd zrxbtc zrxeth tnbusd tnbbtc tnbeth spkusd spkbtc spketh trxusd trxbtc trxeth rcnusd rcnbtc rcneth rlcusd rlcbtc rlceth aidusd aidbtc aideth sngusd sngbtc sngeth repusd repbtc repeth elfusd elfbtc elfeth btcgbp etheur ethjpy ethgbp neoeur neojpy neogbp eoseur eosjpy eosgbp iotjpy iotgbp iosusd iosbtc ioseth aiousd aiobtc aioeth requsd reqbtc reqeth rdnusd rdnbtc rdneth lrcusd lrcbtc lrceth waxusd waxbtc waxeth daiusd daibtc daieth agiusd agibtc agieth bftusd bftbtc bfteth mtnusd mtnbtc mtneth odeusd odebtc odeeth antusd antbtc anteth dthusd dthbtc dtheth mitusd mitbtc miteth stjusd stjbtc stjeth xlmusd xlmeur xlmjpy xlmgbp xlmbtc xlmeth xvgusd xvgeur xvgjpy xvggbp xvgbtc xvgeth bciusd bcibtc mkrusd mkrbtc mkreth kncusd kncbtc knceth poausd poabtc poaeth lymusd lymbtc lymeth utkusd utkbtc utketh veeusd veebtc veeeth dadusd dadbtc dadeth orsusd orsbtc orseth aucusd aucbtc auceth poyusd poybtc poyeth fsnusd fsnbtc fsneth cbtusd cbtbtc cbteth zcnusd zcnbtc zcneth senusd senbtc seneth ncausd ncabtc ncaeth cndusd cndbtc cndeth ctxusd ctxbtc ctxeth paiusd paibtc seeusd seebtc seeeth essusd essbtc esseth atmusd atmbtc atmeth hotusd hotbtc hoteth dtausd dtabtc dtaeth iqxusd iqxbtc iqxeos wprusd wprbtc wpreth zilusd zilbtc zileth bntusd bntbtc bnteth absusd abseth xrausd xraeth manusd maneth bbnusd bbneth niousd nioeth dgxusd dgxeth vetusd vetbtc veteth utnusd utneth tknusd tkneth gotusd goteur goteth xtzusd xtzbtc cnnusd cnneth boxusd boxeth trxeur trxgbp trxjpy mgousd mgoeth rteusd rteeth yggusd yggeth mlnusd mlneth wtcusd wtceth csxusd csxeth omnusd omnbtc intusd inteth drnusd drneth pnkusd pnketh dgbusd dgbbtc bsvusd bsvbtc babusd babbtc wlousd wloxlm vldusd vldeth enjusd enjeth onlusd onleth rbtusd rbtbtc ustusd euteur eutusd gsdusd udcusd tsdusd paxusd rifusd rifbtc pasusd paseth vsyusd vsybtc zrxdai mkrdai omgdai bttusd bttbtc btcust ethust clousd clobtc].freeze

    TICKERS = %i[neousd neobtc neoeth neoeur].freeze

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
      CurrencyPair.new ticker[0, 3], ticker[3, 3]
    end

    def load_rates
      TICKERS.each_with_object({}) { |ticker, ag| ag[ticker] = BitfinexFetcher.new(ticker: ticker).perform }
    end
  end
end
