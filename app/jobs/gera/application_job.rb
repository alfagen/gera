# frozen_string_literal: true

module Gera
  class ApplicationJob < ActiveJob::Base
    # SolidQueue's engine automatically includes ActiveJob::ConcurrencyControls
    # which provides limits_concurrency method
  end
end
