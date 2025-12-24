# frozen_string_literal: true

# Полностью изолированные тесты - не загружают Rails и spec_helper

require 'rspec'
require 'virtus'

# Загружаем только необходимые файлы
$LOAD_PATH.unshift File.expand_path('../../../../app/services', __dir__)
$LOAD_PATH.unshift File.expand_path('../../../../lib', __dir__)

require 'gera/autorate_calculators/base'
require 'gera/autorate_calculators/legacy'
require 'gera/autorate_calculators/position_aware'

RSpec.describe 'AutorateCalculators (isolated)' do
  let(:exchange_rate) { double('ExchangeRate') }
  let(:target_autorate_setting) { double('TargetAutorateSetting') }

  before do
    allow(exchange_rate).to receive(:target_autorate_setting).and_return(target_autorate_setting)
    allow(exchange_rate).to receive(:autorate_from).and_return(1.0)
    allow(exchange_rate).to receive(:autorate_to).and_return(3.0)
    allow(target_autorate_setting).to receive(:could_be_calculated?).and_return(true)
  end

  describe Gera::AutorateCalculators::Legacy do
    let(:calculator) do
      described_class.new(
        exchange_rate: exchange_rate,
        external_rates: external_rates
      )
    end

    context 'с валидными rates' do
      let(:external_rates) do
        [
          double('ExternalRate', target_rate_percent: 2.5),
          double('ExternalRate', target_rate_percent: 2.8),
          double('ExternalRate', target_rate_percent: 3.0)
        ]
      end

      before do
        allow(exchange_rate).to receive(:position_from).and_return(1)
        allow(exchange_rate).to receive(:position_to).and_return(3)
      end

      it 'вычитает GAP из первого matching rate' do
        expect(calculator.call).to eq(2.5 - 0.001)
      end
    end

    context 'когда rates пустые' do
      let(:external_rates) { [] }

      before do
        allow(exchange_rate).to receive(:position_from).and_return(1)
        allow(exchange_rate).to receive(:position_to).and_return(3)
      end

      it 'возвращает autorate_from' do
        expect(calculator.call).to eq(1.0)
      end
    end
  end

  describe Gera::AutorateCalculators::PositionAware do
    let(:calculator) do
      described_class.new(
        exchange_rate: exchange_rate,
        external_rates: external_rates
      )
    end

    context 'UC-1: все позиции имеют одинаковый курс' do
      let(:external_rates) do
        10.times.map { double('ExternalRate', target_rate_percent: 2.5) }
      end

      before do
        allow(exchange_rate).to receive(:position_from).and_return(5)
        allow(exchange_rate).to receive(:position_to).and_return(10)
      end

      it 'не перепрыгивает позицию выше, возвращает ту же комиссию' do
        expect(calculator.call).to eq(2.5)
      end
    end

    context 'UC-2: есть разрыв между позициями' do
      let(:external_rates) do
        [
          double('ExternalRate', target_rate_percent: 1.0),
          double('ExternalRate', target_rate_percent: 1.2),
          double('ExternalRate', target_rate_percent: 1.4),
          double('ExternalRate', target_rate_percent: 1.6),
          double('ExternalRate', target_rate_percent: 2.5),
          double('ExternalRate', target_rate_percent: 2.6),
          double('ExternalRate', target_rate_percent: 2.7),
          double('ExternalRate', target_rate_percent: 2.8),
          double('ExternalRate', target_rate_percent: 2.9),
          double('ExternalRate', target_rate_percent: 3.0)
        ]
      end

      before do
        allow(exchange_rate).to receive(:position_from).and_return(5)
        allow(exchange_rate).to receive(:position_to).and_return(10)
      end

      it 'безопасно вычитает GAP когда есть разрыв' do
        expect(calculator.call).to eq(2.5 - 0.001)
      end
    end

    context 'UC-3: целевая позиция 1' do
      let(:external_rates) do
        [
          double('ExternalRate', target_rate_percent: 2.5),
          double('ExternalRate', target_rate_percent: 2.8),
          double('ExternalRate', target_rate_percent: 3.0)
        ]
      end

      before do
        allow(exchange_rate).to receive(:position_from).and_return(1)
        allow(exchange_rate).to receive(:position_to).and_return(3)
      end

      it 'вычитает GAP когда нет позиции выше' do
        expect(calculator.call).to eq(2.5 - 0.001)
      end
    end

    context 'UC-4: позиция выше с очень близкой комиссией' do
      let(:external_rates) do
        [
          double('ExternalRate', target_rate_percent: 1.0),
          double('ExternalRate', target_rate_percent: 1.5),
          double('ExternalRate', target_rate_percent: 2.0),
          double('ExternalRate', target_rate_percent: 2.4999),
          double('ExternalRate', target_rate_percent: 2.5),
          double('ExternalRate', target_rate_percent: 2.8)
        ]
      end

      before do
        allow(exchange_rate).to receive(:position_from).and_return(5)
        allow(exchange_rate).to receive(:position_to).and_return(6)
      end

      it 'не перепрыгивает позицию 4' do
        expect(calculator.call).to eq(2.4999)
      end
    end
  end
end
