#!/bin/bash

echo "Installiere Figlet und LSB-Release"
apt-get install lsb-release figlet -y

echo "Erstelle /etc/update-motd.d/"
mkdir /etc/update-motd.d/
cd /etc/update-motd.d

echo "Erstelle die dynmischen Dateien"
echo ""

echo "Erstelle 00-header"
cat > 00-header <<'_EOF'
#!/bin/sh
[ -r /etc/lsb-release ] && . /etc/lsb-release
if [ -z "$DISTRIB_DESCRIPTION" ] && [ -x /usr/bin/lsb_release ]; then
# Fall back to using the very slow lsb_release utility
DISTRIB_DESCRIPTION=$(lsb_release -s -d)
fi
figlet $(hostname)
printf "\n"
printf "Welcome to %s (%s).\n" "$DISTRIB_DESCRIPTION" "$(uname -r)"
printf "\n"
_EOF

echo "Erstelle 10-sysinfo"
cat > 10-sysinfo <<'_EOF'
#!/bin/bash
date=`date`
load=`cat /proc/loadavg | awk '{print $1}'`
root_usage=`df -h / | awk '/\// {print $(NF-1)}'`
memory_usage=`free -m | awk '/Mem:/ { total=$2 } /buffers\/cache/ { used=$3 } END { printf("%3.1f%%", used/total*100)}'`
swap_usage=`free -m | awk '/Swap/ { printf("%3.1f%%", "exit !$2;$3/$2*100") }'`
users=`users | wc -w`
time=`uptime | grep -ohe 'up .*' | sed 's/,/\ hours/g' | awk '{ printf $2" "$3 }'`
processes=`ps aux | wc -l`
ip=`ifconfig $(route | grep default | awk '{ print $8 }') | grep "inet addr" | awk -F: '{print $2}' | awk '{print $1}'`
echo "System information as of: $date"
echo
printf "System load:\t%s\tIP Address:\t%s\n" $load $ip
printf "Memory usage:\t%s\tSystem uptime:\t%s\n" $memory_usage "$time"
printf "Usage on /:\t%s\tSwap usage:\t%s\n" $root_usage $swap_usage
printf "Local Users:\t%s\tProcesses:\t%s\n" $users $processes
echo
_EOF

echo "Erstelle 99-footer"
cat > 90-footer <<'_EOF'
#!/bin/sh
[ -f /etc/motd.tail ] && cat /etc/motd.tail || true
_EOF

echo "Mache alle 3 Dateien ausführbar"
chmod +x 00-header
chmod +x 10-sysinfo
chmod +x 90-footer

echo "Verschiebe /etc/motd zu /etc/motd.old"
mv /etc/motd /etc/motd.old

echo "Erstelle Symlink zur neuen dynamischen Motd"
ln -s /var/run/motd /etc/motd