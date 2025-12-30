FactoryBot.define do
  factory :exchange_rate_limit, class: Gera::ExchangeRateLimit do
    association :exchange_rate, factory: :gera_exchange_rate
  end
end
