#!/bin/bash

###############
# Conventions #
###############

# Since my bash function 'libraries'/include scripts are rapidly expanding
# I'm introducing a new convention.
# All scripts will start ts_ 
# All libraries will have a second part that acts as a prefix
# finally there will be an actual human readable name
# So this library is called ts_rt_request-tracker_functions.sh
# All functions will start with the prefix followed by a dot.i
#  e.g. rt.fuction_name

# all libraries will:
#       include a prefix.describe function 
#       have a #!/bin/bash line at the top
#       call this function at the end of the script, 
#       testing for -h or --help
#       so you can call the script directly 
#       to get a description of what it does
#       ditto for prefix.list_functions


template.example_function(){
#description
if global.check_desc $1; then cat <<EOF
$FUNCNAME 
Insert description here
EOF
    return
fi
#function...
}

# example

#wget --keep-session-cookies  --save-cookies cookies.txt  --post-data 'user=$RTUSER&pass=$RTPASS`' -qO-  todo.freegeek.org/REST/1.0/search/ticket?query=Queue=%27TechSupport%27ANDid=$TICKET
                   
# N.B. %27 = ' and is needed 

# need to add format.

# Global/Config Variables

rt_global_queue='TechSupport'
rt_ticketsys_host='todo.freegeek.org'
rt_ticketsys_user='tsrobot'
rt_ticketsys_password='EucNabs4'

rt_command="wget --keep-session-cookies  --save-cookies cookies.txt  --post-data 'user=${rt_ticketsys_user}&pass=${rt_ticketsys_password}' -qO- "

rt_url="${rt_ticketsys_host}/REST/1.0/"

# Functions common to all libraries
global.tolower(){
echo $1 | tr [:upper:] [:lower:]
}

global.check_desc(){
local var=$(global.tolower $1)
if [[ $var == 'help' ]]; then
    return 0
else
    return 1
fi
}

#List functions library contains
global.list_functions(){
for function in $(grep '()' $0| grep -v 'global' | grep -v 'grep'); do
    function_name=$(echo $function | awk -F '(' '{print $1}')
    echo $function_name
    $function_name 'help'
done
}


# Describe what this library does
rt.describe(){ 
#description
if global.check_desc $1; then cat <<EOF
$FUNCNAME [string]
Prints description of library
EOF
    return 
fi
cat <<EOF

This file is intended as a bash library. 
Calling it directly merely  prints this description.

It contains functions that enable you to work easily with the REST API of Request Tracker, the ticketing system used by Free Geek. 

They can be used to get information from request tracker, such as the ticket status, and to post comments directly etc.

EOF
}

#List functions library contains
rt.list_functions(){ 
if global.check_desc $1; then cat <<EOF
$FUNCNAME 
Prints listing of all library specific functions in library.
EOF
    return
fi
global.list_functions
}

rt.search_ticket(){
#description
if global.check_desc $1; then cat <<EOF
$FUNCNAME [string]
Returns the result of search defined in string. This is primarily intended 
for internal use by this library but maybe used to construct searchs. 
Requires a correctly formatted string.

EOF
    return
fi

#function
local search_terms=$1
local result=$(${rt_comand} "${rt_url}/search/ticket?query=${search_terms}")
echo $result
}

rt.check_message_status(){
#description
if global.check_desc $1; then cat <<EOF
    $FUNCNAME 
    Returns 0 if RT returns a message sucessfully
       i.e. RT/3.8.8 200 Ok
    Otherwise 1 
EOF
        return
    fi

#function...
local status_line="$1"
if [[ $status_line =~ "200 Ok" ]]; then
        return 0
else 
        return 1
fi
}


rt.is_valid_ticket(){
# description
if global.check_desc $1; then cat <<EOF
$FUNCNAME [ticket-no] [queue]  
Tests to see if a ticket exists. Takes a ticket number and optionally
a queue name. Assumes tech support queue otherwise (set default queue in the script. Edit rt_global_queue variable to change). 
Returns 0 on success (i.e. ticket exists in queue)
        1 if ticket does not exist in queue
        3 other error e.g. RT  returned  bad request
EOF
    return
fi
# function
# set ticket id & queue
local id=$1
if  [[ -n $2 ]]; then
    local queue=$2
else
   local queue=$rt_global_queue
fi 

# get results from RT and push to array
# searches for ticket $id in queue $queue
declare -a local rt_message
while read line; do
        # push line onto rt_message array
        rt_message=(${rt_message[@]}  "$line")
done < <(rt.search_ticket "Queue=%27${queue}%27ANDid=${id}")

# check message status
local status=${rt_message[0]}
rt.check_message_status $status
if [[ $? -ne 0 ]]; then
        echo "RT did not return a valid message"
        return 3
fi

# check message contents
#  ${array[${#array[*]}-1]} = last member of array
local content= ${rt_message[${#rt_message[*]}-1]}

# return 1 if contents indicate no message found
if [[ $content =~ "No matching results." ]]; then 
        return 1
else
        return 0
fi
}

rt.post_comment(){
#description
if global.check_desc $1; then cat <<EOF
$FUNCNAME 
Usage:
$FUNCNAME [ticket_no] ["message"]

Adds a comment to a ticket
EOF
    return
fi
#function...

local ticket=$1
shift $@
local message=$@

# Ticket History Comment Edit

# To add a comment to an existing ticket: POST on "/REST/1.0/ticket/<ticket-id>/comment" with a variable name "content", containing "key: value" line by line:

# id: <ticket-id>
# Action: comment
# Text: the text comment
# Attachment: an attachment filename/path

# Action can be "comment" or "correspond". For a list of fields you can use in correspondence, try "/opt/rt3/bin/rt correspond ticket/1" 

# wget --keep-session-cookies  --save-cookies cookies.txt  --post-data "user=tsrobot&pass=EucNabs4&content=id: 34168\nAction: comment\nText: test\nAttachment: " -qO- http://todo.freegeek.org/REST/1.0/ticket/34168/comment
# ^^^ doesn't work but getting close


local url=${rt_url}ticket/${ticket}/comment"

}


# END OF FILE, FUNCTIONS GO ABOVE THIS LINE
# Describe what this library does, and what it contains
if [[ $1 == "-h" || $1 == "--help" ]]; then
        rt.describe
        rt.list_functions
fi
