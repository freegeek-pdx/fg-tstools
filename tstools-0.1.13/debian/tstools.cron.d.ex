#
# Regular cron jobs for the tstools package
#
0 4	* * *	root	[ -x /usr/bin/tstools_maintenance ] && /usr/bin/tstools_maintenance
