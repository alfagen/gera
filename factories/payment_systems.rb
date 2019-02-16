FactoryBot.define do
  factory :gera_payment_system, class: Gera::PaymentSystem do
    currency { RUB }
    priority { 1 }
    income_enabled { true }
    outcome_enabled { true }
    sequence(:name) { |n| "name#{n}" }
  end
end
