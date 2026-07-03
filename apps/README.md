# 📦 SkyOps — Applications

This document covers the application layer: service descriptions, local development, environment variables, API references, and Docker configuration.

---

## 🏗️ Services Overview

| Service | Language | Port | Description |
|---|---|---|---|
| `weather` | Python / Flask | 5000 | Fetches weather data from RapidAPI (weatherapi-com) |
| `auth` | Go / Gin | 8080 | User registration, login, and JWT issuance |
| `UI` | Node.js / Express | 3000 | Web frontend (BFF — proxies auth & weather) |
| `mysql` | MySQL 8 | 3306 | Persistent database for the auth service |

The UI talks to auth and weather over the cluster network (or Docker Compose service names locally). Browsers hit the UI only; the UI calls `auth` and `weather` internally.

---

## 📁 Directory Structure

```
apps/
├── auth/
│   ├── main/main.go       # HTTP handlers & JWT logic
│   ├── authdb/            # MySQL access layer
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
│   ├── public/            # Static HTML/JS assets
│   └── Dockerfile
│
└── mysql-init/
    └── init.sql           # Reference schema (also used by Docker Compose)
```

---

## 🌦️ Weather Service (Python)

Fetches current weather from [weatherapi-com on RapidAPI](https://rapidapi.com/weatherapi/api/weatherapi-com) and returns JSON. The UI calls this service directly; end users go through the UI BFF at `/weather/:city`.

### Endpoints

| Method | Path | Description |
|---|---|---|
| `GET` | `/` | Health check — returns plain text |
| `GET` | `/{city}` | Current weather for a city (e.g. `/London`) |

### Environment Variables

| Variable | Required | Default | Description |
|---|---|---|---|
| `APIKEY` | ✅ | — | RapidAPI key (`x-rapidapi-key` header) |

Flask listens on port **5000** (Dockerfile `EXPOSE 5000`; default Flask port when run via `python main.py`).

### Run Locally

```bash
cd apps/weather
pip install -r requirements.txt
APIKEY=your_rapidapi_key python main.py
```

### Docker

```bash
docker build -t skyops/weather ./apps/weather
docker run -p 5000:5000 -e APIKEY=your_rapidapi_key skyops/weather
```

---

## 🔐 Auth Service (Go)

Handles user registration, login, and JWT issuance. Stores users in MySQL database **`weatherapp`**.

### Endpoints

| Method | Path | Description |
|---|---|---|
| `GET` | `/` | Health check |
| `POST` | `/users` | Register — JSON body: `{ "user_name", "user_password" }` |
| `POST` | `/users/:id` | Login — same JSON body; `:id` matches username in UI calls |

Successful login returns `{ "JWT": "<token>" }`.

### Environment Variables

| Variable | Required | Default | Description |
|---|---|---|---|
| `DB_HOST` | ❌ | `127.0.0.1` | MySQL hostname |
| `DB_PORT` | ❌ | `3306` | MySQL port |
| `DB_USER` | ❌ | `authuser` | MySQL username |
| `DB_PASSWORD` | ❌ | `authpassword` | MySQL password |
| `DB_NAME` | ❌ | `weatherapp` | Database name |
| `SECRET_KEY` | ❌ | *(built-in dev default)* | JWT signing secret — **must match UI `SECRET_KEY`** |
| `AUTH_PORT` | ❌ | `8080` | HTTP listen port |

### Run Locally

Requires a running MySQL instance with the `weatherapp` database and `authuser` (see [MySQL](#-mysql) or Docker Compose below).

```bash
cd apps/auth
go mod download
DB_HOST=localhost DB_USER=authuser DB_PASSWORD=my-secret-pw \
DB_NAME=weatherapp SECRET_KEY=local_dev_secret go run ./main
```

### Docker

```bash
docker build -t skyops/auth ./apps/auth
docker run -p 8080:8080 \
  -e DB_HOST=host.docker.internal \
  -e DB_USER=authuser \
  -e DB_PASSWORD=my-secret-pw \
  -e DB_NAME=weatherapp \
  -e SECRET_KEY=local_dev_secret \
  skyops/auth
```

---

## 🖥️ UI (Node.js / Express)

Serves login/signup pages, sets an HTTP-only JWT cookie, and proxies weather requests to the weather service.

### UI Routes (browser-facing)

| Method | Path | Description |
|---|---|---|
| `GET` | `/` | Main app (requires auth cookie) |
| `GET` | `/login`, `/signup` | Auth pages |
| `POST` | `/login`, `/signup` | Form handlers → auth service |
| `GET` | `/logout` | Clears JWT cookie |
| `GET` | `/health` | Health check |
| `GET` | `/weather/:city` | Proxies to weather service `GET /:city` |

### Environment Variables

| Variable | Default | Description |
|---|---|---|
| `PORT` | `3000` | HTTP listen port |
| `AUTH_HOST` | `localhost` | Auth service hostname |
| `AUTH_PORT` | `8080` | Auth service port |
| `WEATHER_HOST` | `localhost` | Weather service hostname |
| `WEATHER_PORT` | `5000` | Weather service port |
| `SECRET_KEY` | *(built-in dev default)* | JWT verification secret — **must match auth `SECRET_KEY`** |

### Run Locally

Start auth, weather, and MySQL first (or use Docker Compose).

```bash
cd apps/UI
npm install
AUTH_HOST=localhost AUTH_PORT=8080 \
WEATHER_HOST=localhost WEATHER_PORT=5000 \
SECRET_KEY=local_dev_secret npm start
```

Open [http://localhost:3000](http://localhost:3000).

### Docker

```bash
docker build -t skyops/ui ./apps/UI
docker run -p 3000:3000 \
  -e AUTH_HOST=auth -e AUTH_PORT=8080 \
  -e WEATHER_HOST=weather -e WEATHER_PORT=5000 \
  -e SECRET_KEY=local_dev_secret \
  skyops/ui
```

---

## 🗄️ MySQL

In Kubernetes, MySQL 8 runs as a `StatefulSet` with a PVC (`gp2` storage class, EBS CSI driver). Schema and app user are created by the init `Job` in `deployment/k8s/base/mysql/init-job.yaml`.

Locally, `apps/mysql-init/init.sql` creates:

- Database: `weatherapp`
- User: `authuser` / password: `my-secret-pw`

### Kubernetes Secrets (via ESO)

| Kubernetes Secret key | AWS Secrets Manager key | Used by |
|---|---|---|
| `auth-password` | `skyops-dev/auth-password` | Auth `DB_PASSWORD`, MySQL init Job |
| `root-password` | `skyops-dev/root-password` | MySQL root, init Job |
| `secret-key` | `skyops-dev/secret-key` | Auth `SECRET_KEY` |
| `apikey` | `skyops-dev/apikey` | Weather `APIKEY` |

See [deployment/README.md → Secrets](../deployment/README.md#-secrets--external-secrets-operator).

---

## 🐳 Local Development — Docker Compose

Run the full stack from the repository root:

```bash
docker compose up --build
```

| Service | URL |
|---|---|
| UI | [http://localhost:3000](http://localhost:3000) |
| Auth | [http://localhost:8080](http://localhost:8080) |
| Weather | [http://localhost:5000](http://localhost:5000) |
| MySQL | `localhost:3306` |

Set your RapidAPI key before starting:

```bash
export RAPIDAPI_KEY=your_key
docker compose up --build
```

Or create a `.env` file in the repo root:

```env
RAPIDAPI_KEY=your_key
```

Configuration lives in [`docker-compose.yml`](../docker-compose.yml) at the repo root.

---

## 🔗 Related

- [← Back to root README](../README.md)
- [🚀 Deployment & Infrastructure documentation](../deployment/README.md)
