#!/bin/bash
set -e

########## НАСТРОЙКИ ##########

# Полный путь к бинарнику bw
# Если bw лежит рядом со скриптом, можешь написать: BW="$(dirname "$0")/bw"
BW="$(dirname "$0")/bw"

# ID организации 003
#ORG_ID="54fce57c-1e00-473c-b199-c6a3a2796d9e"
ORG_ID="eb7400fe-22db-460f-8d1d-3a6d1ce11b48"

######## КОНЕЦ НАСТРОЕК #######

# Проверяем, что bw существует
if [ ! -x "$BW" ]; then
  echo "Ошибка: не найден исполняемый файл bw по пути: $BW"
  echo "Проверь, что он существует и что у него есть права на запуск (chmod +x)."
  exit 1
fi

# Проверка сессии
if [ -z "$BW_SESSION" ]; then
  echo "Ошибка: переменная BW_SESSION не установлена."
  echo "Сначала выполни вручную:"
  echo "  export BW_SESSION=\$($BW unlock --raw)"
  exit 1
fi

# Проверка валидности сессии

echo "Проверяю валидность сессии..."
# Проверяем статус сессии вместо list items
if ! $BW status --session "$BW_SESSION" 2>/dev/null | grep -q '"status":"unlocked"'; then
  echo "Сессия невалидна. Нужно разблокировать заново."
  echo "Выполни: export BW_SESSION=\$($BW unlock --raw)"
  exit 1
fi
echo "Сессия валидна."


echo "=== Bitwarden CLI без jq ==="
echo
#echo $GTOPS
#source ./SPISOK3_v4.sh
read -p "Введите НАЗВАНИЕ коллекции($GTOPS): " COLLECTION_NAME
    if [ -z "$COLLECTION_NAME" ]; then
        COLLECTION_NAME=$GTOPS
    fi
read -p "Введите НАЗВАНИЕ элемента(Пользователи и пароли): " ITEM_NAME
    if [ -z "$ITEM_NAME" ]; then
        ITEM_NAME="Пользователи и пароли"
    fi
read -p "Введите ПУТЬ к файлу с заметкой: " NOTES_FILE
    if [ -z "$NOTES_FILE" ]; then
        NOTES_FILE=$FILE_GTOPS_txt
        #NOTES_FILE=passwd.txt
    fi
if [ ! -f "$NOTES_FILE" ]; then
  echo "Ошибка: файл '$NOTES_FILE' не найден"
 # exit 1
fi

# Читаем файл и экранируем для JSON:
#  - \  -> \\
#  - "  -> \"
#  - перевод строки -> \n

if [ -z "$NOTES_FILE" ]; then
    ITEM_NOTES="."
    #continue
else
    ITEM_NOTES=$(sed ':a;N;$!ba;s/\\/\\\\/g;s/"/\\"/g;s/\n/\\n/g' "$NOTES_FILE")
fi
echo
echo "Проверяю существование коллекции \"$COLLECTION_NAME\"..."

# Ищем коллекцию
COLLECTION_ID=$($BW list collections --organizationid "$ORG_ID" --session "$BW_SESSION" \
  | grep -A3 "\"name\": \"$COLLECTION_NAME\"" \
  | grep '"id":' \
  | head -1 \
  | sed 's/.*"id": "\(.*\)".*/\1/')

if [ -z "$COLLECTION_ID" ]; then
  echo "Коллекция не найдена. Создаю..."

  COLLECTION_JSON=$(cat <<EOF
{
  "organizationId": "$ORG_ID",
  "name": "$COLLECTION_NAME",
  "groups": [],
  "users": []
}
EOF
)

  COLLECTION_ID=$(echo "$COLLECTION_JSON" \
    | "$BW" encode \
    | "$BW" create org-collection --organizationid "$ORG_ID" --session "$BW_SESSION" \
    | sed 's/.*"id":"\([^"]*\)".*/\1/')

  if [ -z "$COLLECTION_ID" ]; then
    echo "Ошибка: не удалось получить ID коллекции."
    exit 1
  fi

  echo "Создана коллекция с ID: $COLLECTION_ID"
else
  echo "Коллекция уже существует. ID: $COLLECTION_ID"
fi

echo
echo "Создаю элемент \"$ITEM_NAME\"..."

ITEM_JSON=$(cat <<EOF
{
  "organizationId": "$ORG_ID",
  "type": 2,
  "name": "$ITEM_NAME",
  "notes": "$ITEM_NOTES",
  "collectionIds": ["$COLLECTION_ID"],
  "secureNote": { "type": 0 }
}
EOF
)

# Создаём элемент и сохраняем ID
ITEM_ID=$(echo "$ITEM_JSON" | "$BW" encode | "$BW" create item --session "$BW_SESSION" | sed 's/.*"id":"\([^"]*\)".*/\1/')

if [ -z "$ITEM_ID" ]; then
  echo "Ошибка: не удалось создать элемент."
  exit 1
fi

echo "Элемент создан с ID: $ITEM_ID"

# --- добавляем вложение ---
read -p "Введите ПУТЬ к файлу для вложения (или Enter чтобы пропустить): " ATTACH_FILE

if [ -z "$ATTACH_FILE" ]; then
  # Если путь пустой, спрашиваем про файл $NOTES_FILE
  if [ -f "$FILE_GTOPS_csv" ]; then
    read -p "Файл '$FILE_GTOPS_csv' найден. Использовать его как вложение? (y/N): " USE_NOTES
    if [[ "$USE_NOTES" =~ ^[Yy]$ ]]; then
      ATTACH_FILE="$FILE_GTOPS_csv"
      echo "Выбран файл: $ATTACH_FILE"
    else
      echo "Вложение не добавлено."
      ATTACH_FILE=""
    fi
  else
    echo "Файл '$FILE_GTOPS_csv' не найден. Вложение не добавлено."
    ATTACH_FILE=""
  fi
fi

if [ -n "$ATTACH_FILE" ]; then
  if [ -f "$ATTACH_FILE" ]; then
    "$BW" create attachment --itemid "$ITEM_ID" --file "$ATTACH_FILE" --session "$BW_SESSION" > /dev/null
    echo "Файл '$ATTACH_FILE' прикреплён как вложение."
  else
    echo "Файл '$ATTACH_FILE' не найден. Вложение не добавлено."
  fi
fi

echo "Готово! Элемент \"$ITEM_NAME\" добавлен в коллекцию \"$COLLECTION_NAME\"."
cd bitwarden_api
SERVER=$(./bw config server)
echo
LINK="$SERVER/#/vault?collectionId=$COLLECTION_ID&itemId=$ITEM_ID"
echo $LINK
cd ..
echo
echo



