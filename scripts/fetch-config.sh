#!/bin/bash
set -e

CONFIG_API_URL=$1

if [ -z "$CONFIG_API_URL" ]; then
  echo "Usage: $0 <config-api-url>"
  exit 1
fi

echo "Fetching config.json from $CONFIG_API_URL ..."

# config.json 다운로드
curl -s "$CONFIG_API_URL/config" -o config.json

echo "config.json fetched successfully!"