# frozen_string_literal: true

require 'spec_helper'

module Gera
  RSpec.describe CurrencyRatesJob do
    it do
      expect(CurrencyRatesJob.new.perform).to be_truthy
    end
  end
end
