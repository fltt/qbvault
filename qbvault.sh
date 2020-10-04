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
  echo "gpg2 not found"
  exit 2
fi
if ! test -x "$GPG_CA"; then
  echo "gpg-connect-agent not found"
  exit 2
fi
if ! test -x "$SHA256"; then
  echo "sha256 not found"
  exit 2
fi

ADD=
READ=
RAW=
REMOVE=
PASSWORD=

URL=""
ACTION=""

usage() {
  local sn ss
  sn=$(basename "$0")
  ss=$(echo "$sn" | sed -e 's,., ,g')
  echo
  echo "Usage:"
  echo "  $sn -A -u <url> [-a <action>]"
  echo "  $ss {-n <name> [-p <value> |"
  echo "  $ss             -l <label> |"
  echo "  $ss             -c <command> [-p <argument> |"
  echo "  $ss                           -l <label>] ...]} ..."
  echo "  $sn -R [-u <url> [-r]]"
  echo "  $sn -D -u <url> [-a <action>]"
  echo "  $sn -U"
  echo
  echo "See README.md, section \"qbvault.sh\" for details."
  echo
}

only_one() {
  if test -n "$ADD$READ$REMOVE$PASSWORD"; then
    echo "Only one -A, -R, -D or -U option can be specified"
    usage
    exit 1
  fi
}

check_n_option() {
  if test $n_names -gt 0; then
    eval "cmd=\$command_${n_names}"
    eval "nl=\$n_labels_${n_names}"
    eval "na=\$n_arguments_${n_names}"
    if test -z "$cmd" && test $nl -eq 0 && test $na -eq 0; then
      echo "Each -n option requires at least one -l, -p or -c option"
      usage
      exit 1
    fi
  fi
}

escape_blanks() {
  echo "$1" | sed -e 's, ,%20,g;s,	,%09,g'
}

corrupt() {
  echo "Corrupt keystore"
  exit 4
}

n_names=0
# name_$i
# command_$i
# n_labels_$i
# label_$i_$j
# n_arguments_$i
# argument_$i_$j

while getopts "Aa:n:l:c:p:Rru:DU" option; do
  case "$option" in
    A) only_one
       ADD=X
       REMOVE=X ;;
    a) ACTION="$OPTARG" ;;
    n) check_n_option
       if test -z "$OPTARG"; then
         echo "Empty arg for -n option"
         usage
         exit 1
       fi
       n_names=$((n_names + 1))
       eval "n_labels_${n_names}=0"
       eval "n_arguments_${n_names}=0"
       eval "name_${n_names}=\"\$OPTARG\"" ;;
    l) eval "nl=\$n_labels_${n_names}"
       nl=$((nl + 1))
       eval "n_labels_${n_names}=\$nl"
       eval "label_${n_names}_${nl}=\"\$OPTARG\"" ;;
    c) if test -z "$OPTARG"; then
         echo "Empty -c option argument"
         usage
         exit 1
       fi
       eval "command_${n_names}=\"\$OPTARG\"" ;;
    p) eval "na=\$n_arguments_${n_names}"
       na=$((na + 1))
       eval "n_arguments_${n_names}=\$na"
       eval "argument_${n_names}_${na}=\"\$OPTARG\"" ;;
    R) only_one
       READ=X ;;
    r) RAW=X ;;
    u) URL="$OPTARG" ;;
    D) only_one
       REMOVE=X ;;
    U) only_one
       PASSWORD=X ;;
    *) usage
       exit 1;;
  esac
done

check_n_option

if test -z "$ADD$READ$REMOVE$PASSWORD"; then
  usage
  exit 0
fi

if test -n "$ADD"; then
  if test $n_names -eq 0; then
    echo "-A option requires one or more -n options"
    usage
    exit 1
  fi
  if test -z "$URL"; then
    echo "-A option requires the -u option"
    usage
    exit 1
  fi
  test -z "$ACTION" && ACTION="$URL"
elif test -n "$REMOVE"; then
  if test -z "$URL"; then
    echo "-D option requires the -u option"
    usage
    exit 1
  fi
fi

TMP_FILE1=$(mktemp)
TMP_FILE2=$(mktemp)
TMP_FILE3=$(mktemp)

trap "rm -P \"$TMP_FILE1\" \"$TMP_FILE2\" \"$TMP_FILE3\"" EXIT

