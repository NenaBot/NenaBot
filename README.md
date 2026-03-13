# NenaBot

Frontend + backend in one repo, runnable with Docker Compose.

## Quick Start

```bash
git submodule update --init --recursive
docker compose up -d --build
```

Open:

- Frontend: http://localhost:8080
- Backend docs: http://localhost:8000/docs

Stop:

```bash
docker compose down
```

## Hardware Mode (Linux)

```bash
docker compose -f docker-compose.yml -f docker-compose.hardware.yml up -d --build
```

See [HARDWARE.md](HARDWARE.md) for device mapping.

## Config

Root `.env` controls ports and frontend API build vars.

Common values:

```env
BACKEND_PORT=8000
FRONTEND_PORT=8080
FRONTEND_VITE_API_URL=http://localhost:8000
```

## Submodules

Automatic submodule update workflow:

- [SUBMODULES.md](SUBMODULES.md)

## Project Docs

- [backend/README.md](backend/README.md)
- [frontend/README.md](frontend/README.md)
