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

cd "$(dirname "$0")"
URL=$(echo "$QUTE_URL" | sed -e 's,^\([^?]*\)?.*$,\1,')

./qbvault.sh read "$URL" | (na=0
FORM_SETUP=""
while read action; do
  action=$(echo "$action" | sed -e "s,\",\\\\\",g")
  FORM_SETUP="$FORM_SETUP\
  if (forms[i].action.startsWith(\"$action\")) {
    var inputs = forms[i].getElementsByTagName(\"input\");
    for (var j = 0; j < inputs.length; ++j) {
"
  while read ntoken field_name; do
    if test -z "$ntoken"; then
      break
    fi
    read vtoken field_value
    if test "$ntoken" != n || test "$vtoken" != v; then
      echo "jseval -q alert(\"The qbvault file is corrupted!\");" >>"$QUTE_FIFO"
      exit 2
    fi
    name=$(echo "$field_name" | sed -e "s,\",\\\\\",g")
    value=$(echo "$field_value" | sed -e "s,\",\\\\\",g")
    FORM_SETUP="$FORM_SETUP\
      if (inputs[j].name == \"$name\")
        inputs[j].value = \"$value\";
"
  done
  FORM_SETUP="$FORM_SETUP\
    }
  }
"
  na=$((na + 1))
done
if test $na -gt 0; then
  JS_SCRIPT="var forms = document.getElementsByTagName(\"form\");
for (var i = 0; i < forms.length; ++i) {
$FORM_SETUP\
}"
  JS_SCRIPT=$(echo "$JS_SCRIPT" | tr '\n' ' ')
  echo "jseval -q $JS_SCRIPT" >>"$QUTE_FIFO"
else
  echo "jseval -q alert(\"No credentials found.\");" >>"$QUTE_FIFO"
fi)
