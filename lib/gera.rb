require 'money'
require 'crypto_math'
require 'crypto_math/root'
require 'require_all'

require 'sidekiq'
require 'auto_logger'

require "gera/engine"
require "gera/version"

require_rel 'banks'
require_rel 'builders'
require_rel 'gera/repositories'

require 'gera/bitfinex_fetcher'

module GERA
  FACTORY_PATH = File.expand_path("../spec/factories", __dir__)

end

Gera = GERA
