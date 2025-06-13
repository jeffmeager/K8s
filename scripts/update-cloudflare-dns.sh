#!/bin/bash
set -o errexit -o pipefail -o nounset

if [[ $# -ne 3 ]]; then
  echo "Usage: $0 <CLOUDFLARE_API_TOKEN> <MONGODB_IP> <WEBAPP_INGRESS_HOSTNAME>"
  exit 1
fi

CF_API_TOKEN="$1"
MONGODB_IP="$2"
WEBAPP_INGRESS_HOSTNAME="$3"

CF_ZONE_NAME="meager.net"

echo "🌐 Updating Cloudflare DNS:"
echo "  - mongodb.meager.net -> ${MONGODB_IP}"
echo "  - webapp.meager.net  -> ${WEBAPP_INGRESS_HOSTNAME}"

# Get Cloudflare Zone ID
CF_ZONE_ID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=${CF_ZONE_NAME}" \
    -H "Authorization: Bearer ${CF_API_TOKEN}" \
    -H "Content-Type: application/json" \
    | jq -r '.result[0].id')

if [[ "$CF_ZONE_ID" == "null" || -z "$CF_ZONE_ID" ]]; then
    echo "❌ Failed to fetch Cloudflare Zone ID for ${CF_ZONE_NAME}"
    exit 1
fi

echo "✅ Zone ID: $CF_ZONE_ID"

# Function to perform a retryable API call with exponential backoff
retry_curl() {
    local CURL_COMMAND="$1"
    local MAX_RETRIES=5
    local RETRY_DELAY=2

    local attempt=1
    while true; do
        echo "➡️ Attempt \$attempt: $CURL_COMMAND"
        eval "$CURL_COMMAND" && break

        if (( attempt >= MAX_RETRIES )); then
            echo "❌ All $MAX_RETRIES attempts failed. Giving up."
            return 1
        fi

        echo "⚠️ Attempt $attempt failed. Retrying in $RETRY_DELAY seconds..."
        sleep $RETRY_DELAY
        RETRY_DELAY=$(( RETRY_DELAY * 2 ))  # Exponential backoff
        attempt=$(( attempt + 1 ))
    done
}

# Function to upsert a DNS record
upsert_record() {
    local RECORD_NAME="$1"
    local RECORD_TYPE="$2"
    local RECORD_CONTENT="$3"

    echo "🔍 Processing $RECORD_NAME ($RECORD_TYPE)"

    # Check if record exists
    RECORD_ID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$CF_ZONE_ID/dns_records?name=$RECORD_NAME&type=$RECORD_TYPE" \
        -H "Authorization: Bearer ${CF_API_TOKEN}" \
        -H "Content-Type: application/json" \
        | jq -r '.result[0].id')

    if [ "$RECORD_ID" != "null" ]; then
        echo "🔄 Updating existing record ID $RECORD_ID for $RECORD_NAME"
        retry_curl "curl -s -X PUT \"https://api.cloudflare.com/client/v4/zones/$CF_ZONE_ID/dns_records/$RECORD_ID\" \
            -H \"Authorization: Bearer ${CF_API_TOKEN}\" \
            -H \"Content-Type: application/json\" \
            --data '{
                \"type\": \"$RECORD_TYPE\",
                \"name\": \"$RECORD_NAME\",
                \"content\": \"$RECORD_CONTENT\",
                \"ttl\": 300,
                \"proxied\": false
            }' | jq -r '.success'"
    else
        echo "➕ Creating new record for $RECORD_NAME"
        retry_curl "curl -s -X POST \"https://api.cloudflare.com/client/v4/zones/$CF_ZONE_ID/dns_records\" \
            -H \"Authorization: Bearer ${CF_API_TOKEN}\" \
            -H \"Content-Type: application/json\" \
            --data '{
                \"type\": \"$RECORD_TYPE\",
                \"name\": \"$RECORD_NAME\",
                \"content\": \"$RECORD_CONTENT\",
                \"ttl\": 300,
                \"proxied\": false
            }' | jq -r '.success'"
    fi
}

# Upsert mongodb A record
upsert_record "mongodb.meager.net" "A" "${MONGODB_IP}"

# Upsert webapp CNAME record
upsert_record "webapp.meager.net" "CNAME" "${WEBAPP_INGRESS_HOSTNAME}"

echo "✅ Cloudflare DNS update complete."