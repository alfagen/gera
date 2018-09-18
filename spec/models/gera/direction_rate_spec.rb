require 'spec_helper'

describe Gera::DirectionRate do
  before do
    allow( Gera::DirectionsRatesWorker ).to receive :perform_async
  end
  subject { create :direction_rate }
  it do
    expect(subject).to be_persisted
  end
end
