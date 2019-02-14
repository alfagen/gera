# frozen_string_literal: true

require 'spec_helper'

describe Gera::CurrencyRate do
  subject { create :currency_rate }
  it 'persisted' do
    expect(subject).to be_persisted
  end
end
