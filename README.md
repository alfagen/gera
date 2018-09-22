# Gera

Генератор курсов для крипто-обменников и бирж.

Осуществляет:

* Регулярный (ежесекундный) сбор и хранение курсов (`ExternalRate`) из внешних источников (`RateSource`)
* Построение и хранение матрицы базовых курсов (`CurrencyRate`) для поддерживаемых валют из курсов внешних истичников (`ExternalRate`) на основе установленного метода расчета (`CurrencyRateMode`) автоматически или через кросс-курсы.
* Построение и хранение матрицы конечных курсов (`DirectionRate`) для поддерживаемых платежных сервисов (`PaymentSystem`) с установленной комиссией (`ExchangeRate`) 
* Регулярная группировка базовых и конечных курсов в N-минутные отрезки со свечками для истории (`CurrencyRateHistoryInterval` и `DirectionRateHistoryInterval`)
* Регулярная очистка матриц ежесекундных курсов (за сутки накапливается несколько гигабайт)

## Внешние источники базовых курсов

* EXMO, ЦБ РФ, Bitfinex, Ручной

## Валюты

* RUB, USD, BTC, LTC, ETH, DSH, KZT, XRP, ETC, XMR, BCH, EUR, NEO, ZEC

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

## TODO

* Уйти от STI в RateSource

## Contributing
Contribution directions go here.

## License
The gem is available as open source under the terms of the [GPLv3](https://opensource.org/licenses/GPL-3.0).
