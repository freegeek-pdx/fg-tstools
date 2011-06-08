# user functions

test_for_root(){
	if [[ $EUID -ne 0 ]]; then
		echo 1
	else
		echo 0
	fi
}

check_file_write(){
        file=$1

        if ! touch $file; then
                exit=$?
        else
                exit=0
        fi

        echo $exit
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
	my_uid=$(id -u)
	echo $my_uid
}

test_for_user(){
	my_user=$1
	id $my_user
	echo $?
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
	for file in passwd group shadow ; do
		if ! cp /etc/$file /etc/$file.fregeek_ts_backup.isotime;then
			failarray=( ${failarray[@]-} $(echo "$file") )
		fi
	done
	# check length of failarray if >0 then something failed
         if [[ ${#fail_array[@]} -ne 0 ]]; then
                echo -n "could not backup"
                for name in ${failarray[@]}; do
                        echo -n "/etc/$name"
                done
                return 2
        fi
}


## gconf related
set_gconf(){
	# checks to see if we are changing our own or somebody elses settings
	# --direct option can only be used if gconfd is not running as that 
	# users session
	my_user=$1
        my_uid=$(grep $my_user /etc/passwd | awk -F: '{print $3}')
	# test to see if self change and if gconfd-2 is running
	if [[ $my_uid -eq $EUID ]] && [[  $(pidof gconfd-2) ]]; then
        	echo "gconftool-2 --recursive-unset"
	else
        	echo "gconftool-2 --direct --config-source=xml::/home/$my_user/.gconf --recursive-unset"
	fi
}



