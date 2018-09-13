# Загрузка курсов из EXMO
#
class EXMORatesWorker
  include Sidekiq::Worker
  prepend UniqueWorker
  prepend RatesWorker
  include AutoLogger

  URL1 = 'https://api.exmo.com/v1/ticker/'.freeze
  URL2 = 'https://api.exmo.me/v1/ticker/'.freeze
  URL = URL2

  private

  def rate_source
    @rate_source ||= RateSource.exmo
  end

  # Содержимое data
  #{"buy_price"=>"8734.99986728",
  #"sell_price"=>"8802.299431",
  #"last_trade"=>"8789.71226599",
  #"high"=>"9367.055011",
  #"low"=>"8700.00000001",
  #"avg"=>"8963.41293922",
  #"vol"=>"330.70358291",
  #"vol_curr"=>"2906789.33918745",
  #"updated"=>1520415288},

  def save_rate(raw_pair, data)
    # TODO У EXMO такая причуда с DASH/DSH лучше это вынести в ExmoRatesWorker
    #
    cf, ct = raw_pair.split('_') .map { |c| c == 'DASH' ? 'DSH' : c }

    cur_from = Money::Currency.find cf
    unless cur_from
      logger.warn "Not supported currency #{cf}"
      return
    end

    cur_to = Money::Currency.find ct
    unless cur_to
      logger.warn "Not supported currency #{ct}"
      return
    end

    currency_pair = CurrencyPair.new cur_from, cur_to
    create_external_rates currency_pair, data, sell_price: data['sell_price'], buy_price: data['buy_price']
  end

  def load_rates
    result = JSON.parse open(URI.parse URL).read
    raise Error.new('Результат не хеш') unless result.is_a? Hash
    raise Error.new(result['error']) if result['error'].present?
    result
  end
end
