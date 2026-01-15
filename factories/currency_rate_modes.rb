FactoryBot.define do
  factory :currency_rate_mode, class: Gera::CurrencyRateMode do
    cur_from { USD }
    cur_to { RUB }
    mode { :auto }
    association :snapshot, factory: :currency_rate_mode_snapshot
  end
end