if test -f "$QB_VAULT_FILE"; then
  if ! "$GPG" -dq "$QB_KEY_FILE" | "$GPG" -dq --passphrase-fd 0 --batch --pinentry-mode loopback "$QB_VAULT_FILE" >"$TMP_FILE1"; then
    echo "Decryption failed"
    exit 3
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
  i=0
  while test $i -lt $n_names; do
    i=$((i + 1))
    eval "name=\"\$name_${i}\""
    eval "cmd=\"\$command_${i}\""
    if test -z "$cmd"; then
      eval "na=\$n_arguments_${i}"
      if test $na -gt 0; then
        eval "argument=\"\$argument_${i}_1\""
        echo "n $name" >>"$TMP_FILE2"
        echo "v $argument" >>"$TMP_FILE2"
      else
        eval "label=\"\$label_${i}_1\""
        if test -z "$label"; then
          label="$name"
        fi
        label=$(escape_blanks "$label")
        echo "get_passphrase --data X X $label X" | "$GPG_CA" --decode >"$TMP_FILE3"
        if grep -q '^ERR ' "$TMP_FILE3"; then
          echo "Could not read user input:"
          cat "$TMP_FILE3"
          exit 0
        fi
        if grep -q '^D ' "$TMP_FILE3"; then
          echo "n $name" >>"$TMP_FILE2"
          sed -ne 's,^D \(.*\)$,v \1,p' "$TMP_FILE3" >>"$TMP_FILE2"
        else
          echo "Skipping field \"$name\"."
        fi
      fi
    else
      echo "n $name" >>"$TMP_FILE2"
      echo "c $cmd" >>"$TMP_FILE2"
      eval "na=\$n_arguments_${i}"
      j=0
      while test $j -lt $na; do
        j=$((j + 1))
        eval "argument=\"\$argument_${i}_${j}\""
        echo "a $argument" >>"$TMP_FILE2"
      done
      eval "nl=\$n_labels_${i}"
      j=0
      while test $j -lt $nl; do
        j=$((j + 1))
        eval "label=\"\$label_${i}_${j}\""
        if test -z "$label"; then
          label="Input line $j"
        fi
        label=$(escape_blanks "$label")
        echo "get_passphrase --data X X $label X" | "$GPG_CA" --decode >"$TMP_FILE3"
        if grep -q '^ERR ' "$TMP_FILE3"; then
          echo "Could not read user input:"
          cat "$TMP_FILE3"
          exit 0
        fi
        if grep -q '^D ' "$TMP_FILE3"; then
          sed -ne 's,^D \(.*\)$,v \1,p' "$TMP_FILE3" >>"$TMP_FILE2"
        else
          echo v >>"$TMP_FILE2"
        fi
      done
    fi
  done
  echo >>"$TMP_FILE2"
fi

if test -n "$PASSWORD" || ! test -f "$QB_KEY_FILE"; then
  echo "Creating a new keystore..."
  mkdir -p "$(dirname "$QB_KEY_FILE")"
  if ! "$GPG" --gen-random 2 32 | "$SHA256" | "$GPG" -c --personal-cipher-preferences AES256 --yes -o "$QB_KEY_FILE"; then
    echo "Could not create a new keystore"
    exit 3
  fi
fi

if test -n "$ADD$PASSWORD$REMOVE"; then
  cmp -s "$TMP_FILE1" "$TMP_FILE2" || PASSWORD=X
  if test -n "$PASSWORD"; then
    if ! "$GPG" -dq "$QB_KEY_FILE" | "$GPG" -c --passphrase-fd 0 --batch --pinentry-mode loopback --personal-cipher-preferences AES256 --yes -o "$QB_VAULT_FILE" "$TMP_FILE2"; then
      echo "Encryption failed"
      exit 3
    fi
  fi
else
  if test -z "$URL"; then
    cat "$TMP_FILE1"
  elif test -n "$RAW"; then
    sed -ne "\\|^$URLE#|,/^\$/p" "$TMP_FILE1" | sed -e 's,^[^#]*#,,'
  else
    sed -ne "\\|^$URLE#|,/^\$/p" "$TMP_FILE1" | sed -e 's,^[^#]*#,,' | while read action; do
      echo "$action"
      read token data
      while test -n "$token"; do
        test "$token" = n || corrupt
        echo "$data"
        cmd=""
        input=""
        while true; do
          read token data
          case "$token" in
            c) test -n "$data" || corrupt
               cmd="\"$data\"" ;;
            a) cmd="$cmd \"$data\"" ;;
            v) if test -z "$input"; then
                 input="$data"
               else
                 input="$input
$data"
               fi ;;
            *) if test -z "$cmd"; then
                 echo "$input"
               else
                 echo "$input" | eval "$cmd" >"$TMP_FILE3"
                 result=$?
                 if test $result -ne 0; then
                   echo "Command failed: $cmd"
                   exit 5
                 fi
                 head -1 "$TMP_FILE3"
               fi
               break ;;
          esac
        done
      done
      echo
    done >"$TMP_FILE2"
    cat "$TMP_FILE2"
  fi
fi
