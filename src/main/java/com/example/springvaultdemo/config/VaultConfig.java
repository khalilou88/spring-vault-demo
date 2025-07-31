package com.example.springvaultdemo.config;

import org.springframework.cloud.vault.config.SecretBackendConfigurer;
import org.springframework.cloud.vault.config.VaultConfigurer;
import org.springframework.context.annotation.Configuration;

@Configuration
public class VaultConfig implements VaultConfigurer {

    @Override
    public void addSecretBackends(SecretBackendConfigurer configurer) {
        // Configure additional secret backends if needed
        configurer.add("secret/spring-vault-demo");
        configurer.add("secret/common");
    }
}