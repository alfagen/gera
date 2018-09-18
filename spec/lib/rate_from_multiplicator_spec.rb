require 'spec_helper'

RSpec.describe Gera::RateFromMultiplicator do
  it 'to_rate' do
    expect(1.to_rate).to be_a described_class
  end

  it 'multiplaction' do
    expect(described_class.new(60) * 20).to eq 1200
  end

  it 'build from numeric' do
    rate = described_class.new(10)

    expect(rate.out_amount).to eq 10
    expect(rate.in_amount).to eq 1
  end

  it 'build from numeric < 1' do
    rate = described_class.new(0.2)

    expect(rate.out_amount).to eq 1
    expect(rate.in_amount).to eq 5
  end
end

