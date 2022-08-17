FactoryBot.define do
  factory :external_rate, class: Gera::ExternalRate do
    cur_from { "ETH" }
    cur_to { "BTC" }
    rate_value { 1.5 }
  end
  factory :inverse_external_rate, class: Gera::ExternalRate do
    cur_from { "BTC" }
    cur_to { "ETH" }
    rate_value { 1.5 }
  end
end
