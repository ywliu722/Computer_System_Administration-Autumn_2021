homepage(){
    selection=$(dialog --title "System Info Panel" --menu "Please select the command you want to use" 12 35 5 1 "POST ANNOUNCEMENT" 2 "USER LIST" 2>&1 > /dev/tty)
    result=$?
    if [ $result -eq 0 ]; then
        if [ $selection -eq 1 ]; then
            announcement
        elif [ $selection -eq 2 ]; then
            user
        fi
    elif [ $result -eq 1 ]; then
        clear
        echo "Exit."
        exit 0
    elif [ $result -eq 255 ]; then
        clear
        >&2 echo "Esc pressed."
        exit 1
    fi
}

announcement(){
    users=$(cat /etc/passwd | awk -F: '{if($3 == 0 || $3 == 66 || $3 > 1000 && $3 < 65534)print $3 " " $1 " off"}')
    selection=$(dialog --title "POST ANNOUNCEMENT" --extra-button --extra-label "ALL" --checklist "Please choose who you want to post" 12 35 5 $users 2>&1 > /dev/tty)
    result=$?

    if [ $result -eq 0 ]; then
        msg=$(dialog --title "Post an announcement" --inputbox "Enter your messages:" 10 50 2>&1 > /dev/tty)
        input_result=$?
        if [ $input_result -eq 0 ]; then
            pw group add id20
            echo "$selection" | xargs -I % -n1 pw groupmod id20 -m %
            echo "$msg" | wall -g id20
            pw group del id20
        elif [ $input_result -eq 255 ]; then
            clear
            >&2 echo "Esc pressed."
            exit 1
        fi
        homepage
    elif [ $result -eq 3 ]; then
        msg=$(dialog --title "Post an announcement" --inputbox "Enter your messages:" 10 50 2>&1 > /dev/tty)
        input_result=$?
        if [ $input_result -eq 0 ]; then
            echo "$msg" | wall
        elif [ $input_result -eq 255 ]; then
            clear
            >&2 echo "Esc pressed."
            exit 1
        fi
        homepage
    elif [ $result -eq 1 ]; then
        homepage
    elif [ $result -eq 255 ]; then
        clear
        >&2 echo "Esc pressed."
        exit 1
    fi
}


user(){
    cat /etc/passwd | awk -F: '{if($3 == 0 || $3 == 66 || $3 > 1000 && $3 < 65534)print $3 " " $1}' > user_list
    who | awk '{print "1 " $1}' >> user_list
    users=$(cat user_list | awk '{
        if($1 > 1000 || $1 == 66 || $1 == 0){uid[$2] = $1; user[$2]++;} else{user[$2]++;}}
        END{ for(key in user){if(user[key] == 1) print uid[key] " " key; else print uid[key] " " key "[*]";}}' | sort -n -k 1,1)
    userid=$(dialog  --ok-label "Select" --cancel-label "Exit" --menu "User Info Panel" 12 35 5 $users 2>&1 > /dev/tty)
    result=$?
    rm user_list

    if [ $result -eq 0 ]; then
        user_action $userid
    elif [ $result -eq 1 ]; then
        homepage
    elif [ $result -eq 255 ]; then
        clear
        >&2 echo "Esc pressed."
        exit 1
    fi
}

user_action(){
    if [ $1 -eq 0 ]; then
        username="root"
    else
        username=$(cat /etc/passwd | grep $1 | awk -F: '{print $1}')
    fi

    locked=$(pw usershow $username | awk '{if($0 ~ /\*LOCKED\*/){print "locked"} else{print "unlock"}}')
    if [ $locked == "locked" ]; then
        selection=$(dialog  --cancel-label "Exit" --menu "User $username" 12 35 5 1 "UNLOCK IT" 2 "GROUP INFO" 3 "PORT INFO" 4 "LOGIN HISTORY" 5 "SUDO LOG" 2>&1 > /dev/tty)
    elif [ $locked == "unlock" ]; then
        selection=$(dialog  --cancel-label "Exit" --menu "User $username" 12 35 5 1 "LOCK IT" 2 "GROUP INFO" 3 "PORT INFO" 4 "LOGIN HISTORY" 5 "SUDO LOG" 2>&1 > /dev/tty)
    fi
    select_result=$?

    if [ $select_result -eq 0 ]; then
        if [ $selection -eq 1 ]; then
            lock_it $1 $username
        elif [ $selection -eq 2 ]; then
            group_info $1 $username
        elif [ $selection -eq 3 ]; then
            port_info $1 $username
        elif [ $selection -eq 4 ]; then
            login_history $1 $username
        elif [ $selection -eq 5 ]; then
            sudo_log $1 $username
        fi
    elif [ $select_result -eq 1 ]; then
        user
    elif [ $select_result -eq 255 ]; then
        clear
        >&2 echo "Esc pressed."
        exit 1
    fi
}

