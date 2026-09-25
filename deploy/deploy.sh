#!/bin/bash
set -euo pipefail

STATE_FILE="deploy/active_color.txt"
COMPOSE_FILE="docker-compose.blue-green.yml"
NGINX_CONF="nginx/nginx.conf"

# Couleur actuellement active (par defaut : blue si le fichier n'existe pas encore)
if [ -f "$STATE_FILE" ]; then
    ACTIVE_COLOR=$(cat "$STATE_FILE")
else
    ACTIVE_COLOR="blue"
fi

if [ "$ACTIVE_COLOR" == "blue" ]; then
    NEW_COLOR="green"
else
    NEW_COLOR="blue"
fi

echo "Couleur active actuelle : $ACTIVE_COLOR"
echo "Nouvelle couleur a deployer : $NEW_COLOR"

echo "Demarrage de $NEW_COLOR..."
docker compose -f "$COMPOSE_FILE" --profile "$ACTIVE_COLOR" --profile "$NEW_COLOR" up -d nginx redis
docker compose -f "$COMPOSE_FILE" --profile "$NEW_COLOR" up -d --build "app-$NEW_COLOR"
echo "Attente que $NEW_COLOR soit healthy..."
MAX_RETRIES=15
RETRY_COUNT=0
CONTAINER_NAME="atelier-devops-acheraf-app-$NEW_COLOR-1"

until [ "$(docker inspect --format='{{.State.Health.Status}}' "$CONTAINER_NAME" 2>/dev/null)" == "healthy" ]; do    RETRY_COUNT=$((RETRY_COUNT + 1))
    if [ "$RETRY_COUNT" -ge "$MAX_RETRIES" ]; then
        echo "ERREUR : $NEW_COLOR n'est pas devenu healthy a temps. Abandon."
        docker compose -f "$COMPOSE_FILE" stop "app-$NEW_COLOR"
        exit 1
    fi
    echo "Tentative $RETRY_COUNT/$MAX_RETRIES, nouvelle verification dans 2s..."
    sleep 2
done

echo "$NEW_COLOR est healthy."

# Smoke test : on interroge /status directement sur le conteneur (via son nom, port interne 5000)
echo "Smoke test sur $NEW_COLOR..."
SMOKE_RESPONSE=$(docker run --rm --network atelier-devops-acheraf_app-network curlimages/curl:latest -s "http://app-$NEW_COLOR:5000/status" || echo "FAIL")

if echo "$SMOKE_RESPONSE" | grep -q "\"deploy_color\":\"$NEW_COLOR\""; then
    echo "Smoke test reussi : $SMOKE_RESPONSE"
else
    echo "ERREUR : smoke test echoue. Reponse : $SMOKE_RESPONSE"
    echo "Abandon, la couleur active reste $ACTIVE_COLOR."
    docker compose -f "$COMPOSE_FILE" stop "app-$NEW_COLOR"
    exit 1
fi

# Bascule : on met a jour nginx pour pointer vers la nouvelle couleur
echo "Bascule de nginx vers $NEW_COLOR..."
TMP_FILE=$(mktemp)
sed "s/server app-$ACTIVE_COLOR:5000;/server app-$NEW_COLOR:5000;/" "$NGINX_CONF" > "$TMP_FILE"
cat "$TMP_FILE" > "$NGINX_CONF"
rm -f "$TMP_FILE"
docker compose -f "$COMPOSE_FILE" exec nginx nginx -s reload

# On confirme que le trafic passe bien par la nouvelle couleur avant d'arreter l'ancienne
sleep 1
FINAL_CHECK=$(curl -s http://localhost:8081/status)
if echo "$FINAL_CHECK" | grep -q "\"deploy_color\":\"$NEW_COLOR\""; then
    echo "Bascule confirmee : $FINAL_CHECK"
else
    echo "ERREUR : la bascule ne s'est pas propagee correctement."
    exit 1
fi

# Seulement maintenant, on arrete l'ancienne couleur
echo "Arret de l'ancienne couleur ($ACTIVE_COLOR)..."
docker compose -f "$COMPOSE_FILE" stop "app-$ACTIVE_COLOR"

# On enregistre le nouvel etat
echo "$NEW_COLOR" > "$STATE_FILE"

echo "Deploiement termine avec succes. Couleur active : $NEW_COLOR"
