package com.example.springvaultdemo.controller;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.cloud.context.config.annotation.RefreshScope;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api")
@RefreshScope
public class VaultController {

    @Value("${app.database.url:not-found}")
    private String databaseUrl;

    @Value("${app.database.username:not-found}")
    private String databaseUsername;

    @Value("${app.api.key:not-found}")
    private String apiKey;

    @GetMapping("/health")
    public Map<String, String> health() {
        Map<String, String> response = new HashMap<>();
        response.put("status", "UP");
        response.put("application", "spring-vault-demo");
        return response;
    }

    @GetMapping("/config")
    public Map<String, String> getConfiguration() {
        Map<String, String> config = new HashMap<>();
        config.put("database.url", databaseUrl);
        config.put("database.username", databaseUsername);
        config.put("api.key", apiKey.replaceAll(".", "*")); // Mask the API key
        return config;
    }

    @GetMapping("/vault-status")
    public Map<String, Object> getVaultStatus() {
        Map<String, Object> status = new HashMap<>();
        status.put("vault-connected", !databaseUrl.equals("not-found"));
        status.put("secrets-loaded", !apiKey.equals("not-found"));
        return status;
    }
}