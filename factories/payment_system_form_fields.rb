FactoryBot.define do
  factory :payment_system_form_field do
    payment_system { nil }
    key { "MyString" }
    is_required { false }
  end
end
