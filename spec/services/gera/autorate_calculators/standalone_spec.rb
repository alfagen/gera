# frozen_string_literal: true

# Standalone тесты для калькуляторов автокурса
# Не требуют полной загрузки Rails

require 'virtus'

# Загружаем только необходимые файлы
require_relative '../../../../app/services/gera/autorate_calculators/base'
require_relative '../../../../app/services/gera/autorate_calculators/legacy'
require_relative '../../../../app/services/gera/autorate_calculators/position_aware'

RSpec.describe 'AutorateCalculators' do
  let(:exchange_rate) { double('ExchangeRate') }
  let(:target_autorate_setting) { double('TargetAutorateSetting') }
      let(:currency_rate) { double('CurrencyRate', rate_value: base_rate) }
      let(:base_rate) { 100.0 }

      # Вспомогательный метод: создаёт хеш Manul из target_rate_percent
      # rate = base_rate * (1 - target_rate_percent / 100)
      def manul_rate(target_rate_percent, changer_id: nil)
        rate_value = base_rate * (1 - target_rate_percent / 100.0)
        { 'rate' => rate_value.to_s, 'changer_id' => changer_id }
      end

  before do
    allow(exchange_rate).to receive(:target_autorate_setting).and_return(target_autorate_setting)
        allow(exchange_rate).to receive(:currency_rate).and_return(currency_rate)
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
          manul_rate(2.5),
          manul_rate(2.8),
          manul_rate(3.0)
        ]
      end

      before do
        allow(exchange_rate).to receive(:position_from).and_return(1)
        allow(exchange_rate).to receive(:position_to).and_return(3)
      end

      it 'вычитает GAP из первого matching rate' do
        expect(calculator.call).to be_within(0.0001).of(2.5 - 0.001)
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
        10.times.map { manul_rate(2.5) }
      end

      before do
        allow(exchange_rate).to receive(:position_from).and_return(5)
        allow(exchange_rate).to receive(:position_to).and_return(10)
      end

      it 'не перепрыгивает позицию выше, возвращает ту же комиссию' do
        # Позиция 4 имеет 2.5, после GAP было бы 2.499 < 2.5 - перепрыгнем!
        # PositionAware должен вернуть 2.5
        expect(calculator.call).to be_within(0.0001).of(2.5)
      end
    end

    context 'UC-2: есть разрыв между позициями' do
      let(:external_rates) do
        [
          manul_rate(1.0),
          manul_rate(1.2),
          manul_rate(1.4),
          manul_rate(1.6),
          manul_rate(2.5),
          manul_rate(2.6),
          manul_rate(2.7),
          manul_rate(2.8),
          manul_rate(2.9),
          manul_rate(3.0)
        ]
      end

      before do
        allow(exchange_rate).to receive(:position_from).and_return(5)
        allow(exchange_rate).to receive(:position_to).and_return(10)
      end

      it 'безопасно вычитает GAP когда есть разрыв' do
        # 2.5 - 0.001 = 2.499 > 1.6 - не перепрыгиваем
        expect(calculator.call).to be_within(0.0001).of(2.5 - 0.001)
      end
    end

    context 'UC-3: целевая позиция 1' do
      let(:external_rates) do
        [
          manul_rate(2.5),
          manul_rate(2.8),
          manul_rate(3.0)
        ]
      end

      before do
        allow(exchange_rate).to receive(:position_from).and_return(1)
        allow(exchange_rate).to receive(:position_to).and_return(3)
      end

      it 'вычитает GAP когда нет позиции выше' do
        expect(calculator.call).to be_within(0.0001).of(2.5 - 0.001)
      end
    end

    context 'UC-4: позиция выше с очень близкой комиссией' do
      let(:external_rates) do
        [
          manul_rate(1.0),
          manul_rate(1.5),
          manul_rate(2.0),
          manul_rate(2.4999),
          manul_rate(2.5),
          manul_rate(2.8)
        ]
      end

      before do
        allow(exchange_rate).to receive(:position_from).and_return(5)
        allow(exchange_rate).to receive(:position_to).and_return(6)
      end

      it 'не перепрыгивает позицию 4' do
        # 2.5 - 0.001 = 2.499 < 2.4999, значит перепрыгнем
        # Должны вернуть min(2.4999, 2.5) = 2.4999
        expect(calculator.call).to be_within(0.0001).of(2.4999)
      end
    end
  end
end
