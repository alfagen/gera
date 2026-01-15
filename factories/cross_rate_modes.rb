FactoryBot.define do
  factory :cross_rate_mode, class: Gera::CrossRateMode do
    cur_from { 'BTC' }
    cur_to { 'USD' }
    association :currency_rate_mode
    rate_source { nil }
  end
end
