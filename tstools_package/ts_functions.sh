# user functions

test_for_root(){
	if [[ $EUID -ne 0 ]]; then
		echo 1
	else
		echo 0
	fi
}


choose_username(){
        declare -a user_list
        for file in /home/*; do
                if [[ -d $file ]]; then
                        name=$(echo $file | awk -F/ '{print $3}')
                        user_list=$user_list" $name"
                fi
        done

        PS3="Select a user "
        select user_name in $user_list; do
                break
        done
echo $user_name
}

test_for_uid(){
	my_user=$1
	my_uid=$(grep $my_user /etc/passwd | awk -F: '{print $3}')
	echo $my_uid
}

# password functions
reset_password(){
        username=$1
        if ! usermod --password zyrSQxJlOIQTo $username; then
                EXIT=2
	else 
		EXIT=0 
        fi
	echo $EXIT
}

expire_password(){
        if ! passwd -e $user; then
                EXIT=1
	else
		EXIT=0
        fi
	echo $EXIT
}

backup_passwords(){
        # backup password files
        if ! cp /etc/passwd /etc/passwd.ts_bak; then
                echo "WARNING: backup for  /etc/passwd could not be created"
                echo "Are you root?"
                echo "user's password not changed"
                exit 2
        fi

        if ! cp /etc/shadow /etc/shadow.ts_bak; then
                echo "WARNING: backup for  /etc/shadow could not be created"
                echo "Are you root?"
                echo "user passwords not changed"
                exit 2
        fi

        if ! cp /etc/gropu /etc/group.ts_bak; then
                echo "WARNING: backup for  /etc/group could not be created"
                echo "Are you root?"
                echo "user passwords not changed"
                exit 2
        fi

}


