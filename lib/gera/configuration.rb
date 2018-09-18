module Gera
	# Gera configuration module.
	# This is extended by Gera to provide configuration settings.
	module Configuration

		# Start a Gera configuration block in an initializer.
		#
		# example: Provide a default currency for the application
		#   Gera.configure do |config|
		#     config.default_currency = :eur
		#   end
		def configure
			yield self
		end
	end
end

# Пример:
# https://github.com/RubyMoney/money-rails/blob/master/lib/money-rails/configuration.rb
