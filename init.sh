#!/bin/bash
# author: honway.liu
# mail: gm100861@gmail.com
# blog: http://www.gm100861.com
# date: 2013-06-25
if [ $(id -u) != 0 ];then
echo "Must be root can do this."
exit 9
fi

# set privileges
chmod 600 /etc/passwd
chmod 600 /etc/shadow
chmod 600 /etc/group
chmod 600 /etc/gshadow
echo "Set important files privileges sucessfully"

#close ctrl+alt+del
sed -i "s/ca::ctrlaltdel:\/sbin\/shutdown -t3 -r now/#ca::ctrlaltdel:\/sbin\/shutdown -t3 -r now/" /etc/inittab
sed -i 's/^id:5:initdefault:/id:3:initdefault:/' /etc/inittab

#close ipv6
echo "alias net-pf-10 off" >> /etc/modprobe.conf
echo "alias ipv6 off" >> /etc/modprobe.conf
/sbin/chkconfig --level 35 ip6tables off
echo -e "\033[031m ipv6 is disabled.\033[0m"

#shutdown SELinux
sed -i '/SELINUX/s/enforcing/disabled/' /etc/selinux/config
echo -e "\033[31m selinux is disabled,if you need,you must reboot.\033[0m"

sed -i "8 s/^/alias vi='vim'/" /root/.bashrc
echo 'syntax on' > /root/.vimrc

#update yum source
mv -f /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.backup
curl -s http://mirrors.163.com/.help/CentOS6-Base-163.repo -o /etc/yum.repos.d/CentOS-Base.repo
yum clean all
yum makecache

#install common software
yum -y install openssh-clients man wget yum-utils vim-enhanced lrzsz telnet traceroute glibc-headers gcc make autoconf libtool automake gcc-c++ openssl openssl-devel unzip zip lrzsz openssl openssl-devel pcre pcre-devel gcc make automake vim

# Turn off unnecessary services

service=($(ls /etc/init.d/))
for i in ${service[@]}; do
case $i in
sshd|network|syslog|crond)
chkconfig $i on;;

*)
chkconfig $i off;;
esac
done

#set ulimit
cat >> /etc/security/limits.conf << EOF
* soft nofile 165535
* hard nofile 165535
EOF

# set sysctl
cat > /etc/sysctl.conf << EOF
net.ipv4.ip_forward = 0
net.ipv4.conf.default.rp_filter = 1
net.ipv4.conf.default.accept_source_route = 0
kernel.sysrq = 0
kernel.core_uses_pid = 1
kernel.msgmnb = 65536
kernel.msgmax = 65536
kernel.shmmax = 68719476736
kernel.shmall = 4294967296
net.ipv4.tcp_max_tw_buckets = 6000
net.ipv4.tcp_sack = 1
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_rmem = 4096 87380 4194304
net.ipv4.tcp_wmem = 4096 16384 4194304
net.core.wmem_default = 8388608
net.core.rmem_default = 8388608
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.core.netdev_max_backlog = 262144
net.core.somaxconn = 262144
net.ipv4.tcp_max_orphans = 3276800
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_max_syn_backlog = 262144
net.ipv4.tcp_timestamps = 0
net.ipv4.tcp_synack_retries = 1
net.ipv4.tcp_syn_retries = 1
net.ipv4.tcp_tw_recycle = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_mem = 94500000 915000000 927000000
net.ipv4.tcp_fin_timeout = 1
net.ipv4.tcp_keepalive_time = 1200
net.ipv4.ip_local_port_range = 1024 65535
vm.swappiness = 0
EOF

echo "0 0 * * * /usr/sbin/ntpdate cn.pool.ntp.org &>/dev/null" >>/var/spool/cron/root

echo "All things is init ok! "
