#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
COMMAND=${1:-}
ENV=${2:-}

if [ -z "$COMMAND" ] || [ -z "$ENV" ]; then
  echo "Usage: $0 <command> <environment>"
  echo ""
  echo "Local commands (environment: local):"
  echo "  start   Build and start sam local start-api on http://localhost:3000"
  echo "  stop    Stop the running sam local process"
  echo "  logs    Tail the sam local log"
  echo ""
  echo "AWS commands (environment: dev | qa | prod):"
  echo "  deploy  Build, deploy stack, and run migrations"
  echo "  destroy Tear down the stack"
  echo "  outputs Show CloudFormation stack outputs"
  echo ""
  echo "Examples:"
  echo "  $0 start local"
  echo "  $0 deploy dev"
  exit 1
fi

ENV_DIR="${SCRIPT_DIR}/environments/${ENV}"

if [ ! -d "$ENV_DIR" ]; then
  echo "Error: Environment directory $ENV_DIR not found"
  exit 1
fi

# ── Local (sam local start-api) ───────────────────────────────────────────────

PIDFILE="${SCRIPT_DIR}/.sam.pid"
LOGFILE="${SCRIPT_DIR}/.sam.log"

start_local() {
  if [ -f "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
    echo "Already running (PID $(cat "$PIDFILE"))"
    exit 1
  fi

  ENV_FILE="${ENV_DIR}/env.json"
  if [ ! -f "$ENV_FILE" ]; then
    echo "Error: $ENV_FILE not found"
    exit 1
  fi

  cd "$SCRIPT_DIR"

  docker network create jobber-net 2>/dev/null || true

  sam build --use-container

  nohup sam local start-api \
    --warm-containers EAGER \
    --docker-network jobber-net \
    --env-vars "${ENV_FILE}" \
    --port 3000 \
    > "$LOGFILE" 2>&1 &
  echo $! > "$PIDFILE"
  echo "Started on http://localhost:3000 (PID $!) — logs at $LOGFILE"
}

stop_local() {
  if [ -f "$PIDFILE" ]; then
    PID=$(cat "$PIDFILE")
    if kill -0 "$PID" 2>/dev/null; then
      kill "$PID"
      echo "Stopped (PID $PID)"
    else
      echo "Process $PID not found (stale pidfile)"
    fi
    rm -f "$PIDFILE"
  else
    echo "Not running"
  fi
}

logs_local() {
  if [ -f "$LOGFILE" ]; then
    tail -f "$LOGFILE"
  else
    echo "No log file found"
  fi
}

# ── AWS (SAM deploy) ──────────────────────────────────────────────────────────

STACK_NAME="jobber-backend-${ENV}"
ARTIFACT_BUCKET="jobber-backend-lambda-${ENV}"

deploy_aws() {
  PARAMS_FILE="${ENV_DIR}/parameters.json"
  if [ ! -f "$PARAMS_FILE" ]; then
    echo "Error: $PARAMS_FILE not found"
    exit 1
  fi

  echo "Deploying jobber-backend to ${ENV}..."

  aws s3 mb s3://${ARTIFACT_BUCKET} --region ca-central-1 2>/dev/null || true

  cd "$SCRIPT_DIR"
  sam build --use-container

  sam deploy \
    --stack-name "${STACK_NAME}" \
    --s3-bucket "${ARTIFACT_BUCKET}" \
    --parameter-overrides $(jq -r 'to_entries | map("\(.key)=\(.value)") | join(" ")' "$PARAMS_FILE") \
    --capabilities CAPABILITY_IAM \
    --region ca-central-1 \
    --no-confirm-changeset \
    --no-fail-on-empty-changeset

  API_URL=$(aws cloudformation describe-stacks --stack-name "$STACK_NAME" \
    --query "Stacks[0].Outputs[?OutputKey=='ApiUrl'].OutputValue" \
    --output text --region ca-central-1)

  MIGRATE_SECRET=$(jq -r '.MigrateSecret' "$PARAMS_FILE")

  echo ""
  echo "Running migrations and seeds..."
  curl -sf -X POST "${API_URL}migrate" \
    -H "X-Migrate-Token: ${MIGRATE_SECRET}" | jq .
  echo ""

  echo ""
  echo "Stack outputs:"
  aws cloudformation describe-stacks --stack-name "$STACK_NAME" --query "Stacks[0].Outputs" --output table

  echo "jobber-backend-${ENV} deployed successfully"
}

destroy_aws() {
  if ! aws cloudformation describe-stacks --stack-name "$STACK_NAME" >/dev/null 2>&1; then
    echo "Stack $STACK_NAME does not exist. Nothing to destroy."
    exit 0
  fi

  echo "Destroying jobber-backend-${ENV}..."
  sam delete --stack-name "$STACK_NAME" --no-prompts --region ca-central-1

  aws s3 rb s3://${ARTIFACT_BUCKET} --force 2>/dev/null || true

  echo "Stack ${STACK_NAME} deleted."
}

outputs_aws() {
  aws cloudformation describe-stacks --stack-name "$STACK_NAME" --query "Stacks[0].Outputs" --output table
}

# ── Dispatch ──────────────────────────────────────────────────────────────────

case "${ENV}" in
  local)
    case "${COMMAND}" in
      start) start_local ;;
      stop)  stop_local  ;;
      logs)  logs_local  ;;
      *)
        echo "Unknown local command: ${COMMAND} (use start | stop | logs)"
        exit 1
        ;;
    esac
    ;;
  *)
    case "${COMMAND}" in
      deploy)  deploy_aws  ;;
      destroy) destroy_aws ;;
      outputs) outputs_aws ;;
      *)
        echo "Unknown AWS command: ${COMMAND} (use deploy | destroy | outputs)"
        exit 1
        ;;
    esac
    ;;
esac
