require 'virtus'

module Gera
  module Mathematic
    class Result
      include Virtus.model strict: true

      # Входные параметры
      #
      attribute :base_rate,       Float # Базовая ставка
      attribute :comission,       Float # Комиссия обменника
      attribute :ps_interest,     Float # Интерес платежной системы (%)
      attribute :income_amount,   Float # Сумма во входящей валюте которую клиент закинул

      # Расчетные параметры
      #
      attribute :finite_rate,     Float # Конечная ставка
      attribute :finite_amount,   Float # сумма которую получет пользователь на счет
      attribute :ps_amount,       Float # Сумма интереса платежной системы в выходящей валюте
      attribute :outcome_amount,  Float # Сумма которая уйдет с выходящего кошелька (что получит клиент + комиссия ПС)
      attribute :profit_amount,   Float # чистая прибыл обменика
    end

    def calculate_profits(base_rate:,
                          comission:,
                          ps_interest:,
                          income_amount:
                         )

      finite_rate     = calculate_finite_rate base_rate, comission
      finite_amount   = income_amount * finite_rate
      ps_amount       = ps_interest.percent_of finite_amount
      outcome_amount  = ps_amount + finite_amount

      Result.new(
        base_rate:       base_rate,
        comission:       comission,
        ps_interest:     ps_interest,
        income_amount:   income_amount,

        finite_rate:     finite_rate,
        finite_amount:   finite_amount, # сумма которую получет пользователь на счет
        ps_amount:       ps_amount,
        outcome_amount:  outcome_amount, # сумма которую нужно перевести чтобы хватило и платежной системе и пользователю сколько обещали
        profit_amount:   income_amount - outcome_amount / base_rate
      ).freeze
    end

    # Отдает базовую тавку из конечной и комиссии
    #
    def calculate_base_rate(finite_rate, comission)
      if finite_rate >= 1
        100.0 * finite_rate / (100.0 - comission.to_f)
      else
        100.0 * finite_rate / (100.0 - comission.to_f)
      end
    end

    # Отдает комиссию исходя из конечной и базовой ставки
    #
    def calculate_comission(finite_rate, base_rate)
      if finite_rate <= 1
        a = 1.0 / finite_rate.to_f - 1.0 / base_rate.to_f
        (a.as_percentage_of(1.0 / finite_rate.to_f).to_f * 100)
      else
        (base_rate.to_f - finite_rate.to_f).as_percentage_of(base_rate.to_f).to_f * 100
      end
    end

    # Конечная ставка из базовой
    #
    def calculate_finite_rate(base_rate, comission)
      if base_rate <= 1
        base_rate.to_f * (1.0 - comission.to_f/100)
      else
        base_rate - comission.to_percent
      end
    end

    # На сколько абсолютных процентов отличается число b от числа a
    #
    def diff_percents(a, b)
      percent_value = (a.to_d / 100.0)
      res = 100.0 - (b.to_d / percent_value)
      res = -res if res < 0
      res.to_percent
    end

    # Отдает сумму которую получим в результате обмена
    # rate - курсовой мультимликатор
    # amount - входящая сумма
    # to_currency - валютя в которой нужно получить результат
    #
    def money_exchange(rate, amount, to_currency)
      fractional = BigDecimal(amount.fractional.to_s) / (
        BigDecimal(amount.currency.subunit_to_unit.to_s) /
        BigDecimal(to_currency.subunit_to_unit.to_s)
      )

      res = fractional * rate
      res = res.round(0, BigDecimal::ROUND_DOWN)
      Money.new(res, to_currency)
    end

    # Обратный обмен. Когда у нас есть курс и сумма которую мы хотим
    # получить и мы вычисляем из какой суммы на входе она получится
    #
    def money_reverse_exchange(rate, amount, to_currency)
      fractional = BigDecimal(amount.fractional.to_s) / (
        BigDecimal(amount.currency.subunit_to_unit.to_s) /
        BigDecimal(to_currency.subunit_to_unit.to_s)
      )

      res = fractional / rate
      res = res.round(0, BigDecimal::ROUND_UP)
      Money.new(res, to_currency)
    end

    # Рассчет суммы с комиссей. Процент комиссии считается от изначальной суммы.
    # Комиссия указывается в процентах.
    #
    def calculate_total_using_regular_comission(amount, comission)
      amount + (amount * comission / 100.0)
    end

    # Рассчет суммы с обратной комиссей. Процент комиссии считается от итоговой суммы
    # Комиссия указывается в процентах.
    #
    def calculate_total_using_reverse_comission(amount, comission)
      100.0 / (100 - comission) * amount
    end

    private

    # Отдает комиссию исходя из конечной и базовой ставки
    #
    def modern_base_rate_percent(finite_rate, base_rate)
      if finite_rate <= 1
        (1.0/finite_rate.to_f - 1.0/base_rate.to_f) / (1.0/base_rate.to_f/100)
      else
        (base_rate - finite_rate.to_f) / (base_rate.to_f/100)
      end
    end

    def modern_calcualte_finite_rate(base_rate, comission)
      # Через обратный процент
      # base_rate / (1.0 + comission/100.0)
      #
      if base_rate <= 1
        1.0 / ( 1.0 /  base_rate + comission.to_percent )
      else
        base_rate - comission.to_percent
      end
    end
  end
end
