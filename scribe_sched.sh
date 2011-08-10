#!/bin/bash
help(){
        cat <<EOF 
        usage $0 [OPTION]
        -h              prints this message
        This is a bash script.
EOF
        exit 0
}

  staff_members=(Amelia Darryl Jen Jessica Laurel Liane  Meredith Paul Richard Sean Tony) 

// staff_members=(Amelia Darryl Jen Jessica Liane  Meredith Paul Richard Sean Tony)


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


# echo test2 | mail -s test2 paulm@freegeek.org
