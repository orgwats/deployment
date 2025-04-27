#!/bin/bash
set -e

TARGET=$1 # aws 또는 gcp
ROOT_DIR=$(dirname "$(dirname "$(realpath "$0")")") # 스크립트 기준으로 상위
CONFIG_FILE="${ROOT_DIR}/config.yml"
CONFIG_JSON="${ROOT_DIR}/config.json"
ENV_FILE="${ROOT_DIR}/.env"
DOCKER_COMPOSE_FILE="${ROOT_DIR}/docker-compose.yml"

if [ -z "$TARGET" ]; then
  echo "Usage: $0 <aws|gcp>"
  exit 1
fi

# .env 파일 읽기
if [ -f "$ENV_FILE" ]; then
  export $(grep -v '^#' "$ENV_FILE" | xargs)
else
  echo ".env file not found!"
  exit 1
fi

# DOCKER_REGISTRY 읽기
if [ -z "$DOCKER_REGISTRY" ]; then
  echo "DOCKER_REGISTRY is not set in .env"
  exit 1
fi

# LOG_VOLUME 읽기
if [ -z "$LOG_VOLUME" ]; then
  echo "LOG_VOLUME is not set in .env"
  exit 1
fi

# 서비스 리스트 읽기
SERVICE_LIST=$(yq e ".${TARGET}[]" "$CONFIG_FILE")

if [ -z "$SERVICE_LIST" ]; then
  echo "No services found for target: $TARGET"
  exit 1
fi

# docker-compose.yml 생성
echo "services:" > "$DOCKER_COMPOSE_FILE"

for service in $SERVICE_LIST; do
  service_upper=$(echo "$service" | tr '[:lower:]' '[:upper:]')

  port=$(jq -r ".service[\"$service\"].port" "$CONFIG_JSON")

  cat <<EOF >> "$DOCKER_COMPOSE_FILE"
  ${service}-service:
    image: ${DOCKER_REGISTRY}/${service}:latest
    container_name: ${service}-service
    ports:
      - "${port}:${port}"
    volumes:
      - "${LOG_VOLUME}/${service}:/logs"

EOF
done

echo "docker-compose.yml generated successfully for $TARGET"