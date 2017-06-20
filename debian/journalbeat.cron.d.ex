#
# Regular cron jobs for the journalbeat package
#
0 4	* * *	root	[ -x /usr/bin/journalbeat_maintenance ] && /usr/bin/journalbeat_maintenance
