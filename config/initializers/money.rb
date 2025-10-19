# frozen_string_literal: true

if defined?(MoneyRails)
  MoneyRails.configure do |config|
  # To set the default currency
  #
  # config.default_currency = :usd

  # Set default bank object
  #
  # Example:
  # config.default_bank = EuCentralBank.new

  # Add exchange rates to current money bank object
  #
  # config.add_rate = "USD", "CAD", 1.24500
  # config.add_rate = "CAD", "USD", 0.803225

  # To handle the inclusion of validations for monetized fields
  #
  # config.include_validations = true

  # Default ActiveRecord migration configuration values for columns
  #
  # config.amount_column = { prefix: '',           # column name prefix
  #                          postfix: '_cents',    # column name  postfix
  #                          column_name: nil,     # full column name (overrides prefix, postfix and accessor name)
  #                          type: :integer,       # column type
  #                          present: true,        # column will be created
  #                          null: false,          # other options will be treated as column options
  #                          default: 0
  #                        }
  #
  # config.currency_column = { prefix: '',
  #                            postfix: '_currency',
  #                            column_name: nil,
  #                            type: :string,
  #                            present: true,
  #                            null: false,
  #                            default: nil
  #                          }

  # Register a custom currency
  #
  # config.register_currency = { priority: 1,
  #                             iso_code: "BTC",
  #                             name: "Bitcoin",
  #                             symbol: "BTC",
  #                             symbol_first: true,
  #                             subunit: "Satoshi",
  #                             subunit_to_unit: 100000000,
  #                             thousands_separator: ',',
  #                             decimal_mark: "."
  #                           }

  # Specify a rounding mode
  #
  # Any rounding mode from the Ruby BigDecimal library is supported
  # :default, :half_up, :half_down, :half_even, :banker, :truncate, :floor, :ceiling
  #
  # config.rounding_mode = BigDecimal::ROUND_HALF_EVEN

  # Set default money format globally
  #
  # config.default_format = {
  #   no_cents_if_whole: nil,
  #   symbol: nil,
  #   sign_before_symbol: nil
  # }

  # If you would like to use i18n localization (formatting depends on the
  # locale):
  # config.locale_backend = :i18n
  #
  # Example (using default locale from config.i18n.default_locale):
  #   Money.new(10_00, 'USD').format # => "$10.00"
  #   Money.new(10_00, 'EUR').format # => "10,00 €"
  #
  # Example (using locale from I18n.locale):
  #   I18n.locale = :de
  #   Money.new(10_00, 'USD').format # => "10,00 $"
  #   Money.new(10_00, 'EUR').format # => "10,00 €"
  #
  # Example (using a custom locale):
  #   Money.new(10_00, 'USD').format(locale: :fr) #=> "10,00 $US"
  #
  # For legacy behaviour of :locale => false (no localization), set locale_backend to :legacy
  # config.locale_backend = :legacy

  # Set default raise_error_on_money_parsing option
  # When set to true, will raise an error if parsing invalid money strings
  #
  # config.raise_error_on_money_parsing = false

  # Configuration for货币化
  config.no_cents_if_whole = true
  config.symbol = true
  end
end