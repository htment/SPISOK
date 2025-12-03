#!/bin/bash
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

./bw sync



read -p "ВВЕДИ имя коллекции: " COLLECTION_NAME
if [ -z "$COLLECTION_NAME" ]; then
    COLLECTION_NAME="GTOPS-555"
fi

echo "=== Поиск коллекций $COLLECTION_NAME ==="
COLLECTIONS_JSON=$(./bw list collections --search "$COLLECTION_NAME")
echo "$COLLECTIONS_JSON"
echo "$COLLECTIONS_JSON" | jq

read -p "ВВЕДИ ID коллекции: " COLLECTION_ID
if [ -z "$COLLECTION_ID" ]; then
    # Автоматически берем первый ID коллекции
    COLLECTION_ID=$(echo "$COLLECTIONS_JSON" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
fi
if [ -z "$COLLECTION_ID" ]; then
    echo "Коллекция не найдена!"
    exit 1
fi

echo ""
echo "=== Элементы коллекции $COLLECTION_ID ==="
ITEMS_JSON=$(./bw list items --collectionid $COLLECTION_ID)
echo "$ITEMS_JSON"
echo "$ITEMS_JSON" | jq
ITEMS_JSON_pretty=$(./bw list items --collectionid $COLLECTION_ID --pretty)
echo "$ITEMS_JSON_pretty" 
# Получаем ITEM_ID из сырых данных
ITEM_ID=$(echo "$ITEMS_JSON" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)

echo ""
echo "=== ОСНОВНАЯ ИНФОРМАЦИЯ ==="

# Парсим основные поля
NAME=$(echo "$ITEMS_JSON" | grep -o '"name":"[^"]*"' | head -1 | cut -d'"' -f4)
NOTES=$(echo "$ITEMS_JSON" | grep -o '"notes":"[^"]*"' | head -1 | cut -d'"' -f4)
CREATION_DATE=$(echo "$ITEMS_JSON" | grep -o '"creationDate":"[^"]*"' | head -1 | cut -d'"' -f4)
FILE_NAME=$(echo "$ITEMS_JSON" | grep -o '"fileName":"[^"]*"' | head -1 | cut -d'"' -f4)

echo "Название: $NAME"
echo "ID элемента: $ITEM_ID"
echo "Создано: $CREATION_DATE"

if [ -n "$NOTES" ]; then
    echo "Заметки:"
    echo "$NOTES" | sed 's/\\n/\n/g'
fi

if [ -n "$FILE_NAME" ]; then
    echo "Файл: $FILE_NAME"
fi

SERVER=$(./bw config server)
echo
echo "Ссылка на элемент: $SERVER/#/vault?collectionId=$COLLECTION_ID&itemId=$ITEM_ID"
