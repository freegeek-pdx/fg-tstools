#!/bin/bash

# user functions

test_for_root(){
	if [[ $EUID -ne 0 ]]; then
		return 1
	else
		return 0
	fi
}

check_file_write(){
        file=$1
        touch $file 2>/dev/null
        return $?
}

choose_username(){
	cat /etc/passwd| while read line ; do
		local user=$(echo $line | awk -F : '{print $1}')
		local user_list
		if [[ $user_uid -gt 999 ]] ; then
                        # unless user is a nobody :)
                        if [[ ! $user == "nobody" ]]; then
        			user_list="$user_list $user"
			fi
		fi
	done	
	PS3="Select a user "
        select user_name in $user_list; do
                break
        done
echo $user_name
}

test_for_uid(){
	local my_user=$1
	local my_uid=$(id -u $my_user)
	echo $my_uid
}

test_for_user(){
	local my_user=$1
	id $my_user &>/dev/null
	return $?
}

# password functions
reset_password(){
        local username=$1
        local passhash="$2"
        usermod --password "$passhash" $username
	return $?
}

expire_password(){
	local username=$1
        passwd -e $username
        return $?
}

backup_passwords(){
	local isotime=$(date +%Y%m%d%H%M)
	for file in passwd group shadow ; do
		if ! cp /etc/$file /etc/$file.fregeek_ts_backup.$isotime;then
			local failarray=( ${failarray[@]-} $(echo "$file") )
		fi
	done
	# check length of failarray if >0 then something failed
         if [[ ${#fail_array[@]} -ne 0 ]]; then
                echo -n "could not backup"
                for name in ${failarray[@]}; do
                        echo -n "/etc/$name"
                done
                return 3
	else
	echo "password files backed up with extension .fregeek_ts_backup.$isotime"
        exit 0
	fi
}

backup_passwords_for_reset(){
        for file in passwd group shadow ; do
                if ! cp /etc/$file /etc/$file.fregeek_ts_bak;then
                        local failarray=( ${failarray[@]-} $(echo "$file") )
                fi
        done
        # check length of failarray if >0 then something failed
         if [[ ${#fail_array[@]} -ne 0 ]]; then
                echo -n "could not backup"
                for name in ${failarray[@]}; do
                        echo -n "/etc/$name"
                done
                return 3
	else
		echo "backed up password files to [file].ts_bak"
		return 0
        fi
}
# gconf related
reset_gconf(){
	# checks to see if we are changing our own or somebody elses settings
	# --direct option can only be used if gconfd is not running as that 
	# users session
	local my_user=$1
        local my_uid=$(id -u $my_user)
	local setting=$2
	# test to see if self change and if gconfd-2 is running
	if [[ $my_uid -eq $EUID ]] && [[  $(pidof gconfd-2) ]]; then
        	gconftool-2 --recursive-unset $setting
	else
        	gconftool-2 --direct --config-source=xml::/home/$my_user/.gconf --recursive-unset $setting
	fi
	return $?
}


# write to error log and/or standard out 
write_msg(){
local msg="$1"
if [[ $2 ]]; then
        local logfile=$2
fi
echo "$msg"
if [[ $logfile ]]; then
        if ! echo "$msg" >>$logfile; then
        echo "Could not write to Log File: $logfile"
        exit 3
        fi
fi
return 0
}

