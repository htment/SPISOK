        #!/bin/bash

        [ $# -ne 1 ] && { echo "Использование: $0 <файл_с_командами>"; exit 1; }
        [ ! -f "$1" ] && { echo "Файл '$1' не найден"; exit 1; }

        success=0
        fail=0
	echo "Список сфейлиных команд" > FAIL_command.txt
        while IFS= read -r cmd; do
            [ -z "$cmd" ] && continue

            echo "Выполняем: $cmd"
            if eval "$cmd"; then
                echo "✓ УСПЕХ"
                ((success++))
            else
		echo "$cmd --FAIL" >> FAIL_command.txt
                echo "✗ НЕУСПЕХ"
                ((fail++))
            fi
            echo "---"
        done < "$1"

        echo "Итого: успешно $success, неуспешно $fail"
        exit $((fail > 0))
