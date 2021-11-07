function _secrets_save_file() {
    local FILE=$1;
    local KEYCHAIN="${HOME}/Documents/Secrets.keychain-db";

    if [ ! -f $KEYCHAIN ]; then
        echo "No such keychain: ${KEYCHAIN}"
        return 1
    fi

    if [ ! -f $FILE ]; then
        echo "No such file: ${FILE}"
        return 1
    fi

    local CONTENTS=$(cat $FILE)
    local NAME=${2:-"~/$(relative $HOME $FILE)"}

    security delete-generic-password -a "" -s "${NAME}" -C note > /dev/null 2>&1 
    security add-generic-password -a "" -s "${NAME}" -w "${CONTENTS}" -C note -T "" -D "secret file" "${KEYCHAIN}"

    return 0
}

function _secrets_load_file() {
    local FILE=$1;
    local OUT_FILE=${2:-$1}
    local KEYCHAIN="${HOME}/Documents/Secrets.keychain-db";

    if [ ! -f $KEYCHAIN ]; then
        echo "No such keychain: ${KEYCHAIN}"
        return 1
    fi

    local NAME="~/$(relative $HOME $FILE)"
    local CONTENTS=$(security find-generic-password -a "" -s "${NAME}" -w -C note "${KEYCHAIN}" 2> /dev/null | xxd -p -r)

    if [ -z "$CONTENTS" ]; then
        echo "No such secret: ${NAME}"
        return 1
    fi

    mkdir -p $(dirname "${OUT_FILE}")
    rm -f "${OUT_FILE}" 
    echo "${CONTENTS}" > "${OUT_FILE}"
    chmod 0400 "${OUT_FILE}"

    return 0
}

function secrets() {
    case $1 in
        add)
            _secrets_save_file "$2" "$3"
            ;;
        save)
            _secrets_save_file "$2" "$3"
            ;;
        load)
            _secrets_load_file "$2" "$3"
            ;;
        *)
            echo "secrets save <infile> [keyname]"
            echo "secrets load <keyname> [outfile]"
            return 1
            ;;
    esac
}
