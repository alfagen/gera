.PHONY: test test-all db-up db-down

# Run calculator and exchange_rate tests (the ones we fixed)
test:
	mise exec -- bundle exec rspec \
		spec/services/gera/autorate_calculators/isolated_spec.rb \
		spec/models/gera/exchange_rate_spec.rb \
		--no-color

# Run all tests
test-all:
	mise exec -- bundle exec rspec --no-color

# Start MySQL for testing
db-up:
	docker-compose up -d
	@echo "Waiting for MySQL..."
	@for i in $$(seq 1 30); do \
		docker exec gera-legacy-mysql-1 mysqladmin ping -h localhost -u root -p1111 2>/dev/null && break || sleep 2; \
	done
	@echo "MySQL is ready"

# Stop MySQL
db-down:
	docker-compose down
