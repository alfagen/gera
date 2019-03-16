# frozen_string_literal: true

module Gera
  class CurrencyRateDecorator < ApplicationDecorator
    delegate :mode, :id, :external_rate_id, :meta, :rate_value

    def detailed
      buffer = []
      buffer << if object.mode_cross?
                  'cross'
                else
                  object.rate_source.to_s # if object.rate_source.present?
      end

      buffer.join(' × ').html_safe
    end

    def external_rate
      return unless object.external_rate_id.present?

      er = object.external_rate
      buffer = if [:exmo_sell].include? mode.to_sym
                 "#{h.humanized_rate_detailed er.sell_price} (из колонки 'продажа')"
               elsif [:exmo_buy].include? mode.to_sym
                 "#{h.humanized_rate_detailed er.buy_price} (из колонки 'покупка')"
               elsif [:cbr_min].include? mode.to_sym
                 "#{h.humanized_rate_detailed er.rate}<br/>(минимальный из пары #{object.meta.rates})"
               elsif [:cbr_max].include? mode.to_sym
                 "#{h.humanized_rate_detailed er.rate}<br/>(максимальный из пары #{object.meta.rates})"
               else
                 'WTF?'
               end

      buffer = buffer + ' от ' + I18n.l(er.created_at, format: :long)

      h.link_to buffer.html_safe, h.external_rate_path(er)
    end

    def tooltip
      buffer = []
      buffer << "Покупаем 1 #{object.cur_from} за #{object.rate_value} #{object.cur_to}"
      buffer << "Покупаем 1 #{object.currency_pair.first} за #{h.humanized_rate object.rate_value} #{object.currency_pair.second}".html_safe
      buffer << "Продаем 1 #{object.cur_to} за #{1.0 / object.rate_value} #{object.cur_from}"
      buffer = buffer.join "\n"
      h.simple_format(buffer).html_safe
    end

    def created_at
      h.link_to h.currency_rate_path(object) do
        if object.created_at.present?
          I18n.l object.created_at, format: :long
        else
          'время создания не известно'
        end
      end
    end

    def source_external_rate
      return '-' unless object.source_external_rate_id.present?

      er = Gera::ExternalRate.find object.source_external_rate_id
      h.link_to h.external_rate_path(er) do
        "Источник EXMO\n#{I18n.l er.created_at, format: :long}\n#{er.buy_price}/#{er.sell_price}"
      end
    end

    def reverse_currency_rate
      return '-' unless object.reverse_currency_rate_id

      cer = Gera::CurrencyRate.find object.reverse_currency_rate_id
      cerd = CurrencyRateDecorator.decorate(cer)
      h.link_to cerd.short_description, h.currency_rate_path(cer)
    end

    def short_description
      "#{title} (#{object.buy_rate}) #{comment}".html_safe
    end

    def title
      to_s
    end

    def rate_value
      h.humanized_rate_detailed object.rate_value
    end

    def metadata
      h.content_tag :code, object.metadata.to_json
    end

    def comment(inverse = false)
      return object.mode
      send "comment_#{object.source}", inverse
    rescue ActiveRecord::RecordNotFound
      raise "Не найдена одна из зависимых записей для #{object.id}"
    end

    def comment_equal(_inverse)
      'Одинаковый тип валюты'
    end

    def comment_inderect(_inverse)
      r1 = CurrencyRateDecorator.decorate object.rate1_currency_rate
      r2 = CurrencyRateDecorator.decorate object.rate2_currency_rate
      "Через #{object.meta.inter_cur}\n" \
        "Продажа:\n" \
        "#{object.rate1_currency_rate.rate_money.format} за #{object.rate1_currency_rate.cur_from}\n(#{r1.comment})\n" \
        "#{object.rate2_currency_rate.rate_money.format} за #{object.rate2_currency_rate.cur_from}\n(#{r2.comment})"
    end

    def comment_exmo(inverse)
      er = Gera::ExternalRate.find object.meta.external_rate_id
      ExternalRateDecorator.decorate(er).comment inverse
    end

    def comment_cbr(inverse)
      # min_rate = Gera::ExternalRate.find object.meta.min_external_rate_id
      max_rate = Gera::ExternalRate.find object.meta.max_external_rate_id
      # min_rate_d = ExternalRateDecorator.decorate min_rate
      max_rate_d = ExternalRateDecorator.decorate max_rate

      max_rate_d.comment inverse
    end

    def comment_reverse(_inverse)
      [
        "Инверсия (#{object.reverse_currency_rate.pair})",
        object.reverse_currency_rate.buy_rate,
        CurrencyRateDecorator.decorate(object.reverse_currency_rate).comment(true)
      ].join "\n"
    end

    private

    def muted(content)
      h.content_tag :span, content, class: 'text-muted'
    end

    def source(currency_rate)
      buffer = if currency_rate.mode_cross?
                 CurrencyRateDecorator.decorate(currency_rate).detailed
               else
                 currency_rate.rate_source.presence || currency_rate.mode
               end
      "(#{buffer})".html_safe
    end
  end
end
