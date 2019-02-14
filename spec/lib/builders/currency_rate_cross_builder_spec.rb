# frozen_string_literal: true

require 'spec_helper'

module Gera
  RSpec.describe CurrencyRateCrossBuilder do
    let(:cur_from) { EUR }
    let(:cur_to) { RUB }
    let(:currency_pair) { CurrencyPair.new cur_from: cur_from, cur_to: cur_to }

    let(:rate_source) { create :rate_source_cbr }
    let(:snapshot) { create :external_rate_snapshot, rate_source: rate_source }

    before do
      rate_source.update actual_snapshot_id: snapshot.id
    end

    subject { described_class.new currency_pair: currency_pair }

    context 'default cross currency' do
      let!(:external_rate1) { create :external_rate, snapshot: snapshot, cur_from: EUR, cur_to: USD }
      let!(:external_rate2) { create :external_rate, snapshot: snapshot, cur_from: USD, cur_to: RUB }
      before do
        Gera.default_cross_currency = USD
      end
      it { expect(subject.build_currency_rate).to be_a CurrencyRateBuilder::SuccessResult }
      it { expect(subject.build_currency_rate).to be_success }
    end

    context 'Gera.cross_pairs' do
      let(:cur_from) { EUR }
      let(:cur_to) { KZT }
      let!(:external_rate1) { create :external_rate, snapshot: snapshot, cur_from: EUR, cur_to: RUB }
      let!(:external_rate2) { create :external_rate, snapshot: snapshot, cur_from: RUB, cur_to: KZT }
      before do
        Gera.cross_pairs = { kzt: :rub }
      end
      it { expect(subject.build_currency_rate).to be_a CurrencyRateBuilder::SuccessResult }
      it { expect(subject.build_currency_rate).to be_success }
    end
  end
end
