#!/bin/bash
help(){
        cat <<EOF 
        usage $0 [OPTION]
	-m 		remind staff that they are facilitator/scribe by email
	-t		test. See what would have been done if it was runnig for real. 
        -h              prints this message
        This is a bash script.
EOF
        exit 0
}


email (){
	name=$1
	email=$2
	role=$3
	env MAILRC=/dev/null from="A Robot on behalf of <paulm@freegeek.org>" smtp=mail.freegeek.org  mailx -n -s "$role reminder" $email <<EOM
Hello $name,
	You are due to be a $role at the next staff meeting. Well I think you are but I'm just a dumb shell script so what do I know. 

You might want to check http://wiki.freegeek.org/index.php/Staff_meeting_facilitation_schedule to make sure. Please poke paulm@freegeek.org if I'm wrong.

	Bye!
		your friendly reminder robot.
EOM

}


magic_number_file="/home/paulm/magic-number"
#staff_members=(Amelia Darryl Jen Jessica Laurel Liane  Meredith Paul Richard Sean Tony) 

staff_members=(Amelia Darryl Jen Jessica Liane  Meredith Paul Richard Sean Tony)
staff_mem_len=$(( ${#staff_members[*]} - 1 ))
# associative array
declare -A email_list
email_list[Amelia]="alamb"
email_list[Darryl]="darryl"
email_list[Jen]="jhiggins"
email_list[Jessica]="jbeckett"
email_list[Laurel]="laurel"
email_list[Liane]="liane"
email_list[Meredith]="meredith"
email_list[Paul]="paulm"
email_list[Richard]="richard"
email_list[Sean]="scellef"
email_list[Tony]="tonyc"


while getopts ":htm" option; do
        case $option in
                h) help
                   exit 0
                ;;
                t) test_on="true"
                ;;
		m) mail_on="true"
		;;
                \?) help
                    exit 1
                ;;
        esac
done
read magic_number < $magic_number_file

facilitator=${staff_members[$magic_number]}
facilitator_email="${email_list[$facilitator]}@freegeek.org"

if (( $magic_number != 0   &&   $magic_number % $staff_mem_len == 0 )); then
	magic_number=0
else
	let magic_number++	
fi

scribe=${staff_members[$magic_number]}
scribe_email="${email_list[$scribe]}@freegeek.org"


if [[ $test_on ]]; then
	echo "remind $facilitator ($facilitator_email) that they are the next facilitator"
	echo "remind $scribe ($scribe_email) that they are the next scribe"

elif [[ $mail_on ]]; then
	email $facilitator $facilitator_email facilitator
	email $scribe $scribe_email scribe
else
	help
	exit
fi 

echo $magic_number >$magic_number_file

