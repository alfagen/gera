FactoryBot.define do
  sequence :crms_title do |n|
    "title#{n}"
  end

  factory :currency_rate_mode_snapshot do
    title { generate :crms_title }
  end
end