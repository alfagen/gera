require 'spec_helper'

describe GERA::CurrencyRate do
  subject { create :currency_rate }
  it { expect(subject).to be_persisted }
end

