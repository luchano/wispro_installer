#!/usr/bin/expect
set timeout 3600
spawn setup-alpine -f /etc/wispro/answers
#spawn ./expect-test.sh
expect {
 "New password:" { send "root\r"; exp_continue }
 "Retype password:" { send "root\r"; exp_continue }
 "WARNING: Erase the above disk(s) and continue?*" { send "y\r"; exp_continue }
 "Proceed anyway? (y,N)" { send "y\r"; exp_continue }
 "Installation is complete. Please reboot." exit
}




