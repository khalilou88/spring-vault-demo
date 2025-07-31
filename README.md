# Spring Boot Vault Demo

A minimal Spring Boot application demonstrating HashiCorp Vault integration with certificate-based authentication.

## Stack

- **Spring Boot**: 2.7.18
- **Spring Cloud**: 2021.0.8 (Jubilee)
- **Spring Cloud Vault**: Certificate-based authentication
- **Packaging**: WAR
- **Java**: 11+

## Prerequisites

- Docker and Docker Compose
- Java 11+
- Maven 3.6+

## Quick Start (Development)

### 1. Automatic Vault Setup with Docker

The easiest way to get started is using the provided Docker Compose setup:

```bash
# Complete development setup (Vault + certificates + secrets)
make dev-setup
```

This will:
- Start Vault server with Docker Compose
- Generate development certificates
- Create JKS keystores in `src/main/resources/`
- Configure certificate authentication
- Initialize sample secrets

### 2. Manual Setup

If you prefer manual setup or don't have make:

```bash
# Make setup script executable
chmod +x setup-vault.sh

# Run the setup
./setup-vault.sh
```

### 3. Production Vault Setup

For production environments, ensure you have a Vault server running with:
- Certificate authentication enabled
- KV secrets engine mounted at `secret/`
- Proper certificate authority configured

Store secrets in Vault at the following paths:
```bash
# Basic application secrets
vault kv put secret/spring-vault-demo \
  app.database.url="jdbc:postgresql://localhost:5432/mydb" \
  app.database.username="myuser" \
  app.api.key="your-secret-api-key"

# Common secrets (optional)
vault kv put secret/common \
  app.shared.secret="shared-value"
```

## Configuration

### Development Configuration

After running `make dev-setup`, update the Vault URI in both configuration files:
- `application.yml`: Change `uri` to `https://localhost:8200`
- `bootstrap.yml`: Change `uri` to `https://localhost:8200`

### Key Configuration Points

1. **Vault URI**: Update `spring.cloud.vault.uri` in `application.yml` and `bootstrap.yml`
2. **Keystore Passwords**: Update keystore and truststore passwords (default: `changeit`)
3. **Secret Paths**: Modify paths in `VaultConfig.java` as needed

### Certificate Authentication

The application uses certificate-based authentication with the following configuration:
- Client certificate: `vault-client.jks`
- Trust store: `vault-truststore.jks`
- Both use password: `changeit` (change this in production)

## Vault Management

### Docker Compose Commands

```bash
# Start Vault services
make vault-start

# Stop Vault services  
make vault-stop

# View Vault status
make vault-status

# View Vault logs
make vault-logs

# Clean everything (containers, volumes, certificates)
make vault-clean

# Test certificate authentication
make vault-test-cert

# List available secrets
make vault-list-secrets

# Show application secrets
make vault-show-app-secrets
```

### Vault UI Access

- **URL**: http://localhost:8200
- **Token**: `myroot` (development only)

## Running the Application

### Development Mode
```bash
./mvnw spring-boot:run
```

### WAR Deployment
```bash
./mvnw clean package
# Deploy target/spring-vault-demo-1.0.0.war to your application server
```

## Endpoints

- **Health Check**: `GET /spring-vault-demo/api/health`
- **Configuration**: `GET /spring-vault-demo/api/config` - Shows loaded secrets (masked)
- **Vault Status**: `GET /spring-vault-demo/api/vault-status` - Shows Vault connection status
- **Actuator Health**: `GET /spring-vault-demo/actuator/health`
- **Vault Actuator**: `GET /spring-vault-demo/actuator/vault`

## Testing Vault Integration

1. Start the application
2. Check vault status: `curl http://localhost:8080/spring-vault-demo/api/vault-status`
3. View configuration: `curl http://localhost:8080/spring-vault-demo/api/config`
4. Check actuator health: `curl http://localhost:8080/spring-vault-demo/actuator/health`

## Troubleshooting

### Common Issues

1. **Certificate Validation Errors**
   - Verify certificate chain in truststore
   - Check certificate validity dates
   - Ensure Vault server certificate matches URI

2. **Authentication Failures**
   - Verify client certificate is properly configured in Vault
   - Check certificate authentication policy in Vault
   - Validate keystore contains both certificate and private key

3. **Connection Timeouts**
   - Verify Vault server is accessible
   - Check network connectivity and firewall rules
   - Adjust timeout values in configuration

### Debug Logging

Enable debug logging by setting:
```yaml
logging:
  level:
    org.springframework.vault: DEBUG
    org.springframework.cloud.vault: DEBUG
```

## Security Notes

- Change default keystore passwords
- Use proper certificate management in production
- Implement certificate rotation procedures
- Monitor certificate expiration dates
- Use Vault policies to limit secret access

## Production Considerations

1. **Certificate Management**
   - Implement automated certificate rotation
   - Use proper certificate storage (not in JAR/WAR)
   - Monitor certificate expiration

2. **Configuration**
   - Externalize configuration (environment variables, external config files)
   - Use proper secret management for keystore passwords
   - Implement proper logging without exposing secrets

3. **Monitoring**
   - Monitor Vault connectivity
   - Set up alerts for authentication failures
   - Track secret refresh operations