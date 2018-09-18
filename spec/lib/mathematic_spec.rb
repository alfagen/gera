require 'spec_helper'

module Gera
  RSpec.describe Mathematic do
    include Mathematic
    let(:rub) { Money::Currency.find :rub }

    subject {
      calculate_profits(
        income_amount: income_amount,
        base_rate:     base_rate,
        comission:     comission,
        ps_interest:   ps_interest
      )
    }

    context 'отличие в процентах' do
      specify do
        a = 100
        b = 105
        percents = diff_percents a, b
        assert_equal percents.to_s, '5%'
      end

      specify do
        a = 100
        b = 95
        percents = diff_percents a, b
        assert_equal percents.to_s, '5%'
      end
    end
    #Принимаем USD
    #отдаем rub
    #0.018504 $
    #1 руб
    #курс 12.36

    # Покупаем за 536621
    # Продаем за 717044
    # Наценка стоит 25%

    #
    # Базовый курс: 537297
    # Конечный курс: 767618.5714
    # Комиссия: ~30%
    #
    # Продаем биткойны (дорого)
    # Откуда: Сбер
    # Куда: на биткойн
    # Отдаем: 716658.66
    # Получаем: 1btc
    #
    # Продажа - 537494 руб.; Покупка - 535308 руб.
    # 25%
    context 'рубль на биткойн' do
      let(:finite_rate) { 1.0 / 716658.66 }
      let(:base_rate) { 1.0 / 537494 }
      let(:comission) { 25 }
      specify do
        c = calculate_comission(finite_rate, base_rate)
        assert_equal comission, c.round(2)
        assert_equal base_rate, calculate_base_rate(finite_rate, c)
        assert_equal finite_rate, calculate_finite_rate(base_rate, c)

        assert_equal 1.0 / 1_000_000, calculate_finite_rate(1.0 / 500_000, 50)
      end
    end

    # Покупаем доллары (дешево)
    #Принимаем USD, отдаем rub
    #Отдаем: 0.018504 или 1 $
    #Принимаем: 1 руб и 54.0427 руб
    #комиссия 12.36%
    #25): 61.6644 руб.
    #Продажа (2018-04-24): 61.7655 руб.
    #
    #61.6644 - 12.36.to_percent   = 54.04268016
    context 'доллар на рубль' do
      let(:base_rate) { 61.6644 }
      let(:finite_rate) { 54.0427 } # 0.018504 } # 54.0427
      let(:comission) { 12.36 }
      specify do
        c = calculate_comission(finite_rate, base_rate)
        assert_equal comission, c.round(2)
        assert_equal base_rate, calculate_base_rate(finite_rate, c)
        assert_equal finite_rate, calculate_finite_rate(base_rate, c)

        assert_equal 50, calculate_finite_rate(100, 50)
      end
    end

    context 'обмен' do
      let(:rate_value) { 0.963 }
      let(:outcome_amount_target) { Money.from_amount(150.02, rub) }

      specify do
        income_amount = money_reverse_exchange rate_value, outcome_amount_target, rub
        income_amount = income_amount.to_f

        expect(income_amount).to eq 155.79

        outcome_amount = money_exchange rate_value, Money.from_amount(income_amount, rub), rub
        outcome_amount = outcome_amount.to_f
        expect(outcome_amount).to eq outcome_amount_target.to_f
      end
    end
  end
end
