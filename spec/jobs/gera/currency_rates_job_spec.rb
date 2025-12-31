# frozen_string_literal: true

require 'spec_helper'

module Gera
  RSpec.describe CurrencyRatesJob do
    it do
      expect(CurrencyRatesJob.new.perform).to be_truthy
    end

    describe 'graceful handling when rate cannot be calculated' do
      let(:job) { CurrencyRatesJob.new }
      let(:pair) { CurrencyPair.new(cur_from: Money::Currency.find(:usd), cur_to: Money::Currency.find(:rub)) }
      let(:currency_rate_mode) { instance_double(CurrencyRateMode, mode: 'auto', build_currency_rate: nil) }
      let(:snapshot) { instance_double(CurrencyRateSnapshot) }
      let(:logger) { instance_double(Logger) }

      before do
        allow(job).to receive(:find_currency_rate_mode_by_pair).with(pair).and_return(currency_rate_mode)
        allow(job).to receive(:logger).and_return(logger)
        allow(logger).to receive(:debug)
        allow(logger).to receive(:warn)
      end

      it 'logs warning and continues without raising error' do
        expect(logger).to receive(:warn).with(/Unable to calculate rate for.*auto/)

        job.send(:create_rate, pair: pair, snapshot: snapshot)
      end

      it 'does not notify Bugsnag for missing rates' do
        if defined?(Bugsnag)
          expect(Bugsnag).not_to receive(:notify)
        end

        job.send(:create_rate, pair: pair, snapshot: snapshot)
      end
    end
  end
end
