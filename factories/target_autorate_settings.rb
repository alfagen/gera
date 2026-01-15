FactoryBot.define do
  factory :target_autorate_setting, class: Gera::TargetAutorateSetting do
    association :exchange_rate, factory: :gera_exchange_rate
    position_from { 1 }
    position_to { 10 }
    autorate_from { 0.5 }
    autorate_to { 1.5 }
  end
end
