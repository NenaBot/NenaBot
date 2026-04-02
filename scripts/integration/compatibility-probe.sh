#!/usr/bin/env bash

set -euo pipefail

BACKEND_BASE_URL="${BACKEND_BASE_URL:-http://localhost:8000}"
FRONTEND_BASE_URL="${FRONTEND_BASE_URL:-http://localhost:8080}"
API_BASE_URL="${BACKEND_BASE_URL}/api"
POLL_RETRIES="${POLL_RETRIES:-40}"
POLL_DELAY_SECONDS="${POLL_DELAY_SECONDS:-1}"

LOG_FILE="${PROBE_LOG_FILE:-compatibility-probe.log}"
: >"${LOG_FILE}"

log() {
  local message="$1"
  printf '[probe] %s\n' "${message}" | tee -a "${LOG_FILE}"
}

fail() {
  local message="$1"
  log "ERROR: ${message}"
  exit 1
}

request() {
  local method="$1"
  local url="$2"
  local body="${3:-}"
  local headers_file="$4"
  local response_file="$5"

  local curl_args=(
    --silent
    --show-error
    --location
    --max-time 20
    --request "${method}"
    --dump-header "${headers_file}"
    --output "${response_file}"
    --write-out '%{http_code}'
    "${url}"
  )

  if [[ -n "${body}" ]]; then
    curl_args+=(
      --header 'Content-Type: application/json'
      --data "${body}"
    )
  fi

  curl "${curl_args[@]}"
}

expect_status() {
  local got="$1"
  local expected_csv="$2"
  IFS=',' read -r -a expected_values <<<"${expected_csv}"
  for item in "${expected_values[@]}"; do
    if [[ "${got}" == "${item}" ]]; then
      return 0
    fi
  done
  return 1
}

tmpdir="$(mktemp -d)"
trap 'rm -rf "${tmpdir}"' EXIT

log "Stage A: readiness and static compatibility"

status_code="$(request GET "${BACKEND_BASE_URL}/openapi.json" "" "${tmpdir}/openapi.headers" "${tmpdir}/openapi.json")"
expect_status "${status_code}" "200" || fail "Expected 200 from /openapi.json, got ${status_code}"
python3 - <<'PY' "${tmpdir}/openapi.json" || fail "Invalid OpenAPI JSON"
import json
import sys
with open(sys.argv[1], encoding='utf-8') as f:
    doc = json.load(f)
assert 'paths' in doc and isinstance(doc['paths'], dict)
required = [
    '/api/health',
    '/api/jobs',
    '/api/jobs/latest',
    '/api/profiles',
    '/api/profiles/default',
    '/api/streams/camera/feed',
    '/api/streams/detection/feed',
    '/api/paths',
]
missing = [p for p in required if p not in doc['paths']]
if missing:
    raise SystemExit(f"Missing expected OpenAPI paths: {missing}")
PY

status_code="$(request GET "${FRONTEND_BASE_URL}/" "" "${tmpdir}/frontend.headers" "${tmpdir}/frontend.html")"
expect_status "${status_code}" "200" || fail "Expected 200 from frontend root, got ${status_code}"

status_code="$(request GET "${API_BASE_URL}/health" "" "${tmpdir}/health.headers" "${tmpdir}/health.json")"
expect_status "${status_code}" "200" || fail "Expected 200 from /api/health, got ${status_code}"

status_code="$(request GET "${API_BASE_URL}/profiles" "" "${tmpdir}/profiles.headers" "${tmpdir}/profiles.json")"
expect_status "${status_code}" "200" || fail "Expected 200 from /api/profiles, got ${status_code}"

for stream in camera detection; do
  status_code="$(request GET "${API_BASE_URL}/streams/${stream}/feed" "" "${tmpdir}/${stream}.headers" "${tmpdir}/${stream}.body")"
  expect_status "${status_code}" "200" || fail "Expected 200 from /api/streams/${stream}/feed, got ${status_code}"
  grep -iq '^content-type: multipart/x-mixed-replace' "${tmpdir}/${stream}.headers" || \
    fail "Unexpected content type for ${stream} stream endpoint"
done

log "Stage B: path detection compatibility"

status_code="$(request POST "${API_BASE_URL}/paths" '{"options":{}}' "${tmpdir}/paths.headers" "${tmpdir}/paths.json")"
expect_status "${status_code}" "201" || fail "Expected 201 from /api/paths, got ${status_code}"

python3 - <<'PY' "${tmpdir}/paths.json" >"${tmpdir}/calibrated.txt" || fail "Invalid /api/paths payload"
import json
import sys
with open(sys.argv[1], encoding='utf-8') as f:
    payload = json.load(f)
if 'requestSucceeded' not in payload:
    raise SystemExit('Missing requestSucceeded in /api/paths response')
cal = payload.get('calibration') or {}
print('true' if cal.get('calibrated') is True else 'false')
PY

calibrated="$(cat "${tmpdir}/calibrated.txt")"

