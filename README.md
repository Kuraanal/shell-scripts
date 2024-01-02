# Database Backup Shell Script

This shell script (`backupMysql.sh`) is designed for MySQL database backup with customizable options. It allows you to back up specific databases or all databases on a MySQL server, and it provides flexibility with options like specifying a username, password, log file path, and backup directory.

## Installation

Clone the repository to your local machine using the following command:

```bash
git clone https://github.com/Kuraanal/shell-scripts.git
```

## Usage

To run the script, execute the following command in the terminal:

```bash
./backupMysql.sh -u:USERNAME [-p:PASSWORD] [-db:DATABASENAME] [-log:LOGPATH] [-s:SAVEPATH]
```

### Options

- `-u:USERNAME`: Specify the username for the MySQL database connection. (Required)
- `-p:PASSWORD`: Define the password to use for the database connection.
- `-db:DATABASENAME`: Define the database name to back up. All databases will be exported if empty.
- `-log:LOGPATH`: Define the path to the log file.
- `-s:SAVEPATH`: Define the path for the backup directory.

### Example

```bash
./backupMysql.sh -u:myuser -p:mypassword -db:mydatabase -log:/var/log/mybackup.log -s:/var/local/backups/
```

## Features

- Database backup with optional username and password.
- Ability to specify a target database or back up all databases.
- Customizable log file path and backup directory.

## Log Output

The script generates a log file (`/var/log/backupMysql.sh.log` by default) that includes information about the backup process, such as start time, selected options, and backup status.

## Notes

- Ensure that MySQL command-line tools are installed and accessible in your environment.
- Review the script options using the `-h` flag for help.