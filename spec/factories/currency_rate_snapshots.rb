FactoryBot.define do
  factory :currency_rate_snapshot, class: GERA::CurrencyRateSnapshot do
    association :currency_rate_mode_snapshot
  end
end
