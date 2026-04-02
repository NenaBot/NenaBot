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

## Integration Compatibility CI

The root repo includes a separate workflow to verify frontend-backend compatibility
against the current submodule pointers:

- `.github/workflows/integration-compatibility.yml`

What it checks nightly:

- Compose stack boots (`frontend` + `backend`)
- Key API routes and stream endpoints respond as expected
- Path and job lifecycle compatibility checks
- SSE endpoint compatibility (`/api/jobs/{id}/events`) when calibration is available

You can also trigger it manually with **Run workflow** from the Actions tab.

## Project Docs

- [backend/README.md](backend/README.md)
- [frontend/README.md](frontend/README.md)
