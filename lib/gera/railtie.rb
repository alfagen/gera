require 'gera/money_support'
module Gera
  class Railtie < ::Rails::Railtie
    initializer 'gera.initialize' do
      MoneySupport.init
    end
  end
end
