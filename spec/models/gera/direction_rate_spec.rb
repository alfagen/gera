# frozen_string_literal: true

require 'spec_helper'

describe Gera::DirectionRate do
  before do
    allow(Gera::DirectionsRatesJob).to receive :perform_later

    # Mock BestChange::Service to avoid dependency issues
    best_change_service_class = Class.new do
      def initialize(exchange_rate:)
        # Mock implementation
      end

      def rows_without_kassa
        []
      end
    end
    stub_const('BestChange::Service', best_change_service_class)
  end

  subject { create :gera_direction_rate }

  it 'persosted' do
    expect(subject).to be_persisted
  end
end
