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
* a bunch of utils any modern Unix OS has (`sh`, `sed`, `grep`, ecc.)

I've tested these scripts in *FreeBSD*.
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

Run the following commands in *qutebrowser*:

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

The number of commands shown depends on the number of forms contained in
the page -- choose the one relevant to you.
You may also run them all, should you need to fill all the forms.

If it is the first time you run `qbvault.sh`, you will be asked to enter
(twice) a passphrase to create a new keystore.
Else it may ask you to enter (once) the passphrase to unlock the
keystore.
The script then will ask you to enter the values for all the input
fields, in turn.

> **NOTE**: Hidden and submit fields are ignored.

If you don't want to specify a value for some field, just leave it blank
and press `Enter` (or the `OK` button).
Should you regret your deeds, you can abort the command -- and leave the
keystore untouched -- by pressing the `Cancel` button.

When is time to fill-up those forms, just open the login/forms page and
press `pf` (or whatever you chose).
You may be asked again to enter (once) the passphrase to unlock the
keystore.
How often you have to enter the passphrase depends on your configuration
of the *GNU Privacy Guard*.

Shortcomings
------------
There are several reasons for the scripts to fail.
The following are a few cases I stumbled on while testing them:

* if the login form is loaded inside an `<iframe/>` from a different
  domain name than the main page, the `add_credentials.sh` script will
  be unable to access the forms
* if the fields in the forms are renamed, `fill_credentials.sh` will be
  unable to find and fill them
* if there are no forms, the scripts will be unable to work -- a few
  sites out there make use of Javascript to store the data in variables
  and then invoke the login service via AJAX

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

Four commands are available:

```
qbvault.sh add *page_url* *form_action_url* [*field_name* *field_label*]...
qbvault.sh read [*page_url*]
qbvault.sh remove *page_url* [*form_action_url*]
qbvault.sh updatepassword
```

To `add` new entries, you must specify:

* the URL of the page containing the forms to fill (*page_url*)
* the URL in the action attribute of the form (*form_action_url*) --
  this is used to identify the form to fill
* and for each field to fill:

  * the value of the name attribute of the input element inside the form
    (*field_name*)
  * the label assigned to the input element (*field_label*) -- this is
    only used to show the user a user-friendly name; if empty the value
    of *field_name* will be used instead

To `read` the entries in the keystore, you may specify the URL of the
page (*page_url*) whose entries should be read.
If no URL is specified, all the entries are read.

To `remove` entries from the keystore, you must specify the URL of the
page (*page_url*) whose entries must be removed.
Optionally, you may remove only the entries of a specific form
specifying its action URL (*form_action_url*).

Finally, the `updatepassword` command allows you to change the
passphrases used to encrypt `qbkey.gpg` and `qbvault.gpg`.

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
