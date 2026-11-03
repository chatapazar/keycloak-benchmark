#!/usr/bin/env bash
set -e
set -o pipefail
# set -x

#Functions
function usage {
  echo "Setup of test clients for the benchmark test with a pre-defined secret"
  echo "Usage: $(basename $0) -k KEYCLOAK_HOME -r REALM_NAME -c CLIENT_ID [-d]" 2>&1
  echo "-k keycloak home path ex: /home/opt/keycloak-18.0.0 : default value KEYCLOAK_HOME env variable"
  echo "-d delete the client and realm before re-creating them: default value is false"
  echo "-r realm : default value test-realm"
  echo "-c service account enabled client name : default value gatling"
  echo "-d delete the client and realm : default value is false"
  echo "-u user : default username user-0. The user's password will always be the username plus the suffix -password, ex: for user-0 this would be user-0-password"
  exit 1
}

function set_kcb_in_path {
  echo -e "Setting up kcadm.sh in PATH\n"
  export PATH=$PATH:$KEYCLOAK_HOME/bin
}


function create_user {
  for i in $( seq 1 $totalUsers ) 
  do
    kcadm.sh create users -s username=user$i -s enabled=true -s firstName=Firstname -s lastName=Lastname -s email=user$i@keycloak.org -r $REALM_NAME
    kcadm.sh set-password -r $REALM_NAME --username user$i --new-password user$i-password
    echo "INFO: Created New user user${i} in ${REALM_NAME}"
  done
}

function create_file {
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  OUTPUT_FILE="$SCRIPT_DIR/users.json"

  
  echo "Generating $totalUsers users into: $OUTPUT_FILE ..."

  echo "[" > "$OUTPUT_FILE"

  for ((i=1; i<=$totalUsers; i++)); do
    USERNAME="user$i"
    PASSWORD="user$i-password"

    if [ "$i" -eq "$totalUsers" ]; then
        printf '  { "username": "%s", "password": "%s" }\n' "$USERNAME" "$PASSWORD" >> "$OUTPUT_FILE"
    else
        printf '  { "username": "%s", "password": "%s" },\n' "$USERNAME" "$PASSWORD" >> "$OUTPUT_FILE"
    fi
  done

  echo "]" >> "$OUTPUT_FILE"

  echo "Success! File generated at $OUTPUT_FILE"
}


#main()
#setting default values
OPTIND=1
REALM_NAME=test-realm
CLIENT_ID=gatling
DELETE_ENTITIES='false'
USER_NAME=user-0

while getopts "k:r:u:c:d" arg; do
  case $arg in
    k) KEYCLOAK_HOME="$OPTARG";
        ;;
    r) REALM_NAME="$OPTARG";
        ;;
    c) CLIENT_ID="$OPTARG";
        ;;
    d) DELETE_ENTITIES=true;
        ;;
    u) USER_NAME="$OPTARG";
        ;;
    \?) echo "ERROR: Invalid option: -${OPTARG}" >&2
        usage
        ;;
  esac
done

#Handle missing opt args
if (( ${OPTIND} == 1 ))
then
  echo -e "ERROR: No Options Specified\n"
  usage
fi
shift $(( OPTIND -1 ))

#Setup the KCB client tool in the system PATH
set_kcb_in_path

export KEYCLOAK_HOME=/Users/ckongman/work/workspace/keycloak
totalUsers=10000
create_user
create_file