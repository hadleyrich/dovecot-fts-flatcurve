require ["vnd.dovecot.pipe", "copy", "imapsieve", "environment", "variables"];

if environment :matches "imap.mailbox" "*" {
  set "mailbox" "${1}";
}

if string :matches "${mailbox}" ["*/Trash", "Trash"] {
  stop;
}

if environment :matches "imap.user" "*" {
  set "username" "${1}";
}

pipe :copy "rspamc" ["-h", "rspamd:11334", "-P", "/etc/dovecot/rspamd-controller.password", "-d", "${username}", "learn_ham"];
