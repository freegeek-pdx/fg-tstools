#!/bin/bash
#functions for ts_network_backup
#split out for convinience
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
        else
		return 0
	fi
}

backup_users(){
        local path=$1
	local user
	local user_uid
	local userlist
	local fail
	local fail_list
        while read line ; do
                user=$(echo $line | awk -F : '{print $1}')
                user_uid=$(echo $line | awk -F : '{print $3}')
                # if UID >999 then is normal (non-system) user
                if [[ $user_uid -gt 999 ]] ; then
                        # unless user is a nobody :)
                        if [[ ! $user == "nobody" ]]; then
                                # gets lists of groups user belongs to
                                echo "$user: $(id $user)" >>"${path}/group"
				if (( $? != 0 )); then
					fail="${fail} ${path}/group "
				fi
                                echo $line >>${path}/passwd
				if (( $? != 0 )); then
                                        fail="${fail} ${path}/passwd "
                                fi

                                # /etc/shadow contains the date of last password
                                # change. Having this be older than the install
                                # should not be a problem, but noting just in case
                                grep -e ^$user: /etc/shadow >>"${path}/shadow"
				if (( $? != 0 )); then
                                        fail="${fail} ${path}/shadow "
                                fi
				if [[ $fail ]]; then 
					for file in $fail; do
						fail_list="${failist}\n${user}:${file}"
					done
				else
                                	userlist="$userlist $user"
				fi
                        fi
                fi
        done < /etc/passwd
	if [[ $userlist ]]; then
		echo "backed up passwords for $userlist"
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
 	elif ! useradd -N --gid $gid --uid $uid -d /home/$user --password $password $user; then
		echo "problem creating user: $user"
		return 3
	else
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
				return 3
 				fi
			fi
		return 0
	fi
}

restore_users(){
	local $path=$1
        # note that copying files back across is not sufficient 
        # need to extract values from files and added to new copies
	for file in passwd group shadow; do
		if ! check_file_read "$path/$file"; then
			local retval=$?
			if (( $retval == 5 )); then
				echo "$path/$file does not exist!" 
			elif (( $retval == 4 )); then
				echo "Can not read $path/$file!"
			fi
			return $retval
		fi
	done
        # read /home/password file or equivalent)
        while read line ; do
                user=$(echo $line | awk -F : '{print $1}')
                uid=$(echo $line | awk -F : '{print $3}')
                gid=$(echo $line | awk -F : '{print $4}')
		password=$(grep $user /$password/shadow | awk -F: '{print $2}')
		if ! user_restore=$(restore_user $path $user $uid $gid $password); then
			echo "$user_restore"
			return 3
		fi
	done < ${path/passwd}
	return 0
}


backup_sources(){
	local $sourcespath=$1
	if ! mkdir $sourcespath/; then
		echo "Couldn't make $sourcespath"
		return 3
	elif ! check_file_write $sourcespath/apt ; then
		echo "Couldn't write to $sourcespath/apt Check permissions?" 
		return 3
	elif ! cp -R /etc/apt/sources.list.d/ $sourcespath/apt/  ; then
		echo "Problem copying over /etc/apt/sourceslist.d"
        	return 3
	elif ! cp  /etc/apt/sources.list $sourcespath/apt/  ; then
                echo "Problem copying over /etc/apt/sources.list"
                return 3
	else
		echo "Backed up software sources"
		return 0
        fi
}


restore_multiverse(){
	local dist_version=$1
	
	if ! local tmpfile=$(mktemp); then
		echo "Couldn't make temp file"
		return 3
	fi

	while read line; do
		if [[ $line =~ ^# ]]; then
			echo $line >>$tmpfile
		elif [[ $line =~ main ]] ; then
			echo "# $line" >> $tmpfile
			if [[ $line =~ $dist_version ]]; then
				echo "$line multiverse" >>$tmpfile
			else
				old_version=$(echo $line | awk '{print $3}' | awk -F- '{print $1}')
				newline=$(echo line | sed "s/$old_version/$dist_version/")
				echo "$newline multiverse" >>$tmpfile	
			fi
		else
			echo $line >>$tmpfile  
		fi 
	done < /etc/apt/sources.list
	
	if ! cp $tmpfile /etc/apt/sources.list; then
		echo "could not overwrite /etc/apt/sources.list, new version stored at $tmpfile"
		return 3
	else 
		rm $tmpfile
		return 0
	fi
}

restore_partners(){
	local dist_version=$1
	if ! echo "deb http://archive.canonical.com/ubuntu $dist_version partner" >>/etc/apt/sources.list; then
		echo "could not add partners to /etc/apt/sources.list"
		return 3
	else 
		echo "deb-src http://archive.canonical.com/ubuntu $dist_version partner" >>/etc/apt/sources.list
		return 0
	fi 
}

####

backup_apt(){
	local $dpkgfile=$1
        dpkg --get-selections > $dpkgfile   2>&1
        return $?
}


restore_packages(){
        local $dpkgfile=$1
	                if ! check_file_read "$dpkgfile"; then
                        local retval=$?
                        if (( $retval == 5 )); then
                                echo "$dpkgfile does not exist!" 
                        elif (( $retval == 4 )); then
                                echo "Can not read $dpkgfile!"
                        fi
                        return $retval
                fi

	if ! local update_msg=$(apt-get update); then
		echo "apt-get update failed while attempting to restore packages"
		echo "$update_msg"
		return 3
        elif ! local dpkg_msg=$(dpkg --set-selections < $dpkgfile  2>&1);then
                echo "Could not set package selection when attempting to restore packages"	
		echo "$dpkg_msg"
		return 3
        elif ! local upgrade_mdg=$(apt-get -u dselect-upgrade   2>&1); then
		echo "apt-get -u dselect-upgrade  while attempting to restore packages"
		echo "$upgrade_msg"
	else
		echo "Restored software packages successfully"
		return 0
	fi
}

backup_config(){
	local bpath=$1
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
