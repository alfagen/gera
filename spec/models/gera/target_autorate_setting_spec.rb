# frozen_string_literal: true

require 'spec_helper'

module Gera
  RSpec.describe TargetAutorateSetting do
    # Note: This spec tests the model's interface.
    # The table gera_target_autorate_settings may not exist in test database.

    describe 'model interface' do
      it 'inherits from ApplicationRecord' do
        expect(TargetAutorateSetting.superclass).to eq(ApplicationRecord)
      end

      it 'is defined as a class' do
        expect(TargetAutorateSetting).to be_a(Class)
      end

      it 'has exchange_rate association defined' do
        expect(TargetAutorateSetting.reflect_on_association(:exchange_rate)).to be_present
      end

      it 'defines could_be_calculated? method' do
        expect(TargetAutorateSetting.instance_methods).to include(:could_be_calculated?)
      end
    end
  end
end
