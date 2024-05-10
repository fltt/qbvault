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

URL=$(echo "$QUTE_URL" | sed -e 's,^\([^?]*\)?.*$,\1,' | sed -e 's,\([\"$]\),\\\1,g')
JS_SCRIPT="\
var ncommands = 0;
var forms = document.getElementsByTagName(\"form\");
var fields_list = \"\";
if (forms.length == 0) {
    var fields = new Map();
    var types = new Map();
    for (input of document.getElementsByTagName(\"input\")) {
        if ((input.type == \"hidden\") || (input.type == \"submit\"))
            continue;
        if ((input.name != null) && (input.name != \"\") && !fields.has([\"n\", input.name])) {
            var label = \"\";
            if ((input.labels != null) && (input.labels.length > 0) && (input.labels[0].innerText != null))
                label = input.labels[0].innerText;
            if ((label == \"\") && (input.placeholder != null) && (input.placeholder != \"\"))
                label = input.placeholder;
            fields.set([\"n\", input.name], label);
        } else if ((input.labels != null) && (input.labels.length > 0) && (input.labels[0].innerText != null) && (input.labels[0].innerText != \"\") && !fields.has([\"L\", input.labels[0].innerText])) {
            fields.set([\"L\", input.labels[0].innerText], \"\");
        } else if ((input.placeholder != null) && (input.placeholder != \"\") && !fields.has([\"h\", input.placeholder])) {
            fields.set([\"h\", input.placeholder], \"\");
        } else if ((input.id != null) && (input.id != \"\") && !fields.has([\"i\", input.id])) {
            fields.set([\"i\", input.id], \"\");
        } else {
            var type = input.type;
            if ((type == null) || (type == \"\"))
                type = \"text\";
            if (!types.has(type))
                types.set(type, 1);
            var label = type + \" field\";
            var count = types.get(type);
            types.set(type, count + 1);
            if (count > 1) {
                type += \"#\" + count;
                label += \" number \" + count;
            }
            fields.set([\"t\", type], label);
        }
    }
    if (fields.size > 0) {
        ncommands = 1;
        fields_list += \"<pre>qbvault.sh -A -u \\\"$URL\\\" -a x\";
        for (type_and_name of fields.keys()) {
            var label = fields.get(type_and_name);
            fields_list += \" -\";
            fields_list += type_and_name[0];
            fields_list += \" \\\"\";
            fields_list += type_and_name[1].replace(/([\\\\\"\$])/g, \"\\\\\$1\");
            fields_list += \"\\\"\";
            if (label != \"\") {
                fields_list += \" -l '\";
                fields_list += escape(label);
                fields_list += \"'\";
            }
        }
        fields_list += \"</pre>\";
    }
} else {
    for (form of forms) {
        var fields = new Map();
        var types = new Map();
        for (input of form.getElementsByTagName(\"input\")) {
            if ((input.type == \"hidden\") || (input.type == \"submit\"))
                continue;
            if ((input.name != null) && (input.name != \"\") && !fields.has([\"n\", input.name])) {
                var label = \"\";
                if ((input.labels != null) && (input.labels.length > 0) && (input.labels[0].innerText != null))
                    label = input.labels[0].innerText;
                if ((label == \"\") && (input.placeholder != null) && (input.placeholder != \"\"))
                    label = input.placeholder;
                fields.set([\"n\", input.name], label);
            } else if ((input.labels != null) && (input.labels.length > 0) && (input.labels[0].innerText != null) && (input.labels[0].innerText != \"\") && !fields.has([\"L\", input.labels[0].innerText])) {
                fields.set([\"L\", input.labels[0].innerText], \"\");
            } else if ((input.placeholder != null) && (input.placeholder != \"\") && !fields.has([\"h\", input.placeholder])) {
                fields.set([\"h\", input.placeholder], \"\");
            } else if ((input.id != null) && (input.id != \"\") && !fields.has([\"i\", input.id])) {
                fields.set([\"i\", input.id], \"\");
            } else {
                var type = input.type;
                if ((type == null) || (type == \"\"))
                    type = \"text\";
                if (!types.has(type))
                    types.set(type, 1);
                var label = type + \" field\";
                var count = types.get(type);
                types.set(type, count + 1);
                if (count > 1) {
                    type += \"#\" + count;
                    label += \" number \" + count;
                }
                fields.set([\"t\", type], label);
            }
        }
        if (fields.size == 0)
            continue;
        ++ncommands;
        if (ncommands > 1)
            fields_list += \"<p>Command \" + ncommands + \":</p>\";
        fields_list += \"<pre>qbvault.sh -A -u \\\"$URL\\\" -a \\\"\";
        fields_list += form.action.split(\"?\")[0].replace(/([\\\\\"\$])/g, \"\\\\\$1\");
        fields_list += \"\\\"\";
        for (type_and_name of fields.keys()) {
            var label = fields.get(type_and_name);
            fields_list += \" -\";
            fields_list += type_and_name[0];
            fields_list += \" \\\"\";
            fields_list += type_and_name[1].replace(/([\\\\\"\$])/g, \"\\\\\$1\");
            fields_list += \"\\\"\";
            if (label != \"\") {
                fields_list += \" -l '\";
                fields_list += escape(label);
                fields_list += \"'\";
            }
        }
        fields_list += \"</pre>\";
    }
}
if (ncommands > 0) {
    var header;
    if (ncommands > 1) {
        header = \"<p>Run one (or more) of the following commands.</p>\";
        header += \"<p>Command 1:</p>\";
    } else {
        header = \"<p>Run the following command:</p>\";
    }
    document.open().write(\"<html><body>\" + header + fields_list + \"</body></html>\");
} else {
    alert(\"No input fields found.\");
}"

JS_SCRIPT=$(echo "$JS_SCRIPT" | tr '\n' ' ')

echo "jseval -q $JS_SCRIPT" >>"$QUTE_FIFO"
