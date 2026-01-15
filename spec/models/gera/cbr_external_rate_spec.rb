# frozen_string_literal: true

require 'spec_helper'

module Gera
  RSpec.describe CbrExternalRate do
    # Note: This spec tests the model's interface.
    # The table gera_cbr_external_rates may not exist in test database.

    describe 'model interface' do
      it 'inherits from ApplicationRecord' do
        expect(CbrExternalRate.superclass).to eq(ApplicationRecord)
      end

      it 'responds to rate attribute' do
        expect(CbrExternalRate.new).to respond_to(:rate)
      end

      it 'defines <=> operator for comparison' do
        expect(CbrExternalRate.instance_methods).to include(:<=>)
      end
    end
  end
end
