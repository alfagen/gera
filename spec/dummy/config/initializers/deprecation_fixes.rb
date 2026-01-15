# frozen_string_literal: true

# Fix Rails 8.1 deprecation warnings
Rails.application.configure do
  # Fix to_time deprecation warning
  config.active_support.to_time_preserves_timezone = :zone
end

# Fix Money gem warnings (after Rails config is loaded)
ActiveSupport.on_load(:after_initialize) do
  Money.rounding_mode = BigDecimal::ROUND_HALF_UP

  # Set default currency to avoid warning
  Money.default_currency = Money::Currency.new('USD') if Money.respond_to?(:default_currency=)
end