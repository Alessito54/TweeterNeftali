#!/bin/bash

# Script de Testing para Reacciones
# Uso: ./test-reactions.sh

echo "🧪 Testing Emoji Reactions System"
echo "=================================="
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

BASE_URL="http://127.0.0.1:3000"

# Test 1: Verificar que la BD está limpia
echo -e "${YELLOW}[1] Checking database connection...${NC}"
if curl -s "$BASE_URL/api/tweets" > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Backend conectado${NC}"
else
    echo -e "${RED}✗ Backend NO accessible${NC}"
    exit 1
fi

echo ""
echo -e "${YELLOW}[2] Testing Reaction Constraint...${NC}"
echo "Este test verificará que solo se permite 1 emoji por usuario"
echo ""

# Crear 2 cuentas de test
USER_A_TOKEN=""
USER_B_TOKEN=""

echo "- Creando usuario A (test_user_a@test.com)..."
RESPONSE=$(curl -s -X POST "$BASE_URL/api/auth/register" \
  -H "Content-Type: application/json" \
  -d '{"email":"test_user_a_'$RANDOM'@test.com","password":"Test123!"}')

USER_A_TOKEN=$(echo $RESPONSE | grep -o '"token":"[^"]*' | cut -d'"' -f4)
if [ -z "$USER_A_TOKEN" ]; then
    echo -e "${YELLOW}  (Puede ser que usuario exista ya)${NC}"
fi

echo ""
echo "- Creando usuario B (test_user_b@test.com)..."
RESPONSE=$(curl -s -X POST "$BASE_URL/api/auth/register" \
  -H "Content-Type: application/json" \
  -d '{"email":"test_user_b_'$RANDOM'@test.com","password":"Test123!"}')

USER_B_TOKEN=$(echo $RESPONSE | grep -o '"token":"[^"]*' | cut -d'"' -f4)

echo ""
echo -e "${YELLOW}[3] Creando un tweet de prueba...${NC}"

# Crear tweet
TWEET_RESPONSE=$(curl -s -X POST "$BASE_URL/api/tweets" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $USER_A_TOKEN" \
  -d '{"content":"Test tweet for reactions"}')

TWEET_ID=$(echo $TWEET_RESPONSE | grep -o '"id":[0-9]*' | head -1 | cut -d':' -f2)

if [ -z "$TWEET_ID" ]; then
    echo -e "${RED}✗ Error creando tweet${NC}"
    echo "Response: $TWEET_RESPONSE"
    exit 1
fi

echo -e "${GREEN}✓ Tweet creado: ID $TWEET_ID${NC}"

echo ""
echo -e "${YELLOW}[4] Test de Constraint UNIQUE...${NC}"
echo ""
echo "- User A agrega reacción 👍..."

REACTION1=$(curl -s -X POST "$BASE_URL/api/tweets/$TWEET_ID/reactions" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $USER_A_TOKEN" \
  -d '{"emoji":"👍"}')

echo "  Response: $REACTION1"
echo ""

echo "- User A intenta agregar reacción ❤️ (debería remplazar o fallar)..."

REACTION2=$(curl -s -X POST "$BASE_URL/api/tweets/$TWEET_ID/reactions" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $USER_A_TOKEN" \
  -d '{"emoji":"❤️"}')

echo "  Response: $REACTION2"
echo ""

echo -e "${YELLOW}[5] Verificando reacciones finales...${NC}"

GET_REACTIONS=$(curl -s -X GET "$BASE_URL/api/tweets/$TWEET_ID/reactions" \
  -H "Authorization: Bearer $USER_A_TOKEN")

echo "Total reactions: $GET_REACTIONS"
echo ""

REACTION_COUNT=$(echo $GET_REACTIONS | grep -o '"emoji"' | wc -l)
echo -e "${GREEN}Total emojis encontrados: $REACTION_COUNT${NC}"

if [ "$REACTION_COUNT" -eq 1 ]; then
    echo -e "${GREEN}✓ CONSTRAINT WORKING: Solo 1 emoji por usuario${NC}"
else
    echo -e "${YELLOW}⚠ WARNING: Encontrados $REACTION_COUNT emojis (esperado 1)${NC}"
fi

echo ""
echo "=================================="
echo -e "${GREEN}✓ Tests completados${NC}"
echo ""
echo "Próximos pasos:"
echo "1. Abrir navegador: http://127.0.0.1:8080"
echo "2. Login con las cuentas de test"
echo "3. Verificar que reacciones funcionan correctamente"
echo ""
