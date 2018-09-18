FactoryBot.define do
  factory :external_rate, class: Gera::ExternalRate do
    cur_from { "USD" }
    cur_to { "RUB" }
    rate_value { 1.5 }
  end
end
