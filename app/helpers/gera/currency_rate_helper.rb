# frozen_string_literal: true

module Gera::CurrencyRateHelper
  def currency_rate_mode_autoshow_style(crm)
    'display: none' unless crm.mode_cross?
  end

  def currency_rate_columns(cer)
    if cer.external_rate_id.present?
      %i[id created_at rate_value mode external_rate tooltip metadata]
    else
      %i[id created_at rate_value mode tooltip metadata]
    end
  end

  def currency_rate_class(cer)
    "cer-mode-#{cer.mode}"
  end
end
