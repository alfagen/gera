MoneyRails.configure do |config|
  config.default_bank = Money::Bank::VariableExchange.new(GERA::CurrencyExchange)
  config.amount_column = { postfix: '_cents', type: :integer, null: false, limit: 8, default: 0, present: true }

  # default
  config.rounding_mode = BigDecimal::ROUND_HALF_EVEN
  config.default_format = {
    no_cents_if_whole: true,
    translate: true,
    drop_trailing_zeros: true
  }
end

# Расширяем класс валюты
require './lib/money_extend'
class Money::Currency
  prepend MoneyExtend

  def self.find!(query)
    find(query) || raise("No found currency (#{query.inspect})")
  end

  def self.find_by_local_id(local_id)
    local_id = local_id.to_i
    id, _ = self.table.find{|key, currency| currency[:local_id] == local_id}
    new(id)
  rescue UnknownCurrency
    nil
  end
end

class Money
  # Это сумма, до которой разрешено безопасное округление
  # при приеме суммы от клиента
  def authorized_round
    return self unless currency.authorized_round.is_a? Numeric
    Money.from_amount to_f.round(currency.authorized_round), currency
  end
end

class Money::Currency
  def self.all_crypto
    @all_crypto ||= all.select(&:is_crypto?)
  end

  def zero_money
    Money.from_amount(0, self)
  end
end

# Убираем все валюты
Money::Currency.all.each do |cur|
  Money::Currency.unregister cur.id.to_s
end

# Загружаем только нужные
CURRENCIES_PATH = Rails.root.join './config/currencies.yml'
Psych.load( File.read(CURRENCIES_PATH) ).each { |key, cur| Money::Currency.register cur.symbolize_keys }

# Создают константы-валюты, типа RUB, USD и тп
Money::Currency.all.each do |cur|
  Object.const_set cur.iso_code, cur
end
