# frozen_string_literal: true

module Gera::CurrencyRateModesHelper
  ICON_CLASS = {
    'draft' => 'battery-half',
    'active' => 'battery-charging',
    'deactive' => 'battery-empty'
  }.freeze

  STATUS_CLASS = {
    'draft' => 'label-info',
    'active' => 'label-success',
    'deactive' => 'label-default'
  }.freeze

  def currency_rate_mode_detailed(currency_rate, level = 0)
    buffer = []
    if currency_rate.mode_cross?
      currency_rate.external_rates.each do |er|
        buffer << "#{er.currency_pair}(#{er.source})<sup>#{humanized_rate er.rate_value}</sup>"
      end
    elsif currency_rate.mode_same?
      buffer << t('.same_currency')
    else
      buffer << "#{currency_rate.currency_pair}(#{currency_rate.rate_source})"
    end

    buffer = buffer.join(' × ')
    buffer << " =&nbsp;#{humanized_rate currency_rate.rate_value}&nbsp;#{currency_rate.currency_pair.last}" if level == 0
    buffer.html_safe
  end

  def currency_rate_mode_build_result_details(build_result)
    return build_result.error.message if build_result.error?

    raw t('.calculation_method', rate: currency_rate_mode_detailed(build_result.currency_rate))
  end

  def crms_cell_data_attr(crm)
    url = crm.persisted? ? edit_currency_rate_mode_path(crm, back: request.url) :
      new_currency_rate_mode_path(
        currency_rate_mode: crm.attributes.slice('currency_rate_mode_snapshot_id', 'cur_from', 'cur_to'),
        back: request.url
      )
    {
      toggle: :popover,
      container: :body,
      content: currency_rate_mode_build_result_details(crm.build_result),
      trigger: :hover,
      html: 'true',
      placement: :bottom,
      animation: false,
      delay: 0,
      href: url
    }
  end

  def crms_status_label(status)
    content_tag :span, status, class: "label #{STATUS_CLASS[status]}"
  end

  def currency_rate_mode_snapshot_icon(crms)
    ion_icon ICON_CLASS[crms.status]
  end

  def currency_rate_modes_enum
    Gera::CurrencyRateMode.modes.keys
  end

  def currencies_enum
    Money::Currency.all.map(&:to_s)
  end
end
