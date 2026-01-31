#!/bin/bash
#
# Sync README.md to Docker Hub repository description
#
# Usage:
#   ./scripts/sync-readme.sh
#
# Requires DOCKERHUB_USERNAME and DOCKERHUB_TOKEN environment variables,
# or will prompt for password interactively.
#

set -e

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
README_FILE="${REPO_ROOT}/README.md"
DOCKERHUB_REPO="getgrav/grav"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

# Check README exists
if [ ! -f "$README_FILE" ]; then
    echo -e "${RED}Error: README.md not found at ${README_FILE}${NC}"
    exit 1
fi

# Get credentials
USERNAME="${DOCKERHUB_USERNAME:-getgrav}"

if [ -z "$DOCKERHUB_TOKEN" ]; then
    echo -n "Docker Hub password for ${USERNAME}: "
    read -s PASSWORD
    echo
else
    PASSWORD="$DOCKERHUB_TOKEN"
fi

echo "Authenticating with Docker Hub..."

# Common headers
USER_AGENT="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36"

# Get JWT token
LOGIN_RESPONSE=$(curl -s -X POST \
    -H "Content-Type: application/json" \
    -H "User-Agent: ${USER_AGENT}" \
    -d "{\"username\":\"${USERNAME}\",\"password\":\"${PASSWORD}\"}" \
    https://hub.docker.com/v2/users/login/)

TOKEN=$(echo "$LOGIN_RESPONSE" | jq -r .token 2>/dev/null)

if [ "$TOKEN" = "null" ] || [ -z "$TOKEN" ]; then
    echo -e "${RED}Error: Failed to authenticate with Docker Hub${NC}"
    echo "Response: $LOGIN_RESPONSE" | head -c 500
    exit 1
fi

echo "Updating repository description..."

# Update description
RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}" -X PATCH \
    -H "Authorization: Bearer ${TOKEN}" \
    -H "Content-Type: application/json" \
    -H "User-Agent: ${USER_AGENT}" \
    -d "$(jq -n --arg desc "$(cat "$README_FILE")" --arg short "Official Grav CMS Docker Image" '{full_description: $desc, description: $short}')" \
    "https://hub.docker.com/v2/repositories/${DOCKERHUB_REPO}/")

# Extract HTTP code
HTTP_CODE=$(echo "$RESPONSE" | grep "HTTP_CODE:" | cut -d: -f2)
BODY=$(echo "$RESPONSE" | grep -v "HTTP_CODE:")

# Check for errors
if [ "$HTTP_CODE" != "200" ]; then
    echo -e "${RED}Error: HTTP ${HTTP_CODE}${NC}"
    echo "$BODY" | jq . 2>/dev/null || echo "$BODY"
    exit 1
fi

# Verify the update
if echo "$BODY" | jq -e '.full_description' > /dev/null 2>&1; then
    DESC_LENGTH=$(echo "$BODY" | jq -r '.full_description | length')
    echo -e "${GREEN}Successfully updated Docker Hub description for ${DOCKERHUB_REPO}${NC}"
    echo "Description length: ${DESC_LENGTH} characters"
else
    echo -e "${RED}Warning: Response doesn't contain full_description${NC}"
    echo "$BODY" | jq . 2>/dev/null || echo "$BODY"
fi
