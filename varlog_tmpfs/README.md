varlog_tmpfs
============

Rsyncs log files at startup/shutdown in case /var/log is a tmpfs

Installation:

	* make a backup copy of /var/log if it is important
	* register /var/log/ as tmpfs in /etc/fstab (none /var/log/ tmpfs nodev,nosuid 0 0)
	* copy varlog_exclude to /etc/
	* adapt varlog_exclude to your needs
	* cp varlog_tmpfs to /etc/init.d/
	* rc-update add varlog_tmpfs boot
	* mkdir /var/log_permanent
	* start and stop and start the init script
