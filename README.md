# database-backup
Simple script to run database backup. The script must be able to be launched by a cron job, to send pgp emails and to have backup rotation

## How to install
Clone the repository

## How to use
execute `database_backup.sh` with options:
```
 -c|--command) Required. The command which do the dump. The output will be put into a file and zip
 -d|--database) The database name used to make a directory
 -r|--recipent) The recipient to send a mail in case of failure
 -s|--subject) The email subject
 -b|--backup) Optional. The remote server. After the backup is created, you have the option to send the tar in another server usign ssh for "repetition"
```