lock_it(){
    locked=$(pw usershow $2 | awk '{if($0 ~ /\*LOCKED\*/){print "locked"} else{print "unlock"}}')
    if [ $locked == "unlock" ]; then
        selection=$(dialog --title "LOCK IT" --yesno "Are you sure you want to do this?" 10 50 2>&1 > /dev/tty)
        result=$?

        if [ $result -eq 0 ]; then
            pw lock $2
            lock_result=$(dialog --title "LOCK IT" --msgbox "LOCK SUCCEED!" 10 50 2>&1 > /dev/tty)
            msg_result=$?
            if [ $msg_result -eq 255 ]; then
                clear
                >&2 echo "Esc pressed."
                exit 1
            fi    
            user_action $1 $2
        elif [ $result -eq 1 ]; then
            user_action $1 $2
        elif [ $result -eq 255 ]; then
            clear
            >&2 echo "Esc pressed."
            exit 1
        fi
    elif [ $locked == "locked" ]; then
        selection=$(dialog --title "UNLOCK IT" --yesno "Are you sure you want to do this?" 10 50 2>&1 > /dev/tty)
        result=$?

        if [ $result -eq 0 ]; then
            pw unlock $2
            lock_result=$(dialog --title "UNLOCK IT" --msgbox "UNLOCK SUCCEED!" 10 50 2>&1 > /dev/tty)
            msg_result=$?
            if [ $msg_result -eq 255 ]; then
                clear
                >&2 echo "Esc pressed."
                exit 1
            fi    
            user_action $1 $2
        elif [ $result -eq 1 ]; then
            user_action $1 $2
        elif [ $result -eq 255 ]; then
            clear
            >&2 echo "Esc pressed."
            exit 1
        fi
    fi
}

group_info(){
    group_result=$(groups $2 | xargs -I % -n1 getent group % | awk -F: '{print $3 " " $1}' | sort -n -k 1,1 | awk '{if(NR == 1){print "\n" $0} else{print $0}}')
    selection=$(dialog --title "GROUP" --yes-label "OK" --no-label "EXPORT" --yesno "GROUP_ID GROUP_NAME $group_result" 21 80 2>&1 > /dev/tty)
    result=$?

    if [ $result -eq 0 ]; then
        user_action $1 $2
    elif [ $result -eq 1 ]; then
        output_path=$(dialog --title "Export to file" --inputbox "Enter the path:" 10 50 2>&1 > /dev/tty)
        input_result=$?
        if [ $input_result -eq 0 ]; then
            current_user=$(whoami)
            output_path_edit=$(echo "$output_path" | awk -v current_user="$current_user" '{
                if(/^[A-Za-z0-9]/){
                    if(current_user == "root"){
                        print "/root/" $0
                    }
                    else{
                        print "/home/" current_user "/" $0
                    }
                }
                else{
                    print $0
                }}')
            echo "GROUP_ID GROUP_NAME $group_result" > "$output_path_edit"
        elif [ $input_result -eq 255 ]; then
            clear
            >&2 echo "Esc pressed."
            exit 1
        fi
        group_info $1 $2
    elif [ $result -eq 255 ]; then
        clear
        >&2 echo "Esc pressed."
        exit 1
    fi
}

port_info(){
    ports=$(sockstat | grep $2 | egrep 'tcp4|udp4' | awk '{print $3 " " $5"_"$6}')
    processid=$(dialog --menu "Port INFO(PID and Port)" 21 60 5 $ports 2>&1 > /dev/tty)
    result=$?

    if [ $result -eq 0 ]; then
        port_stat $1 $2 $processid
    elif [ $result -eq 1 ]; then
        user_action $1 $2
    elif [ $result -eq 255 ]; then
        clear
        >&2 echo "Esc pressed."
        exit 1
    fi
}

port_stat(){
    info=$(ps -o user,pid,ppid,stat,%cpu,%mem,command $3 | awk '{if(NR != 1)print $0}' |
        awk '{command = $7;for(i=8;i<=NF;i++){command = command " " $i}
            print "USER " $1 "\nPID " $2 "\nPPID " $3 "\nSTAT " $4 "\n%CPU " $5 "\n%MEM " $6 "\nCOMMAND " command}')
    selection=$(dialog --title "PROCESS STATE: $3" --yes-label "OK" --no-label "EXPORT" --yesno "$info" 21 80 2>&1 > /dev/tty)
    select_result=$?

    if [ $select_result -eq 0 ]; then
        port_info $1 $2
    elif [ $select_result -eq 1 ]; then
        output_path=$(dialog --title "Export to file" --inputbox "Enter the path:" 10 50 2>&1 > /dev/tty)
        input_result=$?
        if [ $input_result -eq 0 ]; then
            current_user=$(whoami)
            output_path_edit=$(echo "$output_path" | awk -v current_user="$current_user" '{
                if(/^[A-Za-z0-9]/){
                    if(current_user == "root"){
                        print "/root/" $0
                    }
                    else{
                        print "/home/" current_user "/" $0
                    }
                }
                else{
                    print $0
                }}')
            echo "$info" > "$output_path_edit"
        elif [ $input_result -eq 255 ]; then
            clear
            >&2 echo "Esc pressed."
            exit 1
        fi
        port_stat $1 $2 $3
    elif [ $select_result -eq 255 ]; then
        clear
        >&2 echo "Esc pressed."
        exit 1
    fi
}

