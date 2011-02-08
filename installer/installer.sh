#! /bin/bash

# test for root
if [ "$(id -u)" != "0" ]; then
	echo "Sorry, you are not root."
	exit 1
fi