status_code="$(request POST "${API_BASE_URL}/path" '{"waypoints":[{"x":10,"y":10},{"x":20,"y":20}]}' "${tmpdir}/path_check.headers" "${tmpdir}/path_check.json")"
expect_status "${status_code}" "200" || fail "Expected 200 from /api/path, got ${status_code}"

log "Stage C: job lifecycle compatibility"

status_code="$(request GET "${API_BASE_URL}/jobs" "" "${tmpdir}/jobs.headers" "${tmpdir}/jobs.json")"
expect_status "${status_code}" "200" || fail "Expected 200 from /api/jobs, got ${status_code}"

status_code="$(request GET "${API_BASE_URL}/jobs/latest" "" "${tmpdir}/latest.headers" "${tmpdir}/latest.json")"
expect_status "${status_code}" "200,404" || fail "Expected 200 or 404 from /api/jobs/latest, got ${status_code}"

if [[ "${calibrated}" == "true" ]]; then
  log "Calibration present, running dry-run create job + polling + SSE checks"

  create_body='{"path":[{"x":650,"y":390},{"x":660,"y":380}],"workZ":0,"workR":0,"dryRun":true}'
  status_code="$(request POST "${API_BASE_URL}/jobs" "${create_body}" "${tmpdir}/create_job.headers" "${tmpdir}/create_job.json")"
  expect_status "${status_code}" "201" || fail "Expected 201 from /api/jobs, got ${status_code}"

  job_id="$(python3 - <<'PY' "${tmpdir}/create_job.json"
import json
import sys
with open(sys.argv[1], encoding='utf-8') as f:
    payload = json.load(f)
job_id = payload.get('id')
if not isinstance(job_id, str) or not job_id:
    raise SystemExit('Missing job id in create job response')
print(job_id)
PY
)"

  terminal_state=""
  for _ in $(seq 1 "${POLL_RETRIES}"); do
    status_code="$(request GET "${API_BASE_URL}/jobs/${job_id}" "" "${tmpdir}/job_poll.headers" "${tmpdir}/job_poll.json")"
    expect_status "${status_code}" "200" || fail "Expected 200 when polling /api/jobs/${job_id}, got ${status_code}"

    state="$(python3 - <<'PY' "${tmpdir}/job_poll.json"
import json
import sys
with open(sys.argv[1], encoding='utf-8') as f:
    payload = json.load(f)
status = payload.get('status') or {}
print(status.get('state', ''))
PY
)"

    if [[ "${state}" == "completed" || "${state}" == "failed" || "${state}" == "stopped" ]]; then
      terminal_state="${state}"
      break
    fi

    sleep "${POLL_DELAY_SECONDS}"
  done

  [[ -n "${terminal_state}" ]] || fail "Timed out waiting for dry-run job terminal state"

  status_code="$(request GET "${API_BASE_URL}/jobs/${job_id}/image" "" "${tmpdir}/image.headers" "${tmpdir}/image.body")"
  expect_status "${status_code}" "200,404" || fail "Expected 200 or 404 from /api/jobs/${job_id}/image, got ${status_code}"

  # Read a short chunk from SSE stream and verify event-stream content type.
  sse_headers="${tmpdir}/sse.headers"
  sse_body="${tmpdir}/sse.body"
  status_code="$(curl --silent --show-error --max-time 8 --location \
    --dump-header "${sse_headers}" \
    --output "${sse_body}" \
    --write-out '%{http_code}' \
    "${API_BASE_URL}/jobs/${job_id}/events")"
  expect_status "${status_code}" "200" || fail "Expected 200 from SSE endpoint, got ${status_code}"
  grep -iq '^content-type: text/event-stream' "${sse_headers}" || fail "SSE endpoint did not return text/event-stream"
  grep -q 'event: job:snapshot' "${sse_body}" || fail "SSE stream did not emit job:snapshot"
else
  log "Calibration unavailable in CI environment; skipping dry-run job + SSE checks"

  create_body='{"path":[{"x":650,"y":390}],"workZ":0,"workR":0,"dryRun":true}'
  status_code="$(request POST "${API_BASE_URL}/jobs" "${create_body}" "${tmpdir}/create_uncalibrated.headers" "${tmpdir}/create_uncalibrated.json")"
  expect_status "${status_code}" "409" || fail "Expected 409 from /api/jobs when uncalibrated, got ${status_code}"
fi

log "Compatibility probe completed successfully"

if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
  {
    echo "## FE-BE Compatibility Probe"
    echo
    echo "- Backend: ${BACKEND_BASE_URL}"
    echo "- Frontend: ${FRONTEND_BASE_URL}"
    echo "- Result: ✅ passed"
    if [[ "${calibrated}" == "true" ]]; then
      echo "- Job/SSE checks: executed"
    else
      echo "- Job/SSE checks: skipped (no calibration available in environment)"
    fi
  } >>"${GITHUB_STEP_SUMMARY}"
fi
