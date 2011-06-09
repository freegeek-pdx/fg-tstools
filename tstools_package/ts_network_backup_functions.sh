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
        groupfile=$1
        passwordfile=$2
        shadowfile=$3
        cat /etc/passwd| while read line ; do
                user=$(echo $line | awk -F : '{print $1}')
                user_uid=$(echo $line | awk -F : '{print $3}')
                # if UID >999 then is normal (non-system) user
                if [[ $user_uid -gt 999 ]] ; then
                        # unless user is a nobody :)
                        if [[ ! $user == "nobody" ]]; then
                                # gets lists of groups user belongs to
                                echo "$user: $(id $user)" >>$groupfile
                                echo $line >>$passwordfile
                                # /etc/shadow contains the date of last password
                                # change. Having this be older than the install
                                # should not be a problem, but noting just in case
                                grep -e ^$user: /etc/shadow >>$shadowfile
                                userlist="$userlist $user"
                        fi
                fi
        done
echo "backed up passwords for $userlist"
}


restore_users(){
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
                echo $line >> /etc/passwd
                grep -e '/^$user:/' home/shadow >> /etc/shadow
                # create group for  user
                addgroup --gid $gid $user

                # read /home/group usermod to addusers to groups        
                groups=$(grep -e "\<$user\>" $group_file | cut -f1 -d: -)
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
        cp /etc/apt/sources.list $sources_file 2>&1
        local retval=$?
        exit $retval
}
### TODO ###
restore_sources(){
}

backup_apt(){
        dpkg --get-selections > $dpkg_file   2>&1
        local retval=$?
        exit $retval
}

restore_apt(){
        dpkg --set-selections < $dpkg_file  2>&1
        local retval=$?
        exit $retval
}

restore_packages(){
        apt-get -u dselect-upgrade   2>&1
        local retval=$?
        exit $retval
}

backup_config(){
        tar -czf ${path}/etc_backup.tar.gz /etc/  2>&1
        local retval=$?
        exit $retval
}

create_backup(){
        ticket="$1-$(date +%Y%m%d)"
        cpath=$2
        if [[ $3 ]]; then
                mylogfile=$3
                RSYNC=" -avzh $cpath tsbackup@tsbackup:/var/tsbackup/$ticket 2>>$mylogfile"
        else
                RSYNC="rsync -avzh $cpath tsbackup@tsbackup:/var/tsbackup/$ticket"
        fi

        if ! $RSYNC; then
                exit=$?
        else
                exit=0
        fi

        echo $exit
}

restore_backup(){
        backupdir=$1
        backup_path=$2
         if [[ $3 ]]; then
                mylogfile=$3
                RESTORE="rsync -avh tsbackup@tsbackup:/var/tsbackup/$backupdir/ $backup_path/ 2>>$mylogfile"
        else
                RESTORE="rsync -avh tsbackup@tsbackup:/var/tsbackup/$backupdir/ $backup_path/"
        fi

        if ! $RESTORE; then
                exit=$?
        else
                exit=0
        fi

        echo $exit
}

