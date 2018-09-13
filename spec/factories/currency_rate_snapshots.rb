FactoryBot.define do
  factory :currency_rate_snapshot do
    association :currency_rate_mode_snapshot
  end
end
