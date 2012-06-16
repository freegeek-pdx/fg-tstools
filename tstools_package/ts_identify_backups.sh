#!/bin/bash
# this file has the following standard layout
# help function
# INCLUDES
#FUNCTIONS
# CONFIGURATION
# process option arguments
# MAIN

help(){
        cat <<EOF 
        usage $0 [OPTION]
        -h              prints this message
        This is a bash script.
EOF
        exit 0
}
# INCLUDES
#FUNCTIONS
# CONFIGURATION

# process option arguments
while getopts "h" option; do		# w: place variable following w in $OPTARG
	case "$option" in
		h) help;;
		[?])  echo "bad option supplied" ; 
			help;;	
	esac
done

#MAIN
