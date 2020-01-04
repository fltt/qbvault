#! /bin/sh
#
# qbvault - Password manager for qutebrowser
#
# Written in 2020 by Francesco Lattanzio <franz.lattanzio@gmail.com>
#
# To the extent possible under law, the author have dedicated all
# copyright and related and neighboring rights to this software to
# the public domain worldwide. This software is distributed without
# any warranty.
#
# You should have received a copy of the CC0 Public Domain Dedication
# along with this software.
# If not, see <http://creativecommons.org/publicdomain/zero/1.0/>.

QB_KEY_FILE="$HOME/.config/qbkey.gpg"
QB_VAULT_FILE="$HOME/.config/qbvault.gpg"

GPG=$(which gpg2)
GPG_CA=$(which gpg-connect-agent)
SHA256=$(which sha256)

if ! test -x "$GPG"; then
  echo "ERROR: gpg2 not found."
  exit 2
fi
if ! test -x "$GPG_CA"; then
  echo "ERROR: gpg-connect-agent not found."
  exit 2
fi
if ! test -x "$SHA256"; then
  echo "ERROR: sha256 not found."
  exit 2
fi

COMMAND="$1"
URL="$2"
ACTION="$3"
shift 3

usage() {
  local sn
  sn=$(basename "$0")
  echo
  echo "Usage:"
  echo "  $sn add <url> <action> [<name> <label>]..."
  echo "  $sn read [<url>]"
  echo "  $sn remove <url> [<action>]"
  echo "  $sn updatepassword"
  echo
  echo "See README.md, section \"qbvault.sh\" for details."
  echo
}

ADD=""
PASSWORD=""
REMOVE=""

case "$COMMAND" in
add)
  if test -z "$URL" || test -z "$ACTION"; then
    usage
    exit 1
  fi
  ADD=X
  REMOVE=X ;;
read)
  ;;
remove)
  if test -z "$URL"; then
    usage
    exit 1
  fi
  REMOVE=X ;;
updatepassword)
  PASSWORD=X ;;
*)
  usage
  exit 0 ;;
esac

TMP_FILE1=$(mktemp)
TRAP_FILES="\"$TMP_FILE1\""

if test -z "$ADD$REMOVE"; then
  TMP_FILE2="$TMP_FILE1"
else
  TMP_FILE2=$(mktemp)
  TRAP_FILES="$TRAP_FILES \"$TMP_FILE2\""
  if test -n "$ADD"; then
    TMP_FILE3=$(mktemp)
    TRAP_FILES="$TRAP_FILES \"$TMP_FILE3\""
  fi
fi

trap "rm $TRAP_FILES" EXIT

if test -f "$QB_VAULT_FILE"; then
  if ! "$GPG" -dq "$QB_KEY_FILE" | "$GPG" -dq --passphrase-fd 0 --batch --pinentry-mode loopback "$QB_VAULT_FILE" >"$TMP_FILE1"; then
    echo "ERROR: Decryption failed."
    exit 2
  fi
fi

test -z "$URL" || URL=$(echo "$URL" | sed -e 's,#.*$,,')
test -z "$URL" || URLE=$(echo "$URL" | sed -e 's,|,\\|,g')
test -z "$ACTION" || ACTION=$(echo "$ACTION" | sed -e 's,#.*$,,')

if test -n "$REMOVE"; then
  if test -z "$ACTION"; then
    sed -e "\\|^$URLE#|,/^\$/d" "$TMP_FILE1" >"$TMP_FILE2"
  else
    ACTIONE=$(echo "$ACTION" | sed -e 's,|,\\|,g')
    sed -e "\\|^$URLE#$ACTIONE\$|,/^\$/d" "$TMP_FILE1" >"$TMP_FILE2"
  fi
fi

if test -n "$ADD"; then
  echo "$URL#$ACTION" >>"$TMP_FILE2"
  while test -n "$1"; do
    if test -z "$2"; then
      label="$1"
    else
      label="$2"
    fi
    echo "get_passphrase --data X X $label X" | "$GPG_CA" >"$TMP_FILE3"
    if grep -q '^ERR ' "$TMP_FILE3"; then
      echo "ERROR: Could not read user input:"
      cat "$TMP_FILE3" | sed -e 's,^,     | ,'
      exit 0
    fi
    if grep -q '^D ' "$TMP_FILE3"; then
      echo "n $1" >>"$TMP_FILE2"
      sed -ne 's,^D \(.*\)$,v \1,p' "$TMP_FILE3" >>"$TMP_FILE2"
    else
      echo "INFO: Skipping field \"$1\"."
    fi
    shift 2
  done
  echo >>"$TMP_FILE2"
fi

if test -n "$PASSWORD" || ! test -f "$QB_KEY_FILE"; then
  echo "INFO: Creating a new keystore..."
  mkdir -p "$(dirname "$QB_KEY_FILE")"
  if ! "$GPG" --gen-random 2 32 | "$SHA256" | "$GPG" -c --personal-cipher-preferences AES256 --yes -o "$QB_KEY_FILE"; then
    echo "ERROR: Could not create a new keystore."
    exit 3
  fi
fi

if test -n "$ADD$PASSWORD$REMOVE"; then
  cmp -s "$TMP_FILE1" "$TMP_FILE2" || PASSWORD=X
  if test -n "$PASSWORD"; then
    if ! "$GPG" -dq "$QB_KEY_FILE" | "$GPG" -c --passphrase-fd 0 --batch --pinentry-mode loopback --personal-cipher-preferences AES256 --yes -o "$QB_VAULT_FILE" "$TMP_FILE2"; then
      echo "ERROR: Encryption failed."
      exit 4
    fi
  fi
else
  if test -z "$URL"; then
    cat "$TMP_FILE1"
  else
    sed -ne "\\|^$URLE#|,/^\$/p" "$TMP_FILE1" | sed -e '1s,^[^#]*#,,'
  fi
fi
