FactoryBot.define do
  factory :exchange_rate do

    # Другое решение, стратегия find_or_create
    # https://gist.github.com/hiasinho/0ed0567dfc091047dc26
    #
    initialize_with { ExchangeRate.find_or_create_by(payment_system_from: payment_system_from, payment_system_to: payment_system_to) }
    association :payment_system_from, factory: :payment_system, currency: USD
    association :payment_system_to, factory: :payment_system, currency: RUB
    value_ps { 10 }

    is_enabled { true }

    trait :with_active_wallets do
      association :payment_system_from, factory: :payment_system_with_active_wallet, currency: USD
      association :payment_system_to, factory: :payment_system_with_active_wallet, currency: RUB
    end

    factory :exchange_rate_with_active_wallets, traits: [:with_active_wallets]
  end
end
