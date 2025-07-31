#!/bin/bash

# Vault Development Setup Script
set -e

echo "🔐 Setting up Vault for Spring Boot development..."

# Create necessary directories
mkdir -p vault/{config,certs,init}
mkdir -p src/main/resources

# Create vault configuration
cat > vault/config/vault.hcl << 'EOF'
ui = true
disable_mlock = true

storage "file" {
  path = "/vault/data"
}

listener "tcp" {
  address = "0.0.0.0:8200"
  tls_cert_file = "/vault/certs/vault-server.pem"
  tls_key_file = "/vault/certs/vault-server-key.pem"
}

api_addr = "https://localhost:8200"
cluster_addr = "https://localhost:8201"
EOF

# Generate certificates for development
echo "📜 Generating development certificates..."

# Create CA private key
openssl genrsa -out vault/certs/ca-key.pem 4096

# Create CA certificate
openssl req -new -x509 -days 365 -key vault/certs/ca-key.pem -out vault/certs/ca.pem -subj "/C=US/ST=Dev/L=Dev/O=Dev/CN=Vault CA"

# Create server private key
openssl genrsa -out vault/certs/vault-server-key.pem 4096

# Create server certificate request
openssl req -new -key vault/certs/vault-server-key.pem -out vault/certs/vault-server.csr -subj "/C=US/ST=Dev/L=Dev/O=Dev/CN=localhost"

# Create server certificate
openssl x509 -req -days 365 -in vault/certs/vault-server.csr -CA vault/certs/ca.pem -CAkey vault/certs/ca-key.pem -CAcreateserial -out vault/certs/vault-server.pem

# Create client private key
openssl genrsa -out vault/certs/client-key.pem 4096

# Create client certificate request
openssl req -new -key vault/certs/client-key.pem -out vault/certs/client.csr -subj "/C=US/ST=Dev/L=Dev/O=Dev/CN=spring-boot-client"

# Create client certificate
openssl x509 -req -days 365 -in vault/certs/client.csr -CA vault/certs/ca.pem -CAkey vault/certs/ca-key.pem -CAcreateserial -out vault/certs/client.pem

echo "🔑 Creating JKS keystores..."

# Create client keystore (PKCS12 first, then JKS)
openssl pkcs12 -export -in vault/certs/client.pem -inkey vault/certs/client-key.pem -out vault/certs/client.p12 -name vault-client -passout pass:changeit

# Convert to JKS
keytool -importkeystore -deststorepass changeit -destkeypass changeit -destkeystore src/main/resources/vault-client.jks -srckeystore vault/certs/client.p12 -srcstoretype PKCS12 -srcstorepass changeit -alias vault-client

# Create truststore with CA certificate
keytool -import -alias vault-ca -file vault/certs/ca.pem -keystore src/main/resources/vault-truststore.jks -storepass changeit -noprompt

echo "🐳 Starting Vault with Docker Compose..."
docker compose up -d vault

echo "⏳ Waiting for Vault to be ready..."
sleep 10

echo "🔧 Configuring certificate authentication..."

# Wait for vault to be healthy
until docker compose exec vault vault status > /dev/null 2>&1; do
  echo "Waiting for Vault..."
  sleep 2
done

# Configure certificate authentication
docker compose exec vault sh -c '
export VAULT_TOKEN=myroot
export VAULT_ADDR=https://0.0.0.0:8200
export VAULT_SKIP_VERIFY=true

echo "Enabling certificate authentication..."
vault auth enable cert

echo "Adding CA certificate to Vault..."
vault write auth/cert/certs/spring-boot-client \
  display_name="Spring Boot Client" \
  policies="spring-boot-policy" \
  certificate=@/vault/certs/ca.pem

echo "Creating policy for Spring Boot..."
vault policy write spring-boot-policy - <<EOF
path "secret/data/spring-vault-demo" {
  capabilities = ["read"]
}
path "secret/data/common" {
  capabilities = ["read"]
}
EOF

echo "Certificate authentication configured!"
'

# Run initialization
docker compose up vault-init

echo "✅ Vault setup completed!"
echo ""
echo "🌐 Vault UI: http://localhost:8200"
echo "🔑 Root Token: myroot"
echo "📁 Keystores created in src/main/resources/"
echo ""
echo "To test certificate authentication:"
echo "curl --cert vault/certs/client.pem --key vault/certs/client-key.pem --cacert vault/certs/ca.pem https://localhost:8200/v1/auth/cert/login"