login_history(){
    history=$(last $2 | 
            awk 'BEGIN{count=0}{if(count<10){print $0; count++;}}' |
            awk -v user="$2" '{if($1 == user) print $0}' |
            awk '{if($3 ~ /[0-9]/){print $4 " " $5 " " $6 " " $7 " " $3} else{print $3 " " $4 " " $5 " " $6 " 127.0.0.1"}}' |
            awk '{if(NR == 1){print "\n" $0} else{print $0}}')
    selection=$(dialog --title "LOGIN HISTORY" --yes-label "OK" --no-label "EXPORT" --yesno "DATE IP $history" 21 80 2>&1 > /dev/tty)
    result=$?

    if [ $result -eq 0 ]; then
        user_action $1 $2
    elif [ $result -eq 1 ]; then
        output_path=$(dialog --title "Export to file" --inputbox "Enter the path:" 10 50 2>&1 > /dev/tty)
        input_result=$?
        if [ $input_result -eq 0 ]; then
            current_user=$(whoami)
            output_path_edit=$(echo "$output_path" | awk -v current_user="$current_user" '{
                if(/^[A-Za-z0-9]/){
                    if(current_user == "root"){
                        print "/root/" $0
                    }
                    else{
                        print "/home/" current_user "/" $0
                    }
                }
                else{
                    print $0
                }}')
            echo "DATE IP $history" > "$output_path_edit"
        elif [ $input_result -eq 255 ]; then
            clear
            >&2 echo "Esc pressed."
            exit 1
        fi
        login_history $1 $2
    elif [ $result -eq 255 ]; then
        clear
        >&2 echo "Esc pressed."
        exit 1
    fi
}

sudo_log(){
    days=$(date | awk 'BEGIN{days_passed["Jan"]=0; days_passed["Feb"]=31; days_passed["Mar"]=59; days_passed["Apr"]=90; days_passed["May"]=120; days_passed["Jun"]=151;
            days_passed["Jul"]=181; days_passed["Aug"]=212; days_passed["Sep"]=243; days_passed["Oct"]=273; days_passed["Nov"]=304; days_passed["Dec"]=334;} {print days_passed[$2]+$3}')
    sudo_logs=$(cat /var/log/auth.log | awk -v user="$2" '{if($6 == user) print $0}' |
    awk -v today="$days" '
        BEGIN{  days_passed["Jan"]=0;   days_passed["Feb"]=31;  days_passed["Mar"]=59;  days_passed["Apr"]=90; 
                days_passed["May"]=120; days_passed["Jun"]=151; days_passed["Jul"]=181; days_passed["Aug"]=212; 
                days_passed["Sep"]=243; days_passed["Oct"]=273; days_passed["Nov"]=304; days_passed["Dec"]=334;}
        {if(days_passed[$1] + $2 - today <= 30){print($0)}}' |
    awk '{if($0 ~ /repeated/){for(i=1;i<=$9;i++){print f}} else{f=$0;print $0}}'|
    awk '/sudo/{
            if($0 ~ /COMMAND/){
                for (i=1;i<=NF;i++){
                    if ($i ~ /COMMAND=/){
                        command = $i;
                        for (j=i+1;j<=NF;j++){
                            command = command " " $j;
                        }
                    }
                }print "sudo " $1 " " $2 " " $3 " " $6 " " command
            }}' | awk -F "COMMAND=" '/sudo/{print $1 $2}' |
    awk '{  if($0 ~ /sudo/){
                command="";
                for(i=6;i<=NF;i++){
                    if(i==6){
                        command=command $i
                    }
                    else{
                        command=command " " $i
                    }
                }
                print $5 " used sudo to do " command " on " $2 " " $3 " " $4}}')
    
    selection=$(dialog --title "SUDO LOG" --yes-label "OK" --no-label "EXPORT" --yesno "$sudo_logs" 21 80 2>&1 > /dev/tty)
    result=$?

    if [ $result -eq 0 ]; then
        user_action $1 $2
    elif [ $result -eq 1 ]; then
        output_path=$(dialog --title "Export to file" --inputbox "Enter the path:" 10 50 2>&1 > /dev/tty)
        input_result=$?
        if [ $input_result -eq 0 ]; then
            current_user=$(whoami)
            output_path_edit=$(echo "$output_path" | awk -v current_user="$current_user" '{
                if(/^[A-Za-z0-9]/){
                    if(current_user == "root"){
                        print "/root/" $0
                    }
                    else{
                        print "/home/" current_user "/" $0
                    }
                }
                else{
                    print $0
                }}')
            echo "$sudo_logs" > "$output_path_edit"
        elif [ $input_result -eq 255 ]; then
            clear
            >&2 echo "Esc pressed."
            exit 1
        fi
        sudo_log $1 $2
    elif [ $result -eq 255 ]; then
        clear
        >&2 echo "Esc pressed."
        exit 1
    fi
}

trap "clear; echo Ctrl + C pressed.; exit 2" 2
homepage