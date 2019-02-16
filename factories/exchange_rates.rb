FactoryBot.define do
  factory :gera_exchange_rate, class: Gera::ExchangeRate do

    # Другое решение, стратегия find_or_create
    # https://gist.github.com/hiasinho/0ed0567dfc091047dc26
    #
    initialize_with { Gera::ExchangeRate.find_or_create_by(payment_system_from: payment_system_from, payment_system_to: payment_system_to) }

    association :payment_system_from, factory: :gera_payment_system, currency: Money::Currency.find('USD')
    association :payment_system_to, factory: :gera_payment_system, currency: Money::Currency.find('RUB')
    value { 10 }

    is_enabled { true }
  end
end
