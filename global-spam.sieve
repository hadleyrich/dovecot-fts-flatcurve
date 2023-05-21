require ["fileinto", "mailbox", "spamtest", "relational", "comparator-i;ascii-numeric"];

if spamtest :value "ge" :comparator "i;ascii-numeric" "10" {
  fileinto :create "Junk";
  stop;
}

if header :contains "X-Spam" "Yes" {
    fileinto :create "Junk";
}

