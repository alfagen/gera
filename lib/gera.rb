require 'money'
require 'require_all'
require 'percentable'

require 'sidekiq'
require 'auto_logger'

require "gera/version"
require 'gera/numeric'

require "gera/configuration"
require "gera/mathematic"
require 'gera/bitfinex_fetcher'
require 'gera/binance_fetcher'
require 'gera/exmo_fetcher'
require 'gera/garantexio_fetcher'
require 'gera/bybit_fetcher'
require 'gera/cryptomus_fetcher'
require 'gera/ff_fixed_fetcher'
require 'gera/ff_float_fetcher'
require 'gera/currency_pair'
require 'gera/rate'
require 'gera/money_support'


module Gera
  CURRENCIES_PATH = File.expand_path("../config/currencies.yml", __dir__)

  extend Configuration
end

require_rel 'banks'
require_rel 'builders'
require_rel 'gera/repositories'

if defined? ::Rails::Railtie
  require "gera/engine"
  require "gera/railtie"
end
