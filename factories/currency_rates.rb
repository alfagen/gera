FactoryBot.define do
  factory :currency_rate, class: Gera::CurrencyRate do
    cur_from { USD }
    cur_to { RUB }
    rate_value { 60 }
    association :snapshot, factory: :currency_rate_snapshot
    mode { :direct }
  end
end
