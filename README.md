# GoPhish Quick Deployment

## Introduction

This repository provides a quick and ready-to-use deployment of GoPhish behind an Nginx reverse proxy, with automatic domain configuration and HTTPS certificates via Let's Encrypt.

The goal is to have a minimal stack that allows you to quickly run GoPhish for testing, learning, or simulated phishing campaigns in a controlled environment.

GoPhish official site: https://getgophish.com/

GoPhish Docker image repository: https://github.com/gophish/gophish

> Disclaimer: This project provides the technical infrastructure only. Using these tools for real phishing attacks is illegal and unethical. Only use in lab environments, for training, or for authorized simulations.

Repository Structure

```
.
├─ gophish/
│  └─ config.json              # GoPhish configuration file (can contain placeholders)
├─ nginx/
│  ├─ conf.d/
│  │  └─ gophish.conf          # Nginx configuration
│  └─ static/
│     └─ sensibilisation.html  # Example static landing page (can redirect users)
├─ docker-compose.yml          # Docker Compose file for GoPhish + Nginx
├─ init.sh                     # Initialization script (replaces placeholders, obtains certificates)
└─ README.md
```

## How It Works

GoPhish runs in a Docker container and exposes:

the Admin UI (default port 3333)

the phishing landing pages (default port 8080)

Nginx runs in a separate container and acts as a reverse proxy with HTTPS:

routes admin.DOMAIN → proxies to gophish:3333

routes www.DOMAIN and DOMAIN → proxies to gophish:8080

The init.sh script:

Replaces placeholders (ADMIN_DOMAIN, WWW_DOMAIN, ROOT_DOMAIN) in configuration files.

Automatically requests HTTPS certificates from Let's Encrypt via certbot --standalone.

Starts the GoPhish and Nginx containers via Docker Compose.

Any static files placed in nginx/static/ can be used as landing pages or redirect destinations after users submit credentials (useful for testing or educational simulations).

## Usage

Clone the repository:
```
git clone https://github.com/yourusername/gophish-deploy.git
cd gophish-deploy
```

Run the initialization script:

```
./init.sh yourdomain.com admin@your-email.com
```


This will:

- Replace placeholders in config.json and nginx.conf.

- Request TLS certificates for yourdomain.com, www.yourdomain.com, and admin.yourdomain.com

- Start the GoPhish and Nginx containers

## Access your services:

Admin UI: https://admin.yourdomain.com

Phishing landing pages: https://yourdomain.com or https://www.yourdomain.com

Customizing Landing Pages

Add any HTML files to nginx/static/

Update your phishing campaign in GoPhish to redirect users to these static pages after interaction.

## Disclaimer

⚠️ Phishing is illegal.

This repository is intended only for testing, educational purposes, or authorized security awareness campaigns.
Do not use this setup to target real users without explicit permission.