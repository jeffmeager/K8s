apiVersion: v1
kind: Secret
metadata:
  name: webapp-secrets
  namespace: default
type: Opaque
stringData:
  mongodb-uri: "mongodb://${MONGODB_USERNAME}:${MONGODB_PASSWORD}@${MONGODB_IP}:27017"
  secret-key: "${MONGODB_SECRET_KEY}"