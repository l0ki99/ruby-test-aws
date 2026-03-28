#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
COMMAND=${1:-}
ENV=${2:-}

if [ -z "$COMMAND" ] || [ -z "$ENV" ]; then
  echo "Usage: $0 <command> <environment>"
  echo ""
  echo "Local commands (environment: local):"
  echo "  start   Write .env.local and start Vite dev server on http://localhost:8091"
  echo ""
  echo "AWS commands (environment: dev | qa | prod):"
  echo "  deploy  Deploy stack, build, and sync to S3"
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

# ── Local (Vite dev server) ───────────────────────────────────────────────────

start_local() {
  # Point the frontend at the local SAM API (aws-backend/deploy.sh start local)
  cat > "${SCRIPT_DIR}/src/.env.local" <<EOF
VITE_API_BASE_URL=http://localhost:3000
EOF
  echo "Wrote src/.env.local pointing at http://localhost:3000"

  cd "${SCRIPT_DIR}/src"
  npm run dev
}

# ── AWS (CloudFormation) ──────────────────────────────────────────────────────

STACK_NAME="jobber-frontend-${ENV}"
BACKEND_STACK="jobber-backend-${ENV}"

get_output() {
  aws cloudformation describe-stacks --stack-name "$1" \
    --query "Stacks[0].Outputs[?OutputKey=='$2'].OutputValue" --output text --region ca-central-1
}

deploy_aws() {
  PARAMS_FILE="${ENV_DIR}/parameters.json"
  if [ ! -f "$PARAMS_FILE" ]; then
    echo "Error: $PARAMS_FILE not found"
    exit 1
  fi

  echo "Deploying jobber-frontend to ${ENV}..."

  aws cloudformation deploy \
    --template-file "${SCRIPT_DIR}/template.yaml" \
    --stack-name "${STACK_NAME}" \
    --parameter-overrides $(jq -r 'to_entries | map("\(.key)=\(.value)") | join(" ")' "$PARAMS_FILE") \
    --region ca-central-1

  API_URL=$(get_output "$BACKEND_STACK" ApiUrl)

  cat > "${SCRIPT_DIR}/src/.env" <<EOF
VITE_API_BASE_URL=${API_URL}
EOF
  echo "Wrote src/.env for ${ENV}"

  BUCKET=$(get_output "$STACK_NAME" FrontendBucketName)
  DIST_ID=$(get_output "$STACK_NAME" DistributionId)

  cd "${SCRIPT_DIR}/src"
  if [ -f .env.local ]; then mv .env.local .env.local.bak; fi
  npm run build
  if [ -f .env.local.bak ]; then mv .env.local.bak .env.local; fi

  aws s3 sync dist/ "s3://${BUCKET}" --delete --region ca-central-1
  aws cloudfront create-invalidation --distribution-id "$DIST_ID" --paths "/*"

  echo ""
  echo "Stack outputs:"
  aws cloudformation describe-stacks --stack-name "$STACK_NAME" --query "Stacks[0].Outputs" --output table

  echo "jobber-frontend-${ENV} deployed successfully"
}

destroy_aws() {
  if ! aws cloudformation describe-stacks --stack-name "$STACK_NAME" --region ca-central-1 >/dev/null 2>&1; then
    echo "Stack $STACK_NAME does not exist. Nothing to destroy."
    exit 0
  fi

  echo "Destroying jobber-frontend-${ENV}..."

  BUCKET=$(get_output "$STACK_NAME" FrontendBucketName 2>/dev/null || true)
  if [ -n "$BUCKET" ] && [ "$BUCKET" != "None" ]; then
    aws s3 rm "s3://${BUCKET}" --recursive --region ca-central-1
  fi

  aws cloudformation delete-stack --stack-name "$STACK_NAME" --region ca-central-1
  aws cloudformation wait stack-delete-complete --stack-name "$STACK_NAME" --region ca-central-1

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
      *)
        echo "Unknown local command: ${COMMAND} (use start)"
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
