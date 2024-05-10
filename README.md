Password manager for qutebrowser
================================
These are a few scripts meant to be used with *qutebrowser* to fill
forms for you.
The most frequent use is to fill login forms with usernames and
passwords, but you can use them to put in the forms whatever information
you like.

Requirements
------------
The scripts require:

* the *GNU Privacy Guard* suite (actually, `gpg2`, `gpg-agent` and
  `gpg-connect-agent`)
* `sha256`
* a bunch of utils any modern Unix OS has (`sh`, `sed`, `grep`, etc.)

I've tested these scripts on *FreeBSD*.
With other OSes you may need to tweak them: e.g., in *Linux*
distributions the `sha256` utility is usually called `sha256sum`.

Configuration
-------------
Copy the three scripts, `add_credentials.sh`, `fill_credentials.sh` and
`qbvault.sh` somewhere.

Put a symbolic link in your PATH pointing to the `qbvault.sh` script.

> **NOTE**: Keep `qbvault.sh` and `fill_credentials.sh` in the same
> directory, as `fill_credentials.sh` needs to find `qbvault.sh` for
> its operation.

Run (once) the following commands in *qutebrowser*:

```
:bind pa spawn --userscript /path/to/add_credentials.sh
:bind pf spawn --userscript /path/to/fill_credentials.sh
```

Substitute `/path/to/` with the correct location of the scripts.

> **NOTE**: You may use whatever key bindings you like, instead of `pa`
> and `pf`.

Then save the *qutebrowser* configuration (unless you have autosave
active).

Usage
-----
When you want to store new credentials (or other information) to fill
the forms with, open the login page (or whatever page has the forms) and
press `pa` (or whatever key binding you chose to use).

The page will be updated with a list of commands (i.e., `qbvault.sh`) to
copy, paste in a terminal and run.

> **NOTE**: To restore the page, just reload it -- don't move back in
> history.

For each form, a `qbvault.sh` command will be prepared -- choose the
one(s) relevant to you.

If it is the first time you run `qbvault.sh`, you will be asked to enter
twice a passphrase to create a new keystore.
Else it may ask you to enter (once) the passphrase to unlock the
keystore.
The script then will ask you to enter the values for all the input
fields, in turn.

> **NOTE**: Hidden and submit input fields are ignored.

If you don't want to specify a value for some field, just leave it blank
and press `Enter` (or the `OK` button).
Should you regret your deeds, you can abort the command -- and leave the
keystore untouched -- by pressing the `Cancel` button.

When is time to fill-up those forms, just open the login/forms page and
press `pf` (or whatever you chose).
You may be asked again to enter (once) the passphrase to unlock the
keystore.
How often you have to enter the passphrase depends on your configuration
of `gpg-agent`'s `default-cache-ttl` option (see `gpgconf(1)`).

Shortcomings
------------
There are several reasons for the scripts to fail.
The following are a few cases I stumbled on while testing them:

* if the login form is loaded inside an `<iframe/>` from a different
  domain name than the main page, the `add_credentials.sh` script will
  be unable to access the forms
* if the fields in the forms are renamed by a site update,
  `fill_credentials.sh` will be unable to find and fill them (or may
  fill the wrong ones)
* there are sites out there that make use of *Javascript* to read the
  data from the input fields when events are fired -- although the
  scripts may be able to fill the input fields, the *Javascript* code
  may not be triggered making it assume that no data were entered

If you stumble in sites like the ones described in the last point, try
adding a char to the scripts-inserted value and then deleting it.

> **NOTE:** I've tried to fake those events, but it looks like the
> *Javascript* in those sites check for the `isTrusted` attribute, which
> synthesized events lack.

qbvault.sh
----------
The `qbvault.sh` script is used to create, read or modify the keystore.

The keystore is made of two files `qbkey.gpg` and `qbvault.gpg`,
located, by default, in the `~/.config` directory.

It is split in two parts to avoid specifying a new passphrase (twice)
every time new entries are added: every time `gpg2` encrypts
`qbvault.gpg` it needs a new passphrase, which you must enter, twice.
If, however, the passphrase is read from another file (i.e.,
`qbkey.gpg`), you will be asked to enter the passphrase (to decrypt
`qbkey.gpg`) only once.

Four operations are available -- add (`-A`), read (`-R`), delete (`-D`)
and update password (`-U`):

```
qbvault.sh -A -u <page_url> [-a <form_action_url>]
           {{-n <field_name> | -L <field_label> |
             -h <placeholder> | -i <dom_element_id> |
             -t <input_type>} [-p <field_value> |
                               -l <field_description> |
                               -c <command> [-p <command_argument> |
                                             -l <argument_description>] ...]} ...
qbvault.sh -R [-u <page_url> [-r]]
qbvault.sh -D -u <page_url> [-a <form_action_url>]
qbvault.sh -U
```

To add (`-A`) new entries, you must specify:

* the URL of the page containing the forms to fill (`-u <page_url>`)
* the URL in the action attribute of the form (`-u <form_action_url>`)
  -- this is used to identify the form to fill
