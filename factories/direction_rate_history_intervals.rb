FactoryBot.define do
  factory :direction_rate_history_interval do
    payment_system_from { nil }
    payment_system_to { nil }
    mim_finite_rate { 1.5 }
    max_finite_rate { 1.5 }
    min_comission { 1.5 }
    max_comission { 1.5 }
    interval_from { "2018-07-13 19:30:19" }
    interval_to { "2018-07-13 19:30:19" }
  end
end
