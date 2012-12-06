#!/bin/bash
#functions for ts_network_backup
#split out for convinience
check_for_backup_dir(){
	local backupuser=$1
	local backuphost=$2
	local backuppath=$3
	local backupdir=$4
	# success if finds backupdir
	if ssh $backupuser@$backuphost ls $backuppath/$backupdir &> /dev/null; then
		return 0
	else
		return 1
	fi
}


backup_users_test(){
	# check we can write to the backup files
        declare -a failarray
        for file in $@; do
                 if [[ $(check_file_write "${file}") -ne 0 ]]; then
                        # if we cant write to file add to array         
                        failarray=( ${failarray[@]-} $(echo "$file") ) 
	fi
        done
        # check length of failarray if >0 then something failed
        if [[ ${#failarray[@]} -ne 0 ]]; then
                echo -n "error writing to "
                for name in ${failarray[@]}; do
                        echo -n "$name"
                done
                return 3
        else
		echo "proceeding to backup users..."
		return 0
	fi
}

get_groups(){
        local user=$1
        local extpath=$2
        local group
        local groups
        for group in $(grep $user ${extpath}/etc/group | awk -F: '{print $1}'); do
                if [[ $group != $user ]]; then
                        groups="${groups},${group}" 
                fi  
        done 
        echo "$groups"
} 

backup_users(){
        local path=$1
	local extpath=$2
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
                                #echo "$user: $(id $user)" >>"${path}/group"
                                echo "$user: $(get_groups $user)" >>"${path}/group"
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
                                grep -e ^$user: $extpath/etc/shadow >>"${path}/shadow"
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
        done < $extpath/etc/passwd
	if [[ $userlist ]]; then
		echo "Backed up passwords for $userlist"
	fi
	if [[ $fail_list ]]; then
		echo "Failed to backup passwords for $fail_list"
		return 3
	else
		return 0
	fi
}
delete_user(){
        local user=$1 
        local gid=$2
        local extpath=$3
	#N.B. users may not be in file
	# delete matching lines in /etc/passwd 
        sed -i "/^$user:/ d" $extpath/etc/passwd
	# delete existing encypted password 
	sed -i "/^$user:/ d" $extpath/etc/shadow
	# delete matching lines/existing groups
	sed -i "/:$gid:/ d" $extpath/etc/group 
}

restore_user(){
        local path=$1        
	local user=$2
	local uid=$3
	local gid=$4
	local password=$5
	local extpath=$6
	if [[ $extpath ]]; then
        	local chroot_path="chroot $extpath"
	fi


	#N.B. users may not be in file
	# delete matching lines in /etc/passwd etc
	delete_user $user $gid $extpath
        
        if ! $chroot_path addgroup --gid $gid $user; then
       		echo "problem creating ${user}'s group"
		return 3
 	elif ! $chroot_path useradd -N --gid $gid --uid $uid -d /home/$user --password $password --shell /bin/bash $user; then
		echo "problem creating user: $user"
		return 3
	else
                # read /home/group usermod to addusers to groups        
                #local groups=$(grep -e "\<$user\>" $path/group | cut -f1 -d: -)
                # line above printed only 1st field , we wanted all but 1st
                local usergroups=$(grep -e "\<$user\>" mygroup | cut -f2- -d: -)

#               superfluous: get_groups produces correctly formatted entry
#                 	for entry in $groups; do
#                         	if [[ $entry != $user ]]; then
#                                 	if [[ ! $usergroups ]]; then
#                                         	usergroups=$entry
# 	                                else
#         	                                usergroups="$usergroups,$entry"
#                 	                fi
# 	                        fi
# 	                done
                if [[ ${#usergroups} -ne 0 ]] ; then
                        if ! $chroot_path usermod -a -G "$usergroups" $user; then
                                echo "problem adding ${user}'s groups"
                                return 3
                        fi
                fi
		return 0
	fi
}

restore_users(){
	local path=$1
	local extpath=$2
        # note that copying files back across is not sufficient 
        # need to extract values from files and added to new copies
	for file in passwd group shadow; do
		check_file_read "$path/$file"
		local retval=$?	
		if [[ $retval -ne 0 ]] ; then
				if (( $retval == 5 )); then
					echo "$path/$file does not exist!" 
				elif (( $retval == 4 )); then
					echo "Can not read $path/$file!"
				fi
				local break_value=1
		fi
	done
	# checks if value is set
		if declare -p break_value &> /dev/null; then
			echo "This backup may have been created with the -d option, if so rerun with -d"
			return 2
		fi
        # read /home/password file or equivalent)
        while read line ; do
                local user=$(echo $line | awk -F : '{print $1}')
                local uid=$(echo $line | awk -F : '{print $3}')
                local gid=$(echo $line | awk -F : '{print $4}')
		local password=$(grep -m 1 $user $path/shadow | awk -F: '{print $2}')
		# trying to restore a user with UID =1000 causes issues
                # if they are not oem. So delete oem first.
                if [[ $uid -eq 1000 && $user != "oem" ]]; then
                       delete_user oem 1000 $extpath
                fi

                if ! user_restore=$(restore_user $path $user $uid $gid $password $extpath); then
			echo "$user_restore"
			return 3
		fi
	done < ${path}/passwd
	return 0
}

backup_other_sources(){
	local sourcespath=$1
	local extpath=$2
	if [ $extpath]; then  
		path=$extpath/etc/apt/sources.list.d
	else
		path=/etc/apt/sources.list.d/
	fi
	if [[ -d $path ]]; then
		if ! mkdir -p $sourcespath/sources.list.d; then
			 echo "Couldn't make $sourcespath/sources.list.d"
			 return 3
		fi
		if [[ $(ls -A $path) ]]; then
			for file in $path/* ; do
				filename=$(echo $file | awk -F/ '{ print $NF }')
				if [[ -L $file ]]; then
					realfile=$(readlink -f $file)
				else
					realfile=$file
				fi		
				if ! cp $realfile $sourcespath/sources.list.d/$filename; then
					echo "Couldn't copy $file to $sourcespath"
					local returnval=3
				fi 
			done
		else
			echo "$path is empty. This is a warning only." 
			echo "The backup will proceed as normal" 
		fi
	else
		echo "$path does not exist. This is a warning only." 
		echo "The backup will proceed as normal"	
	fi
	if [[ $returnval ]]; then
		return $returnval
	else
		return 0
	fi
}

backup_sources(){
	local sourcespath=$1
	local path=$2
	local extpath=$3
	if ! mkdir -p $sourcespath; then
		echo "Couldn't make $sourcespath"
		return 3
	elif ! check_file_write $sourcespath ; then
		echo "Couldn't write to $sourcespath Check permissions?" 
		return 3
	elif ! backup_other_sources $sourcespath $extpath  ; then
		echo "Problem copying over /etc/apt/sources.list.d"
        	return 3
	elif ! cp  $extpath/etc/apt/sources.list $sourcespath  ; then
                echo "Problem copying over /etc/apt/sources.list"
                return 3
	else
		echo "Backed up software sources"
		return 0
        fi
}


restore_multiverse(){
	local dist_version=$1
	local extpath=$2
	if ! local tmpfile=$(mktemp); then
		echo "Couldn't make temp file"
		return 3
	fi

	while read line; do
		if [[ $line =~ ^# ]]; then
			echo $line >>$tmpfile
		elif [[ $line =~ main && ! $line =~ freegeek ]] ; then
			echo "# $line" >> $tmpfile
			if [[ $line =~ $dist_version  ]]; then
				if [[ ! $line =~ multiverse ]]; then
					echo "$line multiverse" >>$tmpfile
				else
					echo "$line" >>$tmpfile
				fi
			else
				old_version=$(echo $line | awk '{print $3}' | awk -F- '{print $1}')
				newline=$(echo line | sed "s/$old_version/$dist_version/")
				if [[ ! $newline =~ multiverse ]]; then
					echo "$newline multiverse" >>$tmpfile
				else 
					echo "$newline" >>$tmpfile
				fi	
			fi
		else
			echo $line >>$tmpfile  
		fi 
	done < $extpath/etc/apt/sources.list
	
	if ! cp $tmpfile $extpath/etc/apt/sources.list; then
		echo "could not overwrite /etc/apt/sources.list, new version stored at $tmpfile"
		return 3
	else 
		rm $tmpfile
		return 0
	fi
}

restore_partners(){
	local dist_version=$1
	local extpath=$2
	if ! echo "deb http://archive.canonical.com/ubuntu $dist_version partner" >>$extpath/etc/apt/sources.list; then
		echo "could not add partners to /etc/apt/sources.list"
		return 3
	else 
		echo "deb-src http://archive.canonical.com/ubuntu $dist_version partner" >>$extpath/etc/apt/sources.list
		return 0
	fi 
}

####

backup_apt(){
	local dpkgfile=$1
	local extpath=$2
        if [[ $extpath ]]; then
        	local aptdir="--admindir=${extpath}/var/lib/dpkg"
	fi
	dpkg --get-selections $aptdir > $dpkgfile  
        return $?
}


restore_packages(){
        local dpkgfile=$1
	local extpath=$2
        
	check_file_read "$dpkgfile"
        local retval=$?
        if [[ $retval -ne 0 ]] ; then
		if (( $retval == 5 )); then
			echo "$dpkgfile does not exist!" 
		elif (( $retval == 4 )); then
			echo "Can not read $dpkgfile!"
		fi
        	exit 3       
	fi

	if [[ $extpath ]] ; then
		local chroot_path="chroot $extpath"
	fi
	if ! local update_msg=$($chroot_path apt-get update); then
		echo "apt-get update failed while attempting to restore packages"
		echo "$update_msg"
		return 3
        elif ! local dpkg_msg=$($chroot_path dpkg --set-selections < $dpkgfile  2>&1);then
                echo "Could not set package selection when attempting to restore packages"	
		echo "$dpkg_msg"
		return 3
        elif ! local upgrade_mdg=$($chroot_path apt-get -y -u dselect-upgrade   2>&1); then
		echo "apt-get -u dselect-upgrade  while attempting to restore packages"
		echo "$upgrade_msg"
	else
		echo "Restored software packages successfully"
		return 0
	fi
}

backup_config(){
	local path=$1
	local extpath=$2
        tar -czf ${path}/etc_backup.tar.gz $extpath/etc/  2>&1
        return $?
}

create_backup(){
        local cpath=$1
	local user=$2
	local host=$3
	local bpath=$4
	local bdir="$5"
        rsync --rsync-path="sudo rsync" -azh --exclude=".gvfs" "${cpath}" "${user}@${host}:${bpath}/${bdir}" 2>&1
	return $?	
}

restore_backup(){
        local user=$1
        local host=$2
        local spath=$3
        local backupdir=$4
        local rpath=$5
                rsync --rsync-path="sudo rsync" -azh --exclude=".gvfs" "${user}@${host}:${spath}/${backupdir}/" "${rpath}/"
	return $?
	
}
