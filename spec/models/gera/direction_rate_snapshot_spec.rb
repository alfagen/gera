# frozen_string_literal: true

require 'spec_helper'

module Gera
  RSpec.describe DirectionRateSnapshot do
    describe 'associations' do
      let(:snapshot) { create(:direction_rate_snapshot) }

      it 'has many direction_rates' do
        expect(snapshot).to respond_to(:direction_rates)
      end
    end

    describe 'persistence' do
      it 'can be created' do
        snapshot = DirectionRateSnapshot.create!
        expect(snapshot).to be_persisted
      end
    end
  end
end
