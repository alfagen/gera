FactoryBot.define do
  factory :currency_rate_snapshot, class: Gera::CurrencyRateSnapshot do
    association :currency_rate_mode_snapshot
  end
end
