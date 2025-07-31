.PHONY: vault-setup vault-start vault-stop vault-clean vault-status vault-logs vault-shell

# Setup Vault with certificates and configuration
vault-setup:
	@echo "🔐 Setting up Vault development environment..."
	@chmod +x setup-vault.sh
	@./setup-vault.sh

# Start Vault services
vault-start:
	@echo "🚀 Starting Vault..."
	@docker compose up -d vault
	@echo "⏳ Waiting for Vault to be ready..."
	@sleep 5
	@docker compose up vault-init

# Stop Vault services
vault-stop:
	@echo "🛑 Stopping Vault..."
	@docker compose stop

# Clean everything (containers, volumes, certificates)
vault-clean:
	@echo "🧹 Cleaning up Vault environment..."
	@docker compose down -v
	@rm -rf vault/
	@rm -f src/main/resources/vault-*.jks
	@echo "✅ Cleanup completed"

# Check Vault status
vault-status:
	@echo "📊 Vault Status:"
	@docker compose exec vault vault status || echo "Vault is not running"

# View Vault logs
vault-logs:
	@docker compose logs -f vault

# Open shell in Vault container
vault-shell:
	@docker compose exec vault sh

# Test certificate authentication
vault-test-cert:
	@echo "🔐 Testing certificate authentication..."
	@curl --cert vault/certs/client.pem \
	      --key vault/certs/client-key.pem \
	      --cacert vault/certs/ca.pem \
	      -X POST \
	      https://localhost:8200/v1/auth/cert/login

# List secrets
vault-list-secrets:
	@echo "📝 Available secrets:"
	@docker compose exec vault sh -c 'export VAULT_TOKEN=myroot && vault kv list secret/'

# Show application secrets
vault-show-app-secrets:
	@echo "🔍 Application secrets:"
	@docker compose exec vault sh -c 'export VAULT_TOKEN=myroot && vault kv get secret/spring-vault-demo'

# Add new secret
vault-add-secret:
	@read -p "Enter secret path (e.g., secret/myapp): " path; \
	read -p "Enter key: " key; \
	read -s -p "Enter value: " value; \
	echo ""; \
	docker compose exec vault sh -c "export VAULT_TOKEN=myroot && vault kv put $$path $$key='$$value'"

# Restart with fresh data
vault-restart:
	@make vault-stop
	@docker compose down -v
	@make vault-start

# Complete development setup
dev-setup: vault-setup
	@echo "🎉 Development environment ready!"
	@echo "Next steps:"
	@echo "1. Update application.yml with: uri: https://localhost:8200"
	@echo "2. Run: ./mvnw spring-boot:run"
	@echo "3. Test: curl http://localhost:8080/spring-vault-demo/api/vault-status"