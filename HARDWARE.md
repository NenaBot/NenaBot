# Hardware Passthrough (Linux)

Use [docker-compose.hardware.yml](docker-compose.hardware.yml) to pass robot + camera devices into the backend container.

## Run

```bash
docker compose -f docker-compose.yml -f docker-compose.hardware.yml up -d --build
```

## Typical Device Paths

- Robot: `/dev/ttyUSB0` or `/dev/ttyACM0`
- Camera: `/dev/video0`

If needed, edit [docker-compose.hardware.yml](docker-compose.hardware.yml).

## Quick Checks

```bash
ls /dev/ttyUSB* /dev/ttyACM* /dev/video*
docker compose ps
docker compose logs -f backend
```

## If It Fails

- Wrong device path in compose override
- Missing permissions to `/dev/tty*` or `/dev/video*`
