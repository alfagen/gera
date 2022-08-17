FactoryBot.define do
  factory :external_rate_snapshot, class: Gera::ExternalRateSnapshot do
    actual_for { Date.yesterday }
  end
end
