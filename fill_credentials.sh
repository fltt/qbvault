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

cd "$(dirname "$0")"
URL=$(echo "$QUTE_URL" | sed -e 's,^\([^?]*\)?.*$,\1,')

./qbvault.sh -R -u "$URL" | (
  NO_FORMS=""
  FORM_SETUP=""
  while read action; do
    if test "$action" = x; then
      NO_FORMS=X
      read field_name
      while test -n "$field_name"; do
        read field_value
        name=$(escape "$field_name")
        value=$(escape "$field_value")
        FORM_SETUP="$FORM_SETUP\
  if (inputs[i].name == \"$name\")
    inputs[i].value = \"$value\";
"
        read field_name
      done
    else
      action=$(escape "$action")
      FORM_SETUP="$FORM_SETUP\
  if (forms[i].action.startsWith(\"$action\")) {
    var inputs = forms[i].getElementsByTagName(\"input\");
    for (var j = 0; j < inputs.length; ++j) {
"
      read field_name
      while test -n "$field_name"; do
        read field_value
        name=$(escape "$field_name")
        value=$(escape "$field_value")
        FORM_SETUP="$FORM_SETUP\
      if (inputs[j].name == \"$name\")
        inputs[j].value = \"$value\";
"
        read field_name
      done
      FORM_SETUP="$FORM_SETUP\
    }
  }
"
    fi
  done
  if test -z "$FORM_SETUP"; then
    echo "jseval -q alert(\"No credentials found.\");" >>"$QUTE_FIFO"
  else
    if test -z "$NO_FORMS"; then
      JS_SCRIPT="var forms = document.getElementsByTagName(\"form\");
for (var i = 0; i < forms.length; ++i) {
$FORM_SETUP\
}"
    else
      JS_SCRIPT="var inputs = document.getElementsByTagName(\"input\");
for (var i = 0; i < inputs.length; ++i) {
$FORM_SETUP\
}"
    fi
    JS_SCRIPT=$(echo "$JS_SCRIPT" | tr '\n' ' ')
    echo "jseval -q $JS_SCRIPT" >>"$QUTE_FIFO"
  fi
)
