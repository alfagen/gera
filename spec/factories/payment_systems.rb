FactoryBot.define do
  sequence :ps_slug do |n|
    "ps_slug#{n}"
  end

  sequence :ps_name do |n|
    "ps_name#{n}"
  end

  factory :payment_system, class: GERA::PaymentSystem do
    currency { RUB }
    priority { 1 }
    letter_cod { generate :ps_slug }
    income_enabled { true }
    outcome_enabled { true }
    referal_output_enabled { true }
    content_path_slug { generate :ps_slug }
    name { generate :ps_name }

    trait :issuing_bank do
      is_issuing_bank { true }
    end

    trait :with_active_wallet do
      after(:create) do |instance|
        create :wallet, active: true, payment_system: instance
      end
    end

    trait :with_wallets do
      after(:create) do |instance|
        create :wallet, payment_system: instance
        create :wallet, active: true, payment_system: instance
      end
    end

    factory :payment_system_with_wallets, traits: [:with_wallets]
    factory :payment_system_with_active_wallet, traits: [:with_active_wallet]
  end
end
