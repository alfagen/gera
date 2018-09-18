require 'spec_helper'

describe Gera::CurrencyRate do
  subject { create :currency_rate }
  it { expect(subject).to be_persisted }
end

