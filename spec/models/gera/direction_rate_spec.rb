require 'spec_helper'

describe GERA::DirectionRate do
  before do
    allow( GERA::DirectionsRatesWorker ).to receive :perform_async
  end
  subject { create :direction_rate }
  it do
    expect(subject).to be_persisted
  end
end
