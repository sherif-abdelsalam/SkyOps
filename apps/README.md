# 📦 SkyOps — Applications

This document covers the application layer: service descriptions, local development, environment variables, API references, and Docker configuration.

---

## 🏗️ Services Overview

| Service | Language | Port | Description |
|---|---|---|---|
| `weather` | Python | 5000 | Fetches and serves weather data from external API |
| `auth` | Go | 8080 | Handles user authentication and JWT issuance |
| `UI` | Node.js / JS | 80 | Web frontend |
| `mysql` | MySQL 8 | 3306 | Persistent database for auth service |

---

## 📁 Directory Structure

```
apps/
├── auth/
│   ├── main          # Compiled Go binary
│   ├── go.mod
│   ├── go.sum
│   └── Dockerfile
│
├── weather/
│   ├── main.py
│   ├── requirements.txt
│   └── Dockerfile
│
├── UI/
│   ├── app.js
│   ├── package.json
│   ├── public/
│   ├── dist/
│   └── Dockerfile
│
└── mysql-init/
    └── init.sql      # DB schema applied on first startup
```

---

## 🌦️ Weather Service (Python)

Fetches current weather data from an upstream provider (e.g. OpenWeatherMap) and exposes it as a REST API consumed by the UI.

### Endpoints

| Method | Path | Description |
|---|---|---|
| `GET` | `/health` | Health check |
| `GET` | `/weather?city={city}` | Get current weather for a city |

### Environment Variables

| Variable | Required | Description |
|---|---|---|
| `WEATHER_API_KEY` | ✅ | API key for weather data provider |
| `WEATHER_API_URL` | ✅ | Base URL of the weather provider |
| `PORT` | ❌ | Server port (default: `5000`) |

### Run Locally

```bash
cd apps/weather
pip install -r requirements.txt
WEATHER_API_KEY=your_key WEATHER_API_URL=https://api.openweathermap.org python main.py
```

### Docker

```bash
docker build -t skyops/weather ./apps/weather
docker run -p 5000:5000 \
  -e WEATHER_API_KEY=your_key \
  -e WEATHER_API_URL=https://api.openweathermap.org \
  skyops/weather
```

---

## 🔐 Auth Service (Go)

Handles user registration, login, and JWT token issuance. Stores user data in MySQL.

### Endpoints

| Method | Path | Description |
|---|---|---|
| `GET` | `/health` | Health check |
| `POST` | `/register` | Register a new user |
| `POST` | `/login` | Login and receive a JWT |
| `GET` | `/verify` | Verify a JWT token |

### Environment Variables

| Variable | Required | Description |
|---|---|---|
| `MYSQL_HOST` | ✅ | MySQL hostname |
| `MYSQL_PORT` | ✅ | MySQL port (default: `3306`) |
| `MYSQL_USER` | ✅ | MySQL username |
| `MYSQL_PASSWORD` | ✅ | MySQL password |
| `MYSQL_DATABASE` | ✅ | Database name |
| `JWT_SECRET` | ✅ | Secret key for signing JWTs |
| `PORT` | ❌ | Server port (default: `8080`) |

### Run Locally

```bash
cd apps/auth
go mod download
MYSQL_HOST=localhost MYSQL_USER=root MYSQL_PASSWORD=secret \
MYSQL_DATABASE=skyops JWT_SECRET=dev_secret go run .
```

### Docker

```bash
docker build -t skyops/auth ./apps/auth
docker run -p 8080:8080 \
  -e MYSQL_HOST=host.docker.internal \
  -e MYSQL_USER=root \
  -e MYSQL_PASSWORD=secret \
  -e MYSQL_DATABASE=skyops \
  -e JWT_SECRET=dev_secret \
  skyops/auth
```

---

## 🖥️ UI (Node.js / JS)

Frontend web application. Communicates with the weather and auth services via HTTP.

### Environment Variables / Config

| Variable | Description |
|---|---|
| `WEATHER_SERVICE_URL` | URL of the weather service |
| `AUTH_SERVICE_URL` | URL of the auth service |

### Run Locally

```bash
cd apps/UI
npm install
npm start
```

### Docker

```bash
docker build -t skyops/ui ./apps/UI
docker run -p 80:80 skyops/ui
```

---

## 🗄️ MySQL

MySQL 8 is deployed as a Kubernetes `StatefulSet` with a PVC backed by AWS EBS (gp3, via the EBS CSI driver). The `mysql-init/init.sql` script is applied via a Kubernetes init `Job` on first startup.

### Environment Variables

| Variable | Description |
|---|---|
| `MYSQL_ROOT_PASSWORD` | Root password (from AWS Secrets Manager via ESO) |
| `MYSQL_DATABASE` | Database name |
| `MYSQL_USER` | App user |
| `MYSQL_PASSWORD` | App user password (from AWS Secrets Manager via ESO) |

Credentials are injected via `ExternalSecret` — see [deployment/README.md → Secrets](../deployment/README.md#secrets--external-secrets-operator).

---

## 🐳 Local Development — Docker Compose

Run the full stack locally:

```bash
docker compose up --build
```

```yaml
services:
  mysql:
    image: mysql:8
    environment:
      MYSQL_ROOT_PASSWORD: secret
      MYSQL_DATABASE: skyops
      MYSQL_USER: appuser
      MYSQL_PASSWORD: appsecret
    ports:
      - "3306:3306"
    volumes:
      - ./apps/mysql-init/init.sql:/docker-entrypoint-initdb.d/init.sql

  auth:
    build: ./apps/auth
    ports:
      - "8080:8080"
    environment:
      MYSQL_HOST: mysql
      MYSQL_PORT: "3306"
      MYSQL_USER: appuser
      MYSQL_PASSWORD: appsecret
      MYSQL_DATABASE: skyops
      JWT_SECRET: local_dev_secret
    depends_on:
      - mysql

  weather:
    build: ./apps/weather
    ports:
      - "5000:5000"
    environment:
      WEATHER_API_KEY: your_key
      WEATHER_API_URL: https://api.openweathermap.org

  ui:
    build: ./apps/UI
    ports:
      - "80:80"
    environment:
      AUTH_SERVICE_URL: http://auth:8080
      WEATHER_SERVICE_URL: http://weather:5000
    depends_on:
      - auth
      - weather
```

---

## 🔗 Related

- [← Back to root README](../README.md)
- [🚀 Deployment & Infrastructure documentation](../deployment/README.md)