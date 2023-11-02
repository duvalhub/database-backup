#!/usr/bin/env bash
###################
# Functions
###################
launch_backup() {
	# Dump the database
	echo "Running backup for database '${DATABASE}' and uploading into secondary server '${REMOTE_SERVER}'"
	mkdir -p "$BACKUP_DIR"
	cd $BACKUP_DIR
	echo "Dumping database into file..."
	$BACKUP_COMMAND > "${BACKUP_FILE_RAW}"
	if [ "$?" -gt 0 ]; then
		echo "FAILED to dump the database"
		return 1
	fi
	echo "Compressing the dump into $BACKUP_FILE..."
	tar -czf "${BACKUP_FILE}" "${BACKUP_FILE_RAW}"
	rm -f "${BACKUP_FILE_RAW}"

	echo "Remove all but the $BACKUP_HISTORY latest backups"
	ls -t | tail -n +$BACKUP_HISTORY | xargs rm -f --

	if [ -n "$REMOTE_SERVER" ]; then
		echo "Uploading into other server $REMOTE_SERVER..."
		ssh "$REMOTE_USERNAME"@${REMOTE_SERVER} "mkdir -p '${BACKUP_DIR}'"
		if [ "$?" -gt 0 ]; then
			echo "FAILED to ssh into other server to create the directory ${BACKUP_DIR}"
			return 1
		fi
		scp "${BACKUP_FILE}" "$REMOTE_USERNAME"@"${REMOTE_SERVER}:${BACKUP_DIR}/${BACKUP_FILE}"
		if [ "$?" -gt 0 ]; then
			echo "FAILED scp backup file into other server"
			return 1
		fi
	fi
	echo "SUCCESS. Backup done and duplicated!"
}

###################
# Begin
###################
export DATABASE
REMOTE_USERNAME="root"
BACKUP_FILE_RAW="`date +%Y-%m-%d`.dump.sql"
BACKUP_FILE="${BACKUP_FILE_RAW}.tgz"
BACKUP_HISTORY=10
while [[ "$#" -gt 0 ]]; do case "$1" in
	-c|--command) BACKUP_COMMAND="$2"; shift;;
	-d|--database) DATABASE="$2"; shift;;
	-r|--recipent) RECIPIENT="$2"; shift;;
	-s|--subject) SUBJECT="$2"; shift;;
	-b|--backup) REMOTE_SERVER="$2"; shift;;
	*) echo "Invalid param $1"; exit 1;;	
esac; shift; done

invalid_params="false"
[ -z "$BACKUP_COMMAND" ] && echo "Missing BACKUP_COMMAND" && invalid_params=true
[ -z "$DATABASE" ] && echo "Missing DATABASE" && invalid_params=true
[ -z "$RECIPIENT" ] && echo "Missing RECIPIENT" && invalid_params=true
[ -z "$SUBJECT" ] && echo "Missing SUBJECT" && invalid_params=true
[ "$invalid_params" = "true" ] && echo "Invalid params" && exit 1

# Launch backup and send mail on failure
BACKUP_DIR="backups/$DATABASE"
OUTPUT=$(mktemp)
launch_backup 2>&1 > "$OUTPUT"
if [ "$?" -gt 0 ]; then
	cat "$OUTPUT" | gpg -ear "$RECIPIENT" | mail -s "$SUBJECT" "$RECIPIENT"
fi
rm -f "$OUTPUT"