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
    FORM_N_SETUP=""
    FORM_L_SETUP=""
    FORM_H_SETUP=""
    FORM_I_SETUP=""
    FORM_T_SETUP=""
    if test "$action" = x; then
      if test -n "$NO_FORMS"; then
        echo "jseval -q alert(\"ERROR: Multiple null-actions!\");" >>"$QUTE_FIFO"
        exit 1
      fi
      NO_FORMS=X
      read field_type field_name
      while test -n "$field_name"; do
        read field_value
        name=$(escape "$field_name")
        value=$(escape "$field_value")
        case "$field_type" in
          n) if test -z "$FORM_N_SETUP"; then
               FORM_N_SETUP="
    "
             else
               FORM_N_SETUP="$FORM_N_SETUP else "
             fi
             FORM_N_SETUP="${FORM_N_SETUP}if (input.name == \"$name\") {
      qbvault_set_value(input, \"$value\");
    }" ;;
          l) if test -z "$FORM_L_SETUP"; then
               FORM_L_SETUP="
    "
             else
               FORM_L_SETUP="$FORM_L_SETUP else "
             fi
             FORM_L_SETUP="${FORM_L_SETUP}if ((input.labels != null) && (input.labels.length > 0) && (input.labels[0].innerText == \"$name\")) {
      qbvault_set_value(input, \"$value\");
    }" ;;
          h) if test -z "$FORM_H_SETUP"; then
               FORM_H_SETUP="
    "
             else
               FORM_H_SETUP="$FORM_H_SETUP else "
             fi
             FORM_H_SETUP="${FORM_H_SETUP}if (input.placeholder == \"$name\") {
      qbvault_set_value(input, \"$value\");
    }" ;;
          i) if test -z "$FORM_I_SETUP"; then
               FORM_I_SETUP="
    "
             else
               FORM_I_SETUP="$FORM_I_SETUP else "
             fi
             FORM_I_SETUP="${FORM_I_SETUP}if (input.id == \"$name\") {
      qbvault_set_value(input, \"$value\");
    }" ;;
          t) if test -z "$FORM_T_SETUP"; then
               FORM_T_SETUP="
    "
             else
               FORM_T_SETUP="$FORM_T_SETUP else "
             fi
             FORM_T_SETUP="${FORM_T_SETUP}if (type == \"$name\") {
      qbvault_set_value(input, \"$value\");
    }" ;;
        esac
        read field_type field_name
      done
      if test -n "$field_type"; then
        echo "jseval -q alert(\"ERROR: Empty name field!\");" >>"$QUTE_FIFO"
        exit 2
      fi
      if test -n "$FORM_N_SETUP$FORM_L_SETUP$FORM_H_SETUP$FORM_I_SETUP$FORM_T_SETUP"; then
        FORM_SETUP="$FORM_SETUP
  if ((input.name != null) && (input.name != \"\") && !fields.has([\"n\", input.name])) {$FORM_N_SETUP
    fields.add([\"n\", input.name]);
  }"
      fi
      if test -n "$FORM_L_SETUP$FORM_H_SETUP$FORM_I_SETUP$FORM_T_SETUP"; then
        FORM_SETUP="$FORM_SETUP else if ((input.labels != null) && (input.labels.length > 0) && (input.labels[0].innerText != null) && (input.labels[0].innerText != \"\") && !fields.has([\"l\", input.labels[0].innerText])) {$FORM_L_SETUP
    fields.add([\"l\", input.labels[0].innerText]);
  }"
      fi
      if test -n "$FORM_H_SETUP$FORM_I_SETUP$FORM_T_SETUP"; then
        FORM_SETUP="$FORM_SETUP else if ((input.placeholder != null) && (input.placeholder != \"\") && !fields.has([\"h\", input.placeholder])) {$FORM_H_SETUP
    fields.add([\"h\", input.placeholder]);
  }"
      fi
      if test -n "$FORM_I_SETUP$FORM_T_SETUP"; then
        FORM_SETUP="$FORM_SETUP else if ((input.id != null) && (input.id != \"\") && !fields.has([\"i\", input.id])) {$FORM_I_SETUP
    fields.add([\"i\", input.id]);
  }"
      fi
      if test -n "$FORM_T_SETUP"; then
        FORM_SETUP="$FORM_SETUP else {
    var type = input.type;
    if ((type == null) || (type == \"\"))
      type = \"text\";
    if (!types.has(type))
      types.set(type, 1);
    var count = types.get(type);
    types.set(type, count + 1);
    if (count > 1)
      type += \"#\" + count;$FORM_T_SETUP
  }"
      fi
    else
      action=$(escape "$action")
      FORM_SETUP="$FORM_SETUP
  if (form.action.startsWith(\"$action\")) {
    for (input of form.getElementsByTagName(\"input\")) {"
      read field_type field_name
      while test -n "$field_name"; do
        read field_value
        name=$(escape "$field_name")
        value=$(escape "$field_value")
        case "$field_type" in
          n) if test -z "$FORM_N_SETUP"; then
               FORM_N_SETUP="
        "
             else
               FORM_N_SETUP="$FORM_N_SETUP else "
             fi
             FORM_N_SETUP="${FORM_N_SETUP}if (input.name == \"$name\") {
          qbvault_set_value(input, \"$value\");
        }" ;;
          l) if test -z "$FORM_L_SETUP"; then
               FORM_L_SETUP="
        "
             else
               FORM_L_SETUP="$FORM_L_SETUP else "
             fi
             FORM_L_SETUP="${FORM_L_SETUP}if ((input.labels != null) && (input.labels.length > 0) && (input.labels[0].innerText == \"$name\")) {
          qbvault_set_value(input, \"$value\");
        }" ;;
          h) if test -z "$FORM_H_SETUP"; then
               FORM_H_SETUP="
        "
             else
               FORM_H_SETUP="$FORM_H_SETUP else "
             fi
             FORM_H_SETUP="${FORM_H_SETUP}if (input.placeholder == \"$name\") {
          qbvault_set_value(input, \"$value\");
        }" ;;
          i) if test -z "$FORM_I_SETUP"; then
               FORM_I_SETUP="
        "
             else
               FORM_I_SETUP="$FORM_I_SETUP else "
             fi
             FORM_I_SETUP="${FORM_I_SETUP}if (input.id == \"$name\") {
          qbvault_set_value(input, \"$value\");
        }" ;;
          t) if test -z "$FORM_T_SETUP"; then
               FORM_T_SETUP="
        "
             else
               FORM_T_SETUP="$FORM_T_SETUP else "
             fi
             FORM_T_SETUP="${FORM_T_SETUP}if (type == \"$name\") {
          qbvault_set_value(input, \"$value\");
        }" ;;
        esac
        read field_type field_name
      done
      if test -n "$field_type"; then
        echo "jseval -q alert(\"ERROR: Empty name field!\");" >>"$QUTE_FIFO"
        exit 2
      fi
      if test -n "$FORM_N_SETUP$FORM_L_SETUP$FORM_H_SETUP$FORM_I_SETUP$FORM_T_SETUP"; then
        FORM_SETUP="$FORM_SETUP
      if ((input.name != null) && (input.name != \"\") && !fields.has([\"n\", input.name])) {$FORM_N_SETUP
        fields.add([\"n\", input.name]);
      }"
      fi
      if test -n "$FORM_L_SETUP$FORM_H_SETUP$FORM_I_SETUP$FORM_T_SETUP"; then
        FORM_SETUP="$FORM_SETUP else if ((input.labels != null) && (input.labels.length > 0) && (input.labels[0].innerText != null) && (input.labels[0].innerText != \"\") && !fields.has([\"l\", input.labels[0].innerText])) {$FORM_L_SETUP
        fields.add([\"l\", input.labels[0].innerText]);
      }"
      fi
      if test -n "$FORM_H_SETUP$FORM_I_SETUP$FORM_T_SETUP"; then
        FORM_SETUP="$FORM_SETUP else if ((input.placeholder != null) && (input.placeholder != \"\") && !fields.has([\"h\", input.placeholder])) {$FORM_H_SETUP
        fields.add([\"h\", input.placeholder]);
      }"
      fi
      if test -n "$FORM_I_SETUP$FORM_T_SETUP"; then
        FORM_SETUP="$FORM_SETUP else if ((input.id != null) && (input.id != \"\") && !fields.has([\"i\", input.id])) {$FORM_I_SETUP
        fields.add([\"i\", input.id]);
      }"
      fi
      if test -n "$FORM_T_SETUP"; then
        FORM_SETUP="$FORM_SETUP else {
        var type = input.type;
        if ((type == null) || (type == \"\"))
          type = \"text\";
        if (!types.has(type))
          types.set(type, 1);
        var count = types.get(type);
        types.set(type, count + 1);
        if (count > 1)
          type += \"#\" + count;$FORM_T_SETUP
      }"
      fi
      FORM_SETUP="$FORM_SETUP
    }
  }"
    fi
  done
  if test -z "$FORM_SETUP"; then
    echo "jseval -q alert(\"No credentials found.\");" >>"$QUTE_FIFO"
  else
    JS_SCRIPT="function qbvault_set_value(field, value) {
  if ((field.type == \"checkbox\") || (field.type == \"radio\")) {
    var val = value.toLowerCase();
    field.checked = ((val != \"0\") && (val != \"no\") && (val != \"false\"));
  } else {
    field.value = value;
  }
}"
    if test -z "$NO_FORMS"; then
      JS_SCRIPT="$JS_SCRIPT
for (form of document.getElementsByTagName(\"form\")) {
  var fields = new Set();
  var types = new Map();$FORM_SETUP
}"
    else
      JS_SCRIPT="$JS_SCRIPT
var fields = new Set();
var types = new Map();
for (input of document.getElementsByTagName(\"input\")) {$FORM_SETUP
}"
    fi
    # DEBUG: echo "$JS_SCRIPT" >/tmp/qbvault_fill.js
    JS_SCRIPT=$(echo "$JS_SCRIPT" | tr '\n' ' ')
    echo "jseval -q $JS_SCRIPT" >>"$QUTE_FIFO"
  fi
)
