# Gera Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] - 2026-01-20

### Added
- **Position-aware autorate calculator** - New algorithm that prevents "jumping over" positions above target range
  - Strategy pattern implementation with `Legacy` and `PositionAware` calculators
  - Calculator selection via `calculator_type` field in ExchangeRate
  - Use cases:
    - UC-1..UC-4: Basic logic without position jumping
    - UC-6: Adaptive GAP for dense ratings
    - UC-8: Exclude own exchanger from calculation (via `Gera.our_exchanger_id`)
    - UC-9: Protection from manipulators with anomalous rates
- **Migration from Sidekiq to ActiveJob** - Complete migration of background jobs
- **Manul API integration** - Use Manul instead of BestChange::Service for external rates
- **Development tools**:
  - Added Makefile for common development tasks
  - Added docker-compose.yml for containerized development
  - Added development documentation in README

### Changed
- **Breaking**: `RateComissionCalculator` now uses strategy pattern instead of inline logic
- **Breaking**: Background jobs migrated from Sidekiq to ActiveJob
- Optimized `DirectionsRatesJob` with batch INSERT instead of individual queries
- Optimized `current_base_rate` query to use existing index
- Improved error handling for missing currency rates (warning instead of error)

### Fixed
- Added proper error handling for unknown calculator types
- Fixed `DirectionRatesRepository` to includes exchange_rate properly

## [1.1.0] - 2025-01-xx

### Added
- SolidQueue integration for recurring tasks
- Configuration options for direction rate history intervals

### Fixed
- Lambda arity for concurrency limits in SolidQueue

## [1.0.0] - 2024-01-xx

### Added
- Initial stable release
- Currency rates generation and management
- BestChange integration
- Payment systems support
