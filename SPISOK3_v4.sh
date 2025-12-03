#!/bin/bash
clear

LOGINS_FILE=logins.txt


LiST_FILE=list.txt




function add_bitwarden {
				    # Экспортируем GTOPS для использования в дочернем скрипте
					if [ -n "$GTOPS" ]; then
						export GTOPS=$GTOPS
					fi

						export FILE_GTOPS_csv=$FILE_GTOPS_csv
						export FILE_GTOPS_txt=$FILE_GTOPS_txt
				bash bitwarden_api/passwd_bitwarden_on_file.sh
				}

function enter_email {
                 read -p "Email:" email 
                }

function gen_pass {
#	chars=$(tr -dc A-Za-z0-9$%^\?\/.\+\#\_\ < /dev/urandom | head -c 20)
        chars=$(tr -dc A-Za-z0-9%^\?\/.\\\+\#_ < /dev/urandom | head -c 20)
        #Вывод сгенерированного пароля
        #echo "$chars"
        new_date=$(date -d "+60 days" +%Y%m%d%H%M%SZ)
}

get_users(){
	#line
	username=$(echo "$line" | awk -F ' ' '{print $5}' | awk -F '@' '{print $1}')
        # echo "$username"
        email=$(echo "$line" | awk -F ' ' '{print $5}')
        # echo "$email"
        first=$(echo "$line" | awk -F ' ' '{print $2 " " $3}')
        # echo "$first"
        last=$(echo "$line" | awk -F ' ' '{print $1}' | cut -d ' ' -f1 | sed 's/[[:space:]]//g' )
         echo "$last"
        phone=$(echo "$line" | awk -F ' ' '{print $4}')
         #echo "$phone"

}



function reset_pass {
    #read -p "Enter GTOPS (e.g., GTOPS-48154): " GTOPS
	#Определение набора символов
	chars=$(tr -dc A-Za-z0-9%^.\+\?\_\/ < /dev/urandom | head -c 20)
	#Вывод сгенерированного пароля
	#echo "$chars"
	new_date=$(date -d "+60 days" +%Y%m%d%H%M%SZ)
	echo "$new_date"
 	echo "echo $chars | ipa user-mod $username --password"
 	echo "echo $chars | ipa user-mod $username --password" >>FREEIPA_commands.txt
	echo "ipa user-mod $username --password-expiration $new_date"
	echo "ipa user-mod $username --password-expiration $new_date" >>FREEIPA_commands.txt
	echo "ipa user-mod $username --add pager=$GTOPS"
	echo "ipa user-mod $username --add pager=$GTOPS">>FREEIPA_commands.txt
	#запишем в файл
	mkdir -p "./GTOPS"
	echo "$last $first $email $phone " >>"./GTOPS/$GTOPS.txt"
	echo "$last;$first;$email;$phone;$username;$chars" >>"./GTOPS/$GTOPS.csv"
	echo "$username / $chars" >>"./GTOPS/$GTOPS.txt"
	echo "-----" >> "./GTOPS/$GTOPS.txt"
	echo "------------------------------------------"

}

get_logins_forchange_pass (){
    echo "Найденные logins:"
	while IFS= read -r line
	 do
	 username=$line
	 echo "$username"
    done < $LOGINS_FILE
    GTOPS_file="/tmp/GTOPS"
    read -p "Enter GTOPS (e.g., $(cat $GTOPS_file)): " GTOPS
    GTOPS=${GTOPS:-"$(cat $GTOPS_file)"}
    echo $GTOPS
    echo "$GTOPS" > "/tmp/GTOPS"
    #echo "$(cat $GTOPS_file)" > /tmp/GTOPS
    mkdir -p "./GTOPS/"
    echo "" > "FREEIPA_commands.txt"
    echo "$GTOPS" > "./GTOPS/$GTOPS.txt"
    echo "Пользователи (пароли и логины)" >> "./GTOPS/$GTOPS.txt"
    echo "last;first;email;phone;username;pass" > "./GTOPS/$GTOPS.csv"
    while IFS= read -r line
	do
	 username=$line
	 echo "user: $username"
	 reset_pass

	 done < $LOGINS_FILE
	#cat ./GTOPS/$GTOPS.txt

    echo "-------------------------------------------------------"
    FILE_GTOPS_txt="./GTOPS/$GTOPS.txt"
    FILE_GTOPS_csv="./GTOPS/$GTOPS.csv"
    cat $FILE_GTOPS_txt
    echo "-------------------------------------------------------"

	echo "------------------------------------------"
	#line
	read -p "Добавим запись в bitwarden:(Y/N)" add_bitwar
		if [[ "$add_bitwar" == "Y" || "$add_bitwarss" == "y" ]]; then
			add_bitwarden

		else
			echo
		fi

}

GET_USERS_FROM_LIST () {

	while IFS= read -r line
	 do
	 username=$line
	 #echo "$username"
    done < $LOGINS_FILE
}


ADD_TO_GROUPS () {
while IFS= read -r groups
        do
        group=$groups
		echo -e "\033[0;31mДобавим в $groups\033[m"

        	while IFS= read -r line
			do
				username=$line
				echo "ipa group-add-member $groups --users=$username"
			done < $LOGINS_FILE

done < groups.txt
}



BLOCK_USER () {
			read -p "Enter GTOPS (e.g., GTOPS-48154): " GTOPS
        	while IFS= read -r line
			do
				username=$line
				echo "ipa user-mod $username --add pager=$GTOPS"
				echo "ipa user-del $username --preserve"
			done < $LOGINS_FILE
}



function add_ipa_members {


# 1. Input File and Validation
input_file="list.txt"
if [ ! -f "$input_file" ]; then
  echo "Error: Input file '$input_file' not found."
  exit 1
fi

# 2. Extract Emails and Logins (improved regex)
email=$(cat $input_file | grep -oE '[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,6}')
login=$(cat $input_file | grep -oE '[a-zA-Z0-9._-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,6}' | awk -F '@' '{print $1}')
# Print emails and logins separately
echo "---------------------------"
echo -e "\033[0;33mНайденные_Emails:\033[0m"
printf "%s\n" "$email"
echo ""  # Add a blank line for better readability
echo -e  "\033[0;33mНайденные Logins----:\033[m"
printf "%s\n" "$login"
echo "" # Add a blank line for better readability
echo "---------------------------"

# 3. Get GTOPS and Orgunit
# Чтение переменной GTOPS от пользователя

GTOPS_file="/tmp/GTOPS"
  if [[ -f "$GTOPS_file" ]]; then
  read -r GTOPS < "$GTOPS_file"
    echo "Старый GTOPS: $GTOPS. Оставляем?"
  read -p "Y/N: " otvet
     if [[ "$otvet" == "Y" || "$otvet" == "y" ]]; then
     #Если ответ "Y", ничего не делаем, просто продолжаем
     echo "Оставляем orgunit: $GTOPS"
  else
     read -p "Enter GTOPS (e.g., GTOPS-48154): " GTOPS
      # Установка переменной GTOPS по умолчанию, если она пустая
	if [ -z "$GTOPS" ]; then
	GTOPS="GTOPS-555"

	fi
	echo "$GTOPS" > "$GTOPS_file"
   fi

else
     read -p "Enter GTOPS (e.g., GTOPS-48154): " GTOPS
      # Установка переменной GTOPS по умолчанию, если она пустая
	if [ -z "$GTOPS" ]; then
	GTOPS="GTOPS-555"
	fi
	echo "$GTOPS" > "$GTOPS_file"
fi
echo "GTOPS: $GTOPS"
export GTOPS


orgunit_file="/tmp/orgunit.txt"

# Проверка наличия файла orgunit 
if [[ -f "$orgunit_file" ]]; then
  # Чтение первой строки из файла 
  read -r orgunit < "$orgunit_file"
  echo "Старый orgunit: $orgunit. Оставляем?"
  read -p "Y/N: " otvet
  if [[ "$otvet" == "Y" || "$otvet" == "y" ]]; then
    # Если ответ "Y", ничего не делаем, просто продолжаем
    echo "Оставляем orgunit: $orgunit"
  else
    # Запрос orgunit от пользователя в случае отрицательного ответа
    read -p "Enter orgunit (e.g., Datamart): " orgunit
    # Установка переменной orgunit по умолчанию, если она пустая
    if [ -z "$orgunit" ]; then
      orgunit="orgunit"
      echo "$orgunit" > "$orgunit_file"
    else
      echo "$orgunit" > "$orgunit_file"  # Сохраним введенное значение в файл
    fi
  fi
else
  # Запрос orgunit от пользователя, если файл не существует
  read -p "Enter orgunit (e.g., Datamart): " orgunit
  # Установка переменной orgunit по умолчанию, если она пустая
  if [ -z "$orgunit" ]; then
    orgunit="orgunit"
  fi
  echo "$orgunit" > "$orgunit_file"  # Сохраним введенное значение в файл
fi

# Вывод значения orgunit
echo "Final orgunit: $orgunit"
mkdir -p "./GTOPS"
# 4. Create GTOPS file
echo "$GTOPS" > "./GTOPS/$GTOPS.txt"
cat "./GTOPS/$GTOPS.txt"
echo "Пользователи (пароли и логины)" >> "./GTOPS/$GTOPS.txt"
echo "-------------------------------------" >> "./GTOPS/$GTOPS.txt"
echo "Logins / Pass" >> "./GTOPS/$GTOPS.txt"
printf "%s\n" ""  "$logins" >> "./GTOPS/$GTOPS.txt"
echo "---------------------------"

#5 Создадим GTOPS 
echo "$GTOPS" > "./GTOPS/$GTOPS.csv"
echo "last;first;email;phone;username;pass" >> "./GTOPS/$GTOPS.csv"




echo -e  "\033[0;33mПоищем в IPA:\033[m"




while IFS= read -r line 
	do
	get_users
	echo "ipa user-find $last "
	echo "ipa user-show  $username  --all | grep --color=auto -e 'Учётная запись отключена:' -e 'Account disabled:' -e 'Номер пейджера' -e 'Pager Number' -e 'Email address:' -e 'User login:' -e 'Full name:'"
	done < list.txt


echo "---------------------------"
echo -e  "\033[0;33mСоздадим пользователей:\033[m"

while IFS= read -r line 
        do
	get_users
	echo "ipa user-add $username --first='$first' --last='$last' --email='$email' --phone='$phone' --pager='$GTOPS' --orgunit='$orgunit'"
done < list.txt

echo "---------------------------"
echo -e  "\033[0;33mСменим пароль:\033[m"
################################ ЗАПИСЬ В TXT/CSV #####################################

while IFS= read -r line 
        do
	get_users
        #Определение набора символов
	chars=$(tr -dc A-Za-z0-9%^.\+\?\_\/ < /dev/urandom | head -c 20)
	#Вывод сгенерированного пароля
	#echo "$chars"
	new_date=$(date -d "+60 days" +%Y%m%d%H%M%SZ)
	echo "$new_date"
 	echo "echo '$chars' | ipa user-mod $username --password"
	echo "ipa user-mod $username --password-expiration $new_date"
	echo "ipa user-mod $username --add pager=$GTOPS" 
	#запишем в файл
	echo "$last $first $email $phone " >>"./GTOPS/$GTOPS.txt"
	echo "$last;$first;$email;$phone;$username;$chars" >>"./GTOPS/$GTOPS.csv"
	echo "$username / $chars" >>"./GTOPS/$GTOPS.txt"
	echo "-----" >> "./GTOPS/$GTOPS.txt" 
done < list.txt



echo "---------------------------"
    FILE_GTOPS_txt="./GTOPS/$GTOPS.txt"
    FILE_GTOPS_csv="./GTOPS/$GTOPS.csv"
cat "./GTOPS/$GTOPS.txt"


echo "---------------------------"
echo -e  "\033[0;33mДобавм в группу:\033[m"
echo -e "\033[0;36mСписок групп\033[m:"
while IFS= read -r line 
        do
        echo "$line"
done < groups.txt
echo -e "Добавляем?"
read -p "Y/N: " otvet_g
  if [[ "$otvet_g" == "Y" || "$otvet_g" == "y" ]]; then
    # Если ответ "Y", ничего не делаем, просто продолжаем
    echo "Добавляем........"
	while IFS= read -r line_group 
        do
        echo -e  "\033[0;31mДобавим в $line_group\033[m"
	        while IFS= read -r line 
	        do
        	 username=$(echo "$line" | awk -F ' ' '{print $5}' | awk -F '@' '{print $1}')
       		 echo "ipa group-add-member $line_group  --users=$username"
        	done < list.txt
        done < groups.txt


  else

	read -p "Enter group: " group
	while IFS= read -r line 
        do
         username=$(echo "$line" | awk -F ' ' '{print $5}' | awk -F '@' '{print $1}')
        echo "ipa group-add-member $group  --users=$username"
	done < list.txt
fi
echo "---------------------------"
echo -e  "\033[0;33mДобавим ЕЩЕ группу:\033[m"
read -p "Enter group: " group_TUZ
if [ -z "$group_TUZ" ]; then
  group_TUZ="service-accounts-client"
fi


while IFS= read -r line 
        do
         username=$(echo "$line" | awk -F ' ' '{print $5}' | awk -F '@' '{print $1}')
        echo "ipa group-add-member $group_TUZ  --users=$username"
done < list.txt
# Добавим в Битварден

read -p "Добавим запись в bitwarden:(Y/N)" add_bitwar
 if [[ "$add_bitwar" == "Y" || "$add_bitwarss" == "y" ]]; then
	add_bitwarden 

 else
	echo
 fi

}



###############################################################################################
function add_one_user {
    # Определяем переменные
    local LiST_FILE="list.txt"
    
    echo "Возьмем из list.txt(ОСТАВИТЬ ОДНОГО В СПИСКЕ!!!!)?"
    read -p "Y/N: " otvet_g
    
    if [[ "$otvet_g" == "N" || "$otvet_g" == "n" ]]; then
        # Ручной ввод пользователя
        read -p "username:" username
        username=${username:-username}
        read -p "Имя Отчество:" first
        first=${first:-"test testov"}
        first=$(echo $first| awk  '{$1=$1};1')
        read -p "Фамилия:" last
        last=${last:-"lastname"}
        
        # Функция для ввода email
        function enter_email {
            read -p "Email:" email
        }
        enter_email
        if [[ -z $email ]]; then
            email=${email:-"test@test.ru"}
        fi
        
        EMAIL_REGEX="^[a-zA-Z0-9._-]+@[a-zA-Z0-9._-]+\.[a-zA-Z0-9._-]+$"
        while true; do
            echo $email
            if [[ $email =~ $EMAIL_REGEX ]]; then
                echo 'норм'
                break
            else
                echo "Плохой email, попробуйте снова."
                enter_email
            fi
        done

        read -p "телефон:" phone
        phone=${phone:-"+777777777"}
        
    else
        # Взятие из файла list.txt
        if [ ! -f "$LiST_FILE" ]; then
            echo "ОШИБКА: Файл $LiST_FILE не существует"
            exit 1
        fi
        
        line_count=$(wc -l < "$LiST_FILE")
        if [ "$line_count" -eq 0 ]; then
            echo "ОШИБКА: Файл $LiST_FILE пустой"
            exit 1
        fi
        
        if [ "$line_count" -gt 1 ]; then
            echo "ОШИБКА: В $LiST_FILE больше одной строки ($line_count строк)"
            exit 1
        fi
        
        # Читаем строку из файла
        line=$(head -n1 "$LiST_FILE" | awk '{$1=$1};1')
        
        if [ -z "$line" ]; then
            echo "ОШИБКА: Строка в файле пустая"
            exit 1
        fi
        
        # Анализируем строку для определения формата данных
        if [[ $line =~ @ ]]; then
            # Формат с email - предполагаем полный формат: "ФИО телефон email"
            last=$(echo "$line" | awk '{print $1}')
            first=$(echo "$line" | awk '{print $2 " " $3}')
            phone=$(echo "$line" | awk '{print $4}')
            email=$(echo "$line" | awk '{print $5}')
            username=$(echo "$email" | cut -d'@' -f1)
        else
            # Простой формат - только логин
            username=$(echo "$line" | tr -d '[:space:]')
            first="test testov"
            last="$username"
            email="test@test.ru"
            phone="+777777777"
        fi
        
        echo "Прочитано из файла:"
        echo "Username: $username"
        echo "ФИО: $last $first" 
        echo "Email: $email"
        echo "Телефон: $phone"
    fi
    
    export USERNAME_SPISOK=$username


    echo
	echo
    # Остальная часть кода...
    GTOPS_file="/tmp/GTOPS"
    read -p "Enter GTOPS (e.g., $(cat $GTOPS_file 2>/dev/null || echo 'GTOPS-555')): " GTOPS
    GTOPS=${GTOPS:-"$(cat $GTOPS_file 2>/dev/null || echo 'GTOPS-555')"}
    echo $GTOPS
    echo "$GTOPS" > "/tmp/GTOPS"

    GTOPS=${GTOPS:-"GTOPS-555"}
    mkdir -p "./GTOPS"
    echo "$GTOPS" > "./GTOPS/$GTOPS.txt"
    echo "last;first;email;phone;username;pass" > "./GTOPS/$GTOPS.csv"
    echo "Пользователи (Логины и пароли)" >> "./GTOPS/$GTOPS.txt"
    
    echo -e "$username\n $first\n $last\n $email\n $phone\n $GTOPS\n"
    
    echo -e  "\033[0;33mПоищем в IPA:\033[m"
    echo "ipa user-find $last "
    echo "ipa user-find $username "

    read -p "Выбери Регион(PD20,PD21,PD40,PD43,PD46(можно через ,)): " PDreg_input
    # Преобразуем строку в массив
        IFS=',' read -ra PDreg <<< "$PDreg_input"

    for PD in "${PDreg[@]}"; do
        echo -e  "\033[0;35mСоздадим в IPA $PD:\033[m"
        echo "ipa user-add $username --first='$first' --last='$last' --email='$email' --phone='$phone' --pager='$GTOPS'"

        echo -e  "\033[0;33mСмена пароля IPA:\033[m"
        gen_pass  # предполагается, что эта функция определена где-то еще
        echo "echo '$chars' | ipa user-mod $username --password"
        echo "ipa user-mod $username --password-expiration $new_date"
        echo "ipa user-mod $username --add pager=$GTOPS"
        
        echo -e  "\033[0;33mДобавим в группу IPA(groups.txt):\033[m"
        while IFS= read -r group
        do
            echo "ipa group-add-member $group --users=$username"
        done < groups.txt

        echo "$PD" >> "./GTOPS/$GTOPS.txt"
        echo "$PD" >> "./GTOPS/$GTOPS.csv"
		echo "$last $first $email $phone " >>"./GTOPS/$GTOPS.txt"
        echo "$username / $chars" >> "./GTOPS/$GTOPS.txt"
        echo "$last;$first;$email;$phone;$username;$chars" >> "./GTOPS/$GTOPS.csv"
    done 
    
    echo "-------------------------------------------------------"
    FILE_GTOPS_txt="./GTOPS/$GTOPS.txt"
    FILE_GTOPS_csv="./GTOPS/$GTOPS.csv"
    cat $FILE_GTOPS_txt
    echo "-------------------------------------------------------"
    
	
	read -p "Добавим запись в bitwarden:(Y/N)" add_bitwar
		if [[ "$add_bitwar" == "Y" || "$add_bitwarss" == "y" ]]; then
			add_bitwarden 

		else
			echo
		fi

		

}
###############################################################################################
#Меню для создания пользователей№ подставляем фунции#
echo -e  "\033[0;31mМЕНЮ создания пользователей:\033[m"

PS3="Выбери действие:"  

items=("Один пользователь"
        "Много (берет из list.txt)"
        "Сбросить пароль (берет из logins.txt)"
        "Добавить в группу (берет из logins.txt и groups.txt)"
        "Блокировать пользователей (берет из logins.txt)"
		"Добавить запись в Bitwarden(экспериментально)"
		"Поискать запись в Bitwarden(экспериментально)")


while true; do
    select item in "${items[@]}" Quit
    do
        case $REPLY in
            1) echo -e "\033[0;34mВыбрано #$REPLY which means $item\033[m"; 
                echo "введи username";
                add_one_user;  break;;
            2) echo -e "\033[0;34mSelected item #$REPLY which means $item\033[m";
                echo "едем дальше..... ";
		add_ipa_members; break;;
			3) echo -e "\033[0;34mSelected item #$REPLY which means $item\033[m";
                echo "едем дальше..... ";
		get_logins_forchange_pass; break;;
			4) echo -e "\033[0;34mSelected item #$REPLY which means $item\033[m";
                echo "едем дальше..... ";
		ADD_TO_GROUPS; break;;
			5) echo -e "\033[0;34mSelected item #$REPLY which means $item\033[m";
                echo "едем дальше..... ";
		BLOCK_USER; break;;
			6) echo -e "\033[0;34mSelected item #$REPLY which means $item\033[m";
                echo "едем дальше..... ";
		add_bitwarden; break;;
			7) echo -e "\033[0;34mSelected item #$REPLY which means $item\033[m";
                echo "едем дальше..... ";
				cd bitwarden_api
				bash search_from_bw.sh;
				cd ..
				break;;
            $((${#items[@]}+1))) echo "We're done!"; break 2;;
            *) echo "Ooops - unknown choice $REPLY"; break;
        esac
   
 done
done 






echo "---------------------------"
echo -e  "\033[0;31mМЕНЮ УСЛУГ:\033[m"



PS3="Выбери услугу:"

items=("Выдать доступы по Услугам 1.1, 1.3, 1.10 (Pangolin, Ignite, Kafka)"
	"Выдать доступы по Услугам 1.2, 1.7 (Фабрика Данных)"
	"Выдать доступы по Услуге 1.4 (Open Search)"
	"Выдать доступы по Услуге 1.13(IAM)"
	"Выдать доступы по Услугам 1.14, 1.15,1.16(ЖАМ)"
        "Выдать доступы по Услуге 1.12 (Сервисы ДВП, ЕФС, ППРБ)")

while true; do
    select item in "${items[@]}" Quit
    do
        case $REPLY in
            1) echo -e "\033[0;34mВыбрано #$REPLY which means $item\033[m"; 
	        echo "1.1 - Присвоение прав администратора ГИС в pangolin \n"
		echo "1.3 - Предоставление доступа к Platform V Datagrid (Ignite), оно же права Администратор ГИС \n"
		echo "1.10 - Предоставление доступа к Platform V Corax (Kafka)";
		  break;;
            2) echo "\033[0;34mSelected item #$REPLY which means $item\033[m";
		echo "Логин и Пароль для доступа к Услуге взять из коллекции Bitwarden в Excel файле для конкретного Пользователя. ";  break;;
            3) echo "\033[0;34mSelected item #$REPLY which means $item\033[m";
		echo "Логин и Пароль для доступа к Услуге взять из коллекции Bitwarden в Excel файле для конкретного Пользователя. "; break;;
	    4) echo "Сервис IAM --- IPA Добавляем в группу CustumerAuth L3";break;;
	    5) echo "ЖАМ ---- PA  группа osdb";break;;
	    6) echo "\n См. инструкцию:  https://works-tools.v-serv.ru/wiki/pages/viewpage.action?pageId=105220584 \n";break;;
            $((${#items[@]}+1))) echo "We're done!"; break 2;;
            *) echo "Ooops - unknown choice $REPLY"; break;
        esac
   
 done
done



