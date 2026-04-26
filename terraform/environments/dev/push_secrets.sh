#!/bin/bash
# Step 1 : chmod +x push_secrets.sh
# Step 2 :
#   export MONGO_USERNAME="carts"
#   export MONGO_PASSWORD="..."
#   export MONGO_URI="mongodb://carts:password@host:27017"
#   export MARIADB_ROOT_PASSWORD="..."
#   export MARIADB_USER="root"
#   export MARIADB_PASSWORD="..."
#   export MARIADB_DATABASE="catalogue"
#   export REDIS_PASSWORD="..."
#   export RABBITMQ_USERNAME="guest"
#   export RABBITMQ_PASSWORD="..."
# Step 3 : ./push_secrets.sh dev

set -e

ENVIRONMENT=${1:-dev}    
REGION="us-east-2"
PROFILE=${AWS_PROFILE}

# colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}Pushing secrets for environment: ${ENVIRONMENT}${NC}"
echo "Region:  $REGION"
echo "Profile: $PROFILE"
echo ""

REQUIRED_VARS=(
  "MONGO_PASSWORD"
  "MONGO_URI"
  "MARIADB_ROOT_PASSWORD"
  "MARIADB_PASSWORD"
  "REDIS_PASSWORD"
  "RABBITMQ_PASSWORD"
)

MISSING=0
for VAR in "${REQUIRED_VARS[@]}"; do
  if [ -z "${!VAR}" ]; then
    echo -e "${RED}ERROR: $VAR is not set${NC}"
    MISSING=1
  fi
done

if [ $MISSING -eq 1 ]; then
  echo ""
  echo "Please export all required variables before running:"
  echo "  export MONGO_PASSWORD=..."
  echo "  export MONGO_URI=..."
  echo "  export MARIADB_ROOT_PASSWORD=..."
  echo "  export MARIADB_PASSWORD=..."
  echo "  export REDIS_PASSWORD=..."
  echo "  export RABBITMQ_PASSWORD=..."
  exit 1
fi

push_secret() {
  local SECRET_ID=$1
  local SECRET_VALUE=$2

  echo -n "Pushing ${SECRET_ID}... "

  aws secretsmanager put-secret-value \
    --secret-id    "$SECRET_ID" \
    --secret-string "$SECRET_VALUE" \
    --region       "$REGION" \
    --profile      "$PROFILE" \
    --output text > /dev/null

  echo -e "${GREEN}✅${NC}"
}


# MongoDB — carts service
push_secret \
  "${ENVIRONMENT}/carts-db" \
  "$(cat <<EOF
{
  "MONGO_INITDB_ROOT_USERNAME": "${MONGO_USERNAME:-carts}",
  "MONGO_INITDB_ROOT_PASSWORD": "${MONGO_PASSWORD}",
  "SPRING_DATA_MONGODB_URI":    "${MONGO_URI}"
}
EOF
)"

# MariaDB — catalogue service
push_secret \
  "${ENVIRONMENT}/catalogue-db" \
  "$(cat <<EOF
{
  "MARIADB_ROOT_PASSWORD": "${MARIADB_ROOT_PASSWORD}",
  "MARIADB_USER":          "${MARIADB_USER:-root}",
  "MARIADB_PASSWORD":      "${MARIADB_PASSWORD}",
  "MARIADB_DATABASE":      "${MARIADB_DATABASE:-catalogue}"
}
EOF
)"

# Redis — session service
push_secret \
  "${ENVIRONMENT}/session-db" \
  "$(cat <<EOF
{
  "REDIS_PASSWORD": "${REDIS_PASSWORD}"
}
EOF
)"

# RabbitMQ — message broker
push_secret \
  "${ENVIRONMENT}/rabbitmq" \
  "$(cat <<EOF
{
  "RABBITMQ_DEFAULT_USER": "${RABBITMQ_USERNAME:-guest}",
  "RABBITMQ_DEFAULT_PASS": "${RABBITMQ_PASSWORD}"
}
EOF
)"

echo ""
echo -e "${GREEN}All secrets pushed successfully for '${ENVIRONMENT}'"
echo ""
