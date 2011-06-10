#!/bin/bash
#functions for ts_network_backup
#split our for convinience
backup_users_test(){
        groupfile=$1
        passwordfile=$2
        shadowfile=$3
                # check we can wrtite to the backup files
        declare -a failarray
        for file in "$group_file" "$password_file" "$shadow_file"; do
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
        local groupfile=$1
        local password/file=$2
        local shadowfile=$3
        cat /etc/passwd| while read line ; do
                user=$(echo $line | awk -F : '{print $1}')
                user_uid=$(echo $line | awk -F : '{print $3}')
                # if UID >999 then is normal (non-system) user
                if [[ $user_uid -gt 999 ]] ; then
                        # unless user is a nobody :)
                        if [[ ! $user == "nobody" ]]; then
                                # gets lists of groups user belongs to
                                echo "$user: $(id $user)" >>$groupfile
				if (( $? != 0 )); then
					local fail="${fail} ${groupfile} "
				fi
                                echo $line >>$passwordfile
				if (( $? != 0 )); then
                                        local fail="${fail} ${passwordfile} "
                                fi

                                # /etc/shadow contains the date of last password
                                # change. Having this be older than the install
                                # should not be a problem, but noting just in case
                                grep -e ^$user: /etc/shadow >>$shadowfile
				if (( $? != 0 )); then
                                        local fail="${fail} ${shadowfile} "
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
fi        return $?
if [[ $fail_list ]]]; then
	echo "$fail_list"
	return 3
else
	return 0
fi
}


restore_users(){
	local $passwordfile=$1
        # note that copying files back across is not sufficient 
        # need to extract values form files and added to new copies

        # read /home/password file or equivalent)
        cat $password_file| while read line ; do
                user=$(echo $line | awk -F : '{print $1}')
                uid=$(echo $line | awk -F : '{print $3}')
                gid=$(echo $line | awk -F : '{print $4}')

                # delete matchinf lines in /etc/passwd 
                sed -i '/^$user:/ d' /etc/passwd
                # delete existing encypted password 
                sed -i '/^$user:/ d' /etc/shadow
                # delete matching lines/existing groups
                sed -i '/:$gid:/ d' /etc/group

                #copy relevant lines to /etc/passwd& shadow 
                if ! echo $line >> /etc/passwd; then
			local $faillist="$failist \nproblem adding $user to /etc/password"
		fi
                
		if ! grep -e '/^$user:/' home/shadow >> /etc/shadows; then
			local $faillist="$failist \nproblem adding $user to /etc/shadow"
		fi

                # create group for  user
                if ! addgroup --gid $gid $user; then
			local $faillist="$failist \nproblem creating ${user}'s group"
                fi


                # read /home/group usermod to addusers to groups        
                local groups=$(grep -e "\<$user\>" $group_file | cut -f1 -d: -)
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
                        usermod -a -G "$usergroups" $user
                fi
        done
}

backup_sources(){
	local $sources_file=$1
        cp /etc/apt/sources.list $sources_file 2>&1
        return $?
}
### TODO ###
restore_sources(){
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
