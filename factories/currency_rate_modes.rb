FactoryBot.define do
  factory :currency_rate_mode do
    cur_from { USD }
    cur_to { RUB }
    mode { :auto }
    association :currency_rate_mode_snapshot
  end
end
