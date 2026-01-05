# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Gera is a Rails engine for generating and managing currency exchange rates for crypto changers and markets. It collects rates from external sources, builds currency rate matrices, and calculates final rates for payment systems with commissions.

## Core Architecture

### Rate Flow Hierarchy
1. **ExternalRate** - Raw rates from external sources (EXMO, Bitfinex, Binance, CBR, etc.)
2. **CurrencyRate** - Basic currency rates calculated from external rates using different modes (direct, inverse, cross)
3. **DirectionRate** - Final rates for specific payment system pairs with commissions applied
4. **ExchangeRate** - Configuration for commissions between payment systems

### Key Models
- **RateSource** - External rate providers with STI subclasses (RateSourceExmo, RateSourceBitfinex, etc.)
- **PaymentSystem** - Payment systems with currencies and commissions
- **CurrencyPair** - Utility class for currency pair operations
- **Universe** - Central repository pattern for accessing rate data

### Worker Architecture
- **RatesWorker** concern for fetching external rates
- Individual workers for each rate source (ExmoRatesWorker, BitfinexRatesWorker, etc.)
- **CurrencyRatesWorker** - Builds currency rate matrix from external rates
- **DirectionsRatesWorker** - Calculates final direction rates with commissions
- **CreateHistory_intervalsWorker** - Aggregates historical data

## Development Commands

### Running Tests
```bash
# Run all tests
bundle exec rake spec

# Run specific test file
bundle exec rspec spec/models/gera/currency_rate_spec.rb

# Run with focus
bundle exec rspec --tag focus
```

### Building and Development
```bash
# Install dependencies
bundle install

# Run dummy app for testing
cd spec/dummy && rails server

# Generate documentation
bundle exec yard

# Clean database between tests (uses DatabaseRewinder)
```

### Code Quality
```bash
# Lint code
bundle exec rubocop

# Auto-correct linting issues
bundle exec rubocop -a
```

## Configuration

Create `./config/initializers/gera.rb`:
```ruby
Gera.configure do |config|
  config.cross_pairs = { kzt: :rub, eur: :rub }
  config.default_cross_currency = :usd
end
```

## Key Business Logic

### Rate Calculation Modes
- **direct** - Direct rate from external source
- **inverse** - Inverted rate (1/rate)
- **same** - Same currency (rate = 1)
- **cross** - Calculated through intermediate currency

### Supported Currencies
RUB, USD, BTC, LTC, ETH, DSH, KZT, XRP, ETC, XMR, BCH, EUR, NEO, ZEC

### External Rate Sources
- EXMO, Bitfinex, Binance, GarantexIO
- Russian Central Bank (CBR)
- Manual rates and FF (fixed/float) sources

## Testing Notes

- Uses dummy Rails app in `spec/dummy/`
- Factory Bot for test data in `factories/`
- VCR for HTTP request mocking
- Database Rewinder for fast test cleanup
- Sidekiq testing inline enabled

### Запуск изолированных тестов автокурсов

Для тестов автокурсов (PositionAware, Legacy калькуляторы) используются изолированные тесты,
которые не загружают Rails и spec_helper. Это позволяет быстро тестировать логику без полной
загрузки приложения.

```bash
# Переименовать .rspec чтобы не загружался spec_helper
mv .rspec .rspec.bak

# Запустить изолированные тесты
mise exec -- bundle exec rspec spec/services/gera/autorate_calculators/isolated_spec.rb --no-color

# Вернуть .rspec обратно
mv .rspec.bak .rspec
```

Или используйте Makefile (требует БД):
```bash
make test  # запускает isolated_spec.rb и exchange_rate_spec.rb
```

**Важно:** Файл `isolated_spec.rb` самодостаточен и содержит все необходимые стабы для Gera модуля.

## File Organization

- `app/models/gera/` - Core domain models
- `app/workers/gera/` - Background job workers
- `lib/gera/` - Core engine logic and utilities
- `lib/builders/` - Rate calculation builders
- `spec/` - Test suite with dummy app


## stage сервер

На stage сервере логи находятся тут:

```
scp kassa@89.248.193.193:/home/kassa/admin.kassa.cc/current/log/* .
```

# Requirements Management

- **spreadsheet_id:** 1bY_cH5XpuO47qnPsYEdxjkQpwvPNYXHAms_ohkca15A
- **spreadsheet_url:** https://docs.google.com/spreadsheets/d/1bY_cH5XpuO47qnPsYEdxjkQpwvPNYXHAms_ohkca15A
