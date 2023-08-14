#!/bin/bash -x
###########################################
# Fonction : MYSQL Database backup script
#
# Version : 1.5
# Last modification : 03/12/2012
# Auteur : AGNEL Eric ( eric.agnel@gmail.com )
###########################################




launchHelp=0 # initialise help to false

# Base directories
logPath="/var/log/$0.log"
savePath="/var/local/dumps/"

# Print the help
getHelp()
{
	echo "Script options : backupMysql.sh -u:XXX "
    echo "-h	- Print this help dialog."
	echo "-p	- Define the password to use for the database connection. ( -p:PASSWORD )"
	echo "-u	- Define the username to use for the connection. ( -u:USER )"
	echo "-db	- Define the database name to backup. All databases will be exported if empty ( -db:DATABASENAME )"
	echo "-log	- Define the path to the log file. ( -log:LOGPATH )"
	echo "-s	- Define the path for the backup directory. ( -s:SAVEPATH )"
	echo ""
	echo "All arguments are optional except for the user. The minimum command is backupMysql.sh -u:XXX"
}

if [ $# -eq 0 ]
then
	echo "No arguments provided. You must speficy at least the user to use for the connection." >> $logPath
	echo ""
	getHelp
else
	# First check if the log arguments is set
	for args in "$@"
	do
		if [[ "$args" =~ ^[-]log[:][a-zA-Z0-9\/]{1,} ]]
		then
			logPath=$(expr substr "$args" 6 $(expr length "$args"))
			echo "Log file set to : $logPath"
			break
		fi
	done
	
	echo "=================================" >> $logPath
	echo "$(date "+%d-%m-%Y %H:%M") - Starting database backup" >> $logPath

	for arg in "$@" #Get the arguments for job setup
	do
		if [[ "$arg" =~ ^[-]db[:][a-zA-Z0-9]{1,} ]]
		then
			database=$(expr substr "$arg" 5 $(expr length "$arg")) # set the name of the database to be saved
		elif [[ "$arg" =~ ^[-]u[:][a-zA-Z0-9]{1,} ]]
		then
			user=$(expr substr "$arg" 4 $(expr length $arg)) # Set the user to be used for connection to the database
		elif [[ "$arg" =~ ^[-]p[:][a-zA-Z0-9]{1,} ]]
		then
			password=$(expr substr "$arg" 4 $(expr length "$arg")) # Set the password to be used for connection to the database
		elif [[ "$arg" == "-h" ]]
		then
			launchHelp=1 # set the help menu to true
		elif [[ "$arg" =~ ^[-]s[:][a-zA-Z0-9\/]{1,}[/]$ ]]
		then
			savePath=$(expr substr "$arg" 4 $(expr length "$arg")) # Set the path for the backup files
		else
			echo "$0 - $(date "+%d-%m-%Y %H:%M") - Argument $arg not recognised. Use -h for more informations." >> "/var/log/messages" 
		fi
	done


	if [[ $launchHelp != 1 ]] # Print the help if asked for.
	then
		if [[ "$user" != "" ]] # Check if a user is defined
		then
	        if [[ "$password" != "" ]] # is a password provided? if yes use it.
            then
               	echo "$(date "+%d-%m-%Y %H:%M") - A password provided for the user $user" >> $logPath
				mysqlCommandPass="-p$password"
				mysqldCommandPass="--password=$password"
            else
                echo "$(date "+%d-%m-%Y %H:%M") - No password provided, connection will be made without one." >> $loPath
				mysqlCommandPass=""
				mysqldCommandPass=""
            fi
		

			# Check for a database name.
			# If provided, the backup will save this database only. 
			# If not provided, will backup all databases.
			if [[ "$database" != "" ]] 
			then
				echo "$(date "+%d-%m-%Y %H:%M") - Database $database will be saved. Checking for the database on the server." >> $logPath
				
				# Check if the database exist.
				for i in $(mysql -u $user $mysqlCommandPass -e "SHOW DATABASES;")
				do
					if [[ $i == $database ]]
	              	then
						echo "$(date +%d/%m/%Y-%H:%M) - The database is present. Will backup $i to $savePath$DATE-$i.sql" >> $logPath
						mysqldump --databases "$i" --user="$user" "$mysqldCommandPass" --lock-tables > "$savePath$(date +%d-%m-%Y)-$i.sql"
					else
						echo "Database notfound. backup aborted."
					fi
				done
			else
				echo "$(date "+%d-%m-%Y %H:%M") - No database name given. Will backup every databases on the server" >> $logPath
				for i in $(mysql -u $user $mysqlCommandPass -e "SHOW DATABASES;")
				do
					# Backup all databases except for MYSQL default databases
					if [[ "$i" != "performance_schema" && "$i" != "Database" && "$i" != "information_schema" && "$i" != "test" && "$i" != "mysql" ]]
		            then
		                    echo "$(date "+%d-%m-%Y %H:%M") - The database $i has been saved to $savePath$(date +%d-%m-%Y)-$i.sql" >> $logPath
                		    mysqldump --databases "$i" --user="$user" "$mysqldCommandPass" --lock-tables > "$savePath$(date +%d-%m-%Y)-$i.sql"
                	fi
				done
			fi
		else
			echo "$(date "+%d-%m-%Y %H:%M") - No username specified. Backup aborted." >> $logPath
		fi

		echo "$(date "+%d-%m-%Y %H:%M") - Stoping database backup. " >> $logPath
		echo "=================================" >> $logPath
		echo ""
	else
		getHelp
	fi
fi

unset user
unset password
unset database
unset arg
unset args