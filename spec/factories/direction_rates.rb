FactoryBot.define do
  factory :direction_rate do
    association :exchange_rate, is_enabled: true

    # Universe.currency_rates_repository.find_currency_rate_by_pair(exchange_rate.currency_pair)
    association :currency_rate, cur_from: USD, cur_to: RUB
    comission { 10 }

    trait :with_active_wallets do
      association :exchange_rate, is_enabled: true, factory: :exchange_rate_with_active_wallets
    end

    factory :direction_rate_with_active_wallets, traits: [:with_active_wallets]
  end
end
