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

## Mock Dev Mode

Use this mode for frontend hot reload with backend mock mode enabled:

```bash
docker compose -f docker-compose.yml -f docker-compose.mock.dev.yml up -d --build
```

Open:

- Frontend (Vite via container): http://localhost:8080
- Backend docs: http://localhost:8000/docs

Stop:

```bash
docker compose -f docker-compose.yml -f docker-compose.mock.dev.yml down
```

Troubleshooting:

- If frontend container logs show npm lockfile errors together with permission errors, check that the frontend bind mount in `docker-compose.mock.dev.yml` uses `:Z` (SELinux relabel on SELinux-enabled hosts).

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

## Documentation

### Source Code Documentation

Generate comprehensive cross-referenced documentation for both Python (backend) and TypeScript (frontend) code using Doxygen:

```bash
./scripts/generate-docs.sh
```

Generated documentation is saved to `docs/generated/html/`. Open `docs/generated/html/index.html` in a browser to view.

To automatically open the generated documentation in your default browser:

```bash
./scripts/generate-docs.sh --open
```

**Requirements:**
- Doxygen must be installed. See [Doxygen Installation](#doxygen-installation) below.

#### Doxygen Installation

**Ubuntu/Debian:**
```bash
sudo apt-get install doxygen
```

**macOS:**
```bash
brew install doxygen
```

**Windows:**
- Download from [doxygen.nl](https://www.doxygen.nl/download.html), or
- Via Chocolatey: `choco install doxygen`

### Project Docs

Additional project documentation:

- [docs/DOCUMENTATION.md](docs/DOCUMENTATION.md) — Doxygen setup details and regeneration info
- [backend/README.md](backend/README.md)
- [frontend/README.md](frontend/README.md)
