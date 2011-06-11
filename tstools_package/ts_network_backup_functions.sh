#!/bin/bash
#functions for ts_network_backup
#split our for convinience
backup_users_test(){
        local path=$1        
	# check we can wrtite to the backup files
        declare -a failarray
        for file in "${path}/group" "${path}/passwd" "${path}/shadow"; do
                if [[ $(check_file_write "${file}") -ne 0 ]]; then
                        # if we cant write to file add to array         
                        failarray=( ${failarray[@]-} $(echo "$file") )                          fi
        done
        # check length of failarray if >0 then something failed
        if [[ ${#failarray[@]} -ne 0 ]]; then
                echo -n "error writing to "
                for name in ${failarray[@]}; do
                        echo -n "$name"
                done
                return 3
        fi
        return 0
}

backup_users(){
        local path=$1
        cat /etc/passwd| while read line ; do
                user=$(echo $line | awk -F : '{print $1}')
                user_uid=$(echo $line | awk -F : '{print $3}')
                # if UID >999 then is normal (non-system) user
                if [[ $user_uid -gt 999 ]] ; then
                        # unless user is a nobody :)
                        if [[ ! $user == "nobody" ]]; then
                                # gets lists of groups user belongs to
                                echo "$user: $(id $user)" >>"${path}/group"
				if (( $? != 0 )); then
					local fail="${fail} ${groupfile} "
				fi
                                echo $line >>${path}/passwd
				if (( $? != 0 )); then
                                        local fail="${fail} ${path}/passwd "
                                fi

                                # /etc/shadow contains the date of last password
                                # change. Having this be older than the install
                                # should not be a problem, but noting just in case
                                grep -e ^$user: /etc/shadow >>"${path}/shadow"
				if (( $? != 0 )); then
                                        local fail="${fail} ${path}/shadow "
                                fi
				if [[ $fail ]]; then 
					for file in $fail; do
						local fail_list="${failist}\n${user}:${file}"
					done
				else
                                	local userlist="$userlist $user"
				fi
                        fi
                fi
        done
	if [[ $userlist ]]; then
		echo "backed up passwords for $userlist"
		return $?
	fi
	if [[ $fail_list ]]; then
		echo "$fail_list"
		return 3
	else
		return 0
	fi
}

restore_user(){
        local path=$1        
	local user=$2
	local uid=$3
	local gid=$4
	local password=$5

	#N.B. users may not be in file
	# delete matching lines in /etc/passwd 
        sed -i '/^$user:/ d' /etc/passwd
	# delete existing encypted password 
	sed -i '/^$user:/ d' /etc/shadow
	# delete matching lines/existing groups
	sed -i '/:$gid:/ d' /etc/group

	if ! addgroup --gid $gid $user; then
       		echo "problem creating ${user}'s group"
		return 3
	fi
 	if ! useradd -N --gid $gid --uid $uid -d /home/$user --password $password $user; then
		echo "problem creating user: $user"
		return 3
	fi
        # read /home/group usermod to addusers to groups        
	local groups=$(grep -e "\<$user\>" $path/group | cut -f1 -d: -)
                for entry in $groups; do
                        if [[ $entry != $user ]]; then
                                if [[ ! $usergroups ]]; then
                                        usergroups=$entry
                                else
                                        usergroups="$entry,$usergroups"
                                fi
                        fi
                done
	if [[ ${#usergroups} -ne 0 ]] ; then
		if ! usermod -a -G "$usergroups" $user; then
			echo "problem adding ${user}'s groups"
                fi
	fi
}

restore_users(){
	local $path=$1
        # note that copying files back across is not sufficient 
        # need to extract values form files and added to new copies

        # read /home/password file or equivalent)
        cat "${path/passwd}" | while read line ; do
                user=$(echo $line | awk -F : '{print $1}')
                uid=$(echo $line | awk -F : '{print $3}')
                gid=$(echo $line | awk -F : '{print $4}')
		password=$(grep $user /$password/shadow | awk -F: '{print $2}')
		if ! user_restore=$(restore_user $path $user $uid $gid $password); then
			echo "$user_restore"
			return $3
		fi
	done
}


backup_sources(){
	local $sourcespath=$1
	if ! mkdir $sourcespath/; then
		echo "Couldn't make $sourcespath"
		return 3
	fi
	if ! check_file_write $sourcespath/apt ; then
		echo "Couldn't write to $sourcespath/apt Check permissions?" 
		return 3
	fi	

        if ! cp -R /etc/apt/sources.list.d/ $sourcespath/apt/  ; then
		echo "problem copying over /etc/apt/sourceslist.d"
        	return 3
	fi
}
### TODO ###
restore_sources(){
}restore_partners(){
}

backup_apt(){
        dpkg --get-selections > $dpkg_file   2>&1
        return $?
}

restore_apt(){
        dpkg --set-selections < $dpkg_file  2>&1
        return $?
}

restore_packages(){
        apt-get -u dselect-upgrade   2>&1
        return $?
}

backup_config(){
        tar -czf ${path}/etc_backup.tar.gz /etc/  2>&1
        return $?
}

create_backup(){
        local cpath=$1
	local user=$2
	local host=$3
	local bpath=$4
	local ticket="$5-$(date +%Y%m%d)"
        rsync -azh $cpath "${user}@${host}:${bpath}/${ticket}" 2>&1
	return $?	
}

restore_backup(){
        local user=$1
        local host=$2
        local spath=$3
        local backupdir=$4
        local rpath=$5
                rsync -azh "${user}@${host}:${spath}/${backupdir}/" "$rpath/"
	return $?
	
}
###TODO####
restore_multiverse(){
}
restore_partners(){
}
