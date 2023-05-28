#!/bin/bash -x
###########################################
# Fonction : Sauvegarde des bases Mysql
#            sur serveur LINUX
#
# Version : 1.5
# Date de modification : 03/12/2012
# Auteur : AGNEL Eric ( eric.agnel@gmail.com )
###########################################




launchHelp=0 # Definit la variable de test sur false par defaut

# Chemins de base. Utilises par le script si aucun argument ne les specifie
logPath="/var/log/$0.log"
savePath="/var/local/dumps/"

#Fonction d'affichage de l'aide
afficheHelp()
{
	echo "Options du script : backupMysql.sh -u:XXX "
    echo "-h	- Affiche l'aide d'utilisation du script."
	echo "-p	- Definit le mot de passe a utiliser pour la connexion aux bases. ( -p:PASSWORD )"
	echo "-u	- \"OBLIGATOIRE\" Definit le compte pour la connexion aux bases. ( -u:USER )"
	echo "-db	- Definit le nom de la base a sauvegarder. ( -db:DATABASENAME )"
	echo "-log	- Chemin du fichier LOG. ( -log:LOGPATH )"
	echo "-s	- Chemin du dossier de destination des sauvegardes. ( -s:SAVEPATH )"
	echo ""
	echo "Seul l'argument \"-u:USER\" est obligatoire. Les autres ont une valeur de base ou ne sont pas necessaires."
}

if [ $# -eq 0 ]
then
	echo "Aucun argument fournit. Veuillez fournir au moins un compte de connexion a la base" >> $logPath
	echo ""
	afficheHelp
else
	# Verif si l'argument -log est specifie
	for args in "$@"
	do
		if [[ "$args" =~ ^[-]log[:][a-zA-Z0-9\/]{1,} ]]
		then
			logPath=$(expr substr "$args" 6 $(expr length "$args")) # Modifie le chemin d'acces du fichier LOG
			echo "Fichier log definie a : $logPath"
			break
		fi
	done
	
	echo "=================================" >> $logPath
	echo "$(date "+%d-%m-%Y %H:%M") - Lancement de la procedure de sauvegarde des bases MySQL" >> $logPath

	for arg in "$@" #Recuperation des arguments pour configuration du Job.
	do
		if [[ "$arg" =~ ^[-]db[:][a-zA-Z0-9]{1,} ]]
		then
			database=$(expr substr "$arg" 5 $(expr length "$arg")) #Specifie le nom de la base a sauvegarder
		elif [[ "$arg" =~ ^[-]u[:][a-zA-Z0-9]{1,} ]]
		then
			user=$(expr substr "$arg" 4 $(expr length $arg)) # Specifie le compte a utiliser pour la connexion a la base
		elif [[ "$arg" =~ ^[-]p[:][a-zA-Z0-9]{1,} ]]
		then
			password=$(expr substr "$arg" 4 $(expr length "$arg")) # Specifie le mot de passe a utiliser avec le compte de connexion
		elif [[ "$arg" == "-h" ]]
		then
			launchHelp=1 # Specifie la variable d'affichage d'aide a True
		elif [[ "$arg" =~ ^[-]s[:][a-zA-Z0-9\/]{1,}[/]$ ]]
		then
			savePath=$(expr substr "$arg" 4 $(expr length "$arg")) # Modifie le chemin d'acces des fichiers de sauvegarde
		else
			echo "$0 - $(date "+%d-%m-%Y %H:%M") - Argument $arg non reconnu. Utilisez l'argument -h pour plus d'informations." >> "/var/log/messages" 
		fi
	done


	if [[ $launchHelp != 1 ]] # Verifis si l'aide est demandee. Si oui, affiche l'aie, sinon cotinu le Job.
	then
		if [[ "$user" != "" ]] # Verifie qu'un compte a bien ete specifie pour poursuivre le job
		then
			echo "$(date "+%d-%m-%Y %H:%M") - Un compte a ete fournit. Poursuite du Job" >> $logPath

	        if [[ "$password" != "" ]] # Verifie si un mot de passe est necessaire a la connexion
            then
               	echo "$(date "+%d-%m-%Y %H:%M") - Mot de passe fournit. Utilisation du mot de passe avec le compte $user" >> $logPath
				mysqlCommandPass="-p$password"
				mysqldCommandPass="--password=$password"
            else
                echo "$(date "+%d-%m-%Y %H:%M") - Aucun mot de passe fournit. Aucun mot de passe ne sera pas utilise pour la conexion a la base" >> $loPath
				mysqlCommandPass=""
				mysqldCommandPass=""
            fi
		
			if [[ "$database" != "" ]] # Verifie qu'une base est demandee pour la sauvegarde. Si oui sauvegarde uniquement cette base, sinon sauvegarde toutes les bases hors bases Systeme
			then
				echo "$(date "+%d-%m-%Y %H:%M") - Demande de sauvegarde de la base $database. Verification de sa presence sur le serveur" >> $logPath
				
				# Verifis si la base passee en parametre existe bien dans MySQL
				for i in $(mysql -u $user $mysqlCommandPass -e "SHOW DATABASES;")
				do
					if [[ $i == $database ]]
	              	then
						echo "$(date +%d/%m/%Y-%H:%M) - Base presente. Sauvegarde de la base $i vers $savePath$DATE-$i.sql" >> $logPath
						mysqldump --databases "$i" --user="$user" "$mysqldCommandPass" --lock-tables > "$savePath$(date +%d-%m-%Y)-$i.sql"
					else
						echo "Base non trouvee sur le serveur. Abandon de la sauvegarde."
					fi
				done
			else
				echo "$(date "+%d-%m-%Y %H:%M") - Aucun nom de Base specifie. Sauvegarde de toutes les bases" >> $logPath
				for i in $(mysql -u $user $mysqlCommandPass -e "SHOW DATABASES;")
				do
					# Sauvegarde toutes les bases ne faisant pas partie des base standard de MySQL
					if [[ "$i" != "performance_schema" && "$i" != "Database" && "$i" != "information_schema" && "$i" != "test" && "$i" != "mysql" ]]
		            then
		                    echo "$(date "+%d-%m-%Y %H:%M") - Sauvegarde de la base $i vers $savePath$(date +%d-%m-%Y)-$i.sql" >> $logPath
                		    mysqldump --databases "$i" --user="$user" "$mysqldCommandPass" --lock-tables > "$savePath$(date +%d-%m-%Y)-$i.sql"
                	fi
				done
			fi
		else
			echo "$(date "+%d-%m-%Y %H:%M") - Aucun nom d'utilisateur n'a ete specifie. Abandon de la sauvegarde" >> $logPath
		fi

		echo "$(date "+%d-%m-%Y %H:%M") - Fin de la procedure de sauvegarde" >> $logPath
		echo "=================================" >> $logPath
		echo ""
	else
		afficheHelp
	fi
fi

unset user
unset password
unset database
unset arg
unset args