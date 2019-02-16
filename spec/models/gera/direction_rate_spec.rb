# frozen_string_literal: true

require 'spec_helper'

describe Gera::DirectionRate do
  before do
    allow(Gera::DirectionsRatesWorker).to receive :perform_async
  end

  subject { create :gera_direction_rate }

  it 'persosted' do
    expect(subject).to be_persisted
  end
end