* and for each field to fill, the name of the field (`-n <field_name>`),
  its label (`-L <field_label>`), placeholder (`-h <placeholder>`), DOM
  id (`-i <dom_element_id>`) or "enumerated type" (`-t <input_type>`,
  see below), and:

  * the value of the field (`-p <field_value>`), or
  * the description to be shown to the user by `gpg-agent`
    (`-l <field_description>`) -- if empty `<field_name>` will be used
    instead, or
  * the command to run to compute the value to be used for the field
    (`-c <command>`) and
  * the (optional) arguments for the command (`-p <command_argument>`
    and `-l <argument_description>`)

> **NOTE**: If the page at the specified URL has no forms but only input
> fields, use `x` as the value for `<form_action_url>`, i.e., `-a x`.

The "enumerated type" is *only* used to reference those input field that
cannot otherwise be referenced.
It may seem pointless to have fields in a form without name, label,
placeholder or id, yet there are several sites out there with such
"unreferentiable" fields.

So, to deal with such fields, we reference them by type.
However, what do we do if there are more than one unreferentiable input
fields of the same type?
We append a suffix made of a "#" (number sign) followed by an ordinal
number.
For example, say we have three unreferentiable text input fields.
The first will be referenced by `-t text`, the second by `-t "text#2"`,
and the third by `-t "text#3"`.

Remember, this apply only to unreferentiable input fields.
All the other fields must be referenced by name, label, placeholder or
id.

> **NOTE:** The `-t` option is a last resort to deal with badly written
> input forms -- if your browser is not consistent in traversing the DOM
> tree or if the fields are rearranged, the scripts may reference the
> wrong fields.

Use the `-l` option to pass sensitive data, e.g., password, credit card
numbers and the like.
Use `-p` for non-sensitive ones.
Or use `-c` if the value is dynamic and can/must be computed by running
a script or command (e.g., OTP tokens).
If the value is dynamic but cannot be computed, then I guess you should
ignore the field in question and just skip it.

When `-l` is used, `gpg-agent` will be invoked to ask the user to enter
the sensitive data.
The parameter passed to `-l` is a *label* to be shown to the user in the
input form.

When `-p` is used, you pass it the actual value for the field.
As values specified through the `-p` option are visible to anyone
executing a simple `ps`, you should use it only for non-sensitive data.

When a command is used to fill the field, only the first line returned
in its standard output will be used.
Everything else returned is ignored.
Standard error will pass-through to `qbvault.sh` standard error output.

As for the command arguments, they are specified by means of the `-l`
and `-p` options.
Everything said above about the `-l` and `-p` options, apply to the
command arguments as well, with the addition of the following notes:

* multiple `-p` and `-l` can be specified
* arguments specified by means of the `-p` option are passed to the
  command as command-line arguments, in the same order as specified to
  `qbvault.sh` (thus, thery are visible in `ps`'s output)
* arguments collected by means of the `-l` option are passed to the
  command through its standard input, one per line (i.e., separated by
  new-lines), in the same order as specified to `qbvault.sh` (thus, they
  are **not** visible in `ps`'s output)

> **NOTE**: The `qbvault.sh` sample commands generated by the
> `add_credentials.sh` script will only use the `-l` option to fill the
> fields.
> So you can just copy and paste them and they will work fine, whether
> the fields require sensitive data or not.
> However, if one or more fields require dynamic values you can compute,
> then substitute the `-l` option with an apt `-c` option (and
> corresponding `-l`/`-p` option(s) for the arguments).
> Delete the `-n` and `-l` options of the fields you don't bother to
> fill or whose dynamic value cannot be computed.

To read (`-R`) the entries in the keystore, you may specify the URL of
the page (`-u <page_url>`) whose entries should be read.

When reading the entries for a specific URL, `qbvault.sh` will invoke
any command present in the field specifications and return the computed
values.
To show the commands themselves, add `-r` (raw).

If no URL is specified, all the entries are read, but, in this case, an
implicit `-r` is assumed.

To remove (`-D`) entries from the keystore, you must specify the URL of
the page (`-u <page_url>`) whose entries must be removed.
Optionally, you may remove only the entries of a specific form
specifying its action URL (`-a <form_action_url>`).

The last operation, `-U`, allows you to change the passphrases used to
encrypt `qbkey.gpg` and `qbvault.gpg`.

Note that you will be only prompted to enter `qbkey.gpg`'s passphrase.
`qbvault.gpg`'s passphrase -- that is, the content of `qbkey.gpg` -- is
randomly generated by `qbvault.sh`.

License
-------
qbvault - Password manager for qutebrowser

Written in 2020 by Francesco Lattanzio <franz.lattanzio@gmail.com>

To the extent possible under law, the author have dedicated all
copyright and related and neighboring rights to this software to the
public domain worldwide. This software is distributed without any
warranty.

You should have received a copy of the CC0 Public Domain Dedication
along with this software.
If not, see <http://creativecommons.org/publicdomain/zero/1.0/>.
