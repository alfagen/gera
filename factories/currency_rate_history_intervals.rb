FactoryBot.define do
  factory :currency_rate_history_interval, class: Gera::CurrencyRateHistoryInterval do
    cur_from_id { 1 }
    cur_to_id { 1 }
    min_rate { 1.5 }
    avg_rate { 1.5 }
    max_rate { 1.5 }
    at { "2018-03-29 21:27:01" }
  end
end
