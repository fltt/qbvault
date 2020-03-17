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
    var inputs = document.getElementsByTagName(\"input\");
    var nfields = 0;
    for (var j = 0; j < inputs.length; ++j) {
        var input = inputs[j];
        if ((input.type != \"hidden\") && (input.type != \"submit\") && (input.name != null) && (input.name != \"\"))
            ++nfields;
    }
    if (nfields > 0) {
        ncommands = 1;
        fields_list += \"<pre>qbvault.sh -A -u \\\"$URL\\\" -a x\";
        for (var j = 0; j < inputs.length; ++j) {
            var input = inputs[j];
            if ((input.type == \"hidden\") || (input.type == \"submit\") || (input.name == null) || (input.name == \"\"))
                continue;
            fields_list += \" -n \\\"\";
            var name = input.name.replace(/([\\\\\"\$])/g, \"\\\\\$1\");
            fields_list += name;
            fields_list += \"\\\" -l '\";
            if (input.labels && (input.labels.length > 0))
                fields_list += escape(input.labels[0].innerText);
            fields_list += \"'\";
        }
        fields_list += \"</pre>\";
    }
} else {
    for (var i = 0; i < forms.length; ++i) {
        var form = forms[i];
        var inputs = form.getElementsByTagName(\"input\");
        var nfields = 0;
        for (var j = 0; j < inputs.length; ++j) {
            var input = inputs[j];
            if ((input.type != \"hidden\") && (input.type != \"submit\") && (input.name != null) && (input.name != \"\"))
                ++nfields;
        }
        if (nfields == 0)
            continue;
        ++ncommands;
        if (ncommands > 1)
            fields_list += \"<p>Command \" + ncommands + \":</p>\";
        fields_list += \"<pre>qbvault.sh -A -u \\\"$URL\\\" -a \\\"\";
        fields_list += form.action.split(\"?\")[0].replace(/([\\\\\"\$])/g, \"\\\\\$1\");
        fields_list += \"\\\"\";
        for (var j = 0; j < inputs.length; ++j) {
            var input = inputs[j];
            if ((input.type == \"hidden\") || (input.type == \"submit\") || (input.name == null) || (input.name == \"\"))
                continue;
            fields_list += \" -n \\\"\";
            var name = input.name.replace(/([\\\\\"\$])/g, \"\\\\\$1\");
            fields_list += name;
            fields_list += \"\\\" -l '\";
            if (input.labels && (input.labels.length > 0))
                fields_list += escape(input.labels[0].innerText);
            fields_list += \"'\";
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
