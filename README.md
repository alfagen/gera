# Gera

[![RSpec Tests](https://github.com/alfagen/gera/actions/workflows/rspec.yml/badge.svg)](https://github.com/alfagen/gera/actions/workflows/rspec.yml)

Multiple rates generator for crypto changers and markets.

## Осуществляет

* Регулярный (ежесекундный) сбор и хранение курсов (`ExternalRate`) из внешних источников (`RateSource`)
* Построение и хранение матрицы базовых курсов (`CurrencyRate`) для поддерживаемых валют из курсов внешних истичников (`ExternalRate`) на основе установленного метода расчета (`CurrencyRateMode`) автоматически или через кросс-курсы.
* Построение и хранение матрицы конечных курсов (`DirectionRate`) для поддерживаемых платежных сервисов (`PaymentSystem`) с установленной комиссией (`ExchangeRate`) 
* Регулярная группировка базовых и конечных курсов в N-минутные отрезки со свечками для истории (`CurrencyRateHistoryInterval` и `DirectionRateHistoryInterval`)
* Регулярная очистка матриц ежесекундных курсов (за сутки накапливается несколько гигабайт)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'gera'
```

And then execute:
```bash
$ bundle
```

Or install it yourself as:
```bash
$ gem install gera
```

## Configuration

Add `./config/initializers/gera.rb` with this content:

```
Gera.configure do |config|
  config.cross_pairs = { kzt: :rub, eur: :rub }
end
```

## Supported external sources of basic rates

* EXMO, Russian Central Bank, Bitfinex, Manual

## Supported currencies

* RUB, USD, BTC, LTC, ETH, DSH, KZT, XRP, ETC, XMR, BCH, EUR, NEO, ZEC

## Database 

SQL tables diagram - https://github.com/finfex/gera/blob/master/doc/erd.pdf

## TODO

* move Authority to application level
* Remove STI from RateSource

## Contributing

* Fork
* Create Pull Request

## License

The gem is available as open source under the terms of the [GPLv3](https://opensource.org/licenses/GPL-3.0).
