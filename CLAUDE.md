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

### Job Architecture (ActiveJob/SolidQueue)
- **RatesJob** concern for fetching external rates
- Individual jobs for each rate source (ExmoRatesJob, BitfinexRatesJob, etc.)
- **CurrencyRatesJob** - Builds currency rate matrix from external rates
- **DirectionsRatesJob** - Calculates final direction rates with commissions
- **CreateHistoryIntervalsJob** - Aggregates historical data

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

## File Organization

- `app/models/gera/` - Core domain models
- `app/jobs/gera/` - Background jobs (ActiveJob/SolidQueue)
- `lib/gera/` - Core engine logic and utilities
- `lib/builders/` - Rate calculation builders
- `spec/` - Test suite with dummy app
