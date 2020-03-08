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

test "$QUTE_MODE" = command || exit 0

escape() {
  echo "$1" | sed -e "s,\\\\,\\\\\\\\,g;s,\",\\\\\",g"
}

corrupt() {
  echo "jseval -q alert(\"The qbvault file is corrupted!\");" >>"$QUTE_FIFO"
  exit 3
}

cd "$(dirname "$0")"
URL=$(echo "$QUTE_URL" | sed -e 's,^\([^?]*\)?.*$,\1,')

./qbvault.sh -R -u "$URL" | (FORM_SETUP=""
while read action; do
  action=$(escape "$action")
  FORM_SETUP="$FORM_SETUP\
  if (forms[i].action.startsWith(\"$action\")) {
    var inputs = forms[i].getElementsByTagName(\"input\");
    for (var j = 0; j < inputs.length; ++j) {
"
  read token data
  while test -n "$token"; do
    test "$token" = n || corrupt
    field_name="$data"
    CMD=""
    INPUT=""
    while true; do
      read token data
      case "$token" in
        c) test -n "$data" || corrupt
           CMD="\"$data\"" ;;
        a) CMD="$CMD \"$data\"" ;;
        v) if test -z "$INPUT"; then
             INPUT="$data"
           else
             INPUT="$INPUT
$data"
           fi ;;
        *) if test -z "$CMD"; then
             field_value="$INPUT"
           else
             field_value=$(echo "$INPUT" | eval "$CMD")
             result=$?
             if test $result -ne 0; then
               command=$(escape "$CMD")
               echo "jseval -q alert(\"Command failed: $command\");" >>"$QUTE_FIFO"
               exit 0
             fi
           fi
           name=$(escape "$field_name")
           value=$(escape "$field_value")
           FORM_SETUP="$FORM_SETUP\
      if (inputs[j].name == \"$name\")
        inputs[j].value = \"$value\";
"
           break ;;
      esac
    done
  done
  FORM_SETUP="$FORM_SETUP\
    }
  }
"
done
if test -z "$FORM_SETUP"; then
  echo "jseval -q alert(\"No credentials found.\");" >>"$QUTE_FIFO"
else
  JS_SCRIPT="var forms = document.getElementsByTagName(\"form\");
for (var i = 0; i < forms.length; ++i) {
$FORM_SETUP\
}"
  JS_SCRIPT=$(echo "$JS_SCRIPT" | tr '\n' ' ')
  echo "jseval -q $JS_SCRIPT" >>"$QUTE_FIFO"
fi)
