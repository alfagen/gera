module Gera
  class Railtie < ::Rails::Railtie
    initializer 'gera.initialize' do
      # Убираем все валюты
      Money::Currency.all.each do |cur|
        Money::Currency.unregister cur.id.to_s
      end

      Psych.load( File.read CURRENCIES_PATH ).each { |key, cur| Money::Currency.register cur.symbolize_keys }

      # Создают константы-валюты, типа RUB, USD и тп
      Money::Currency.all.each do |cur|
        Object.const_set cur.iso_code, cur
      end

      # Gera::Hooks.init
    end
  end
end
