#!/bin/bash
###########################################################################################
#  @programe  : auto_setup_oracle.sh
#  @version   : 0.0.3
#  @function@ : Automatic oracle instance installation
#  @writer    : Huang Ling Fei
#  @date      : 2020-08-03
############################################################################################

PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
# Source function library.
. /etc/init.d/functions
#set -x 

export ECHO_STYLE_00="\033[0m"        # default style(black background, white foreground)
export ECHO_STYLE_01="\033[41;33;1m"  # red background, yellow foregound bold
export ECHO_STYLE_02="\033[45;37;5m"  # purple background, white foregound flicher
export ECHO_STYLE_03="\033[31;10m"    # red foregound flicker
export ECHO_STYLE_04="\033[36;5m"     # green mint foregound flicker
export ECHO_STYLE_05="\033[32;1m"     # green foregound bold
export ECHO_STYLE_06="\\033[31m"      # red
export ECHO_STYLE_07="\033[35m"       # purple
export ECHO_STYLE_08="\\033[45;30m"   # purple background, black foregound bold
export ECHO_STYLE_09="\\033[45m"      # purple background, white foregound bold
export ECHO_STYLE_10="\\033[44m"      # blue background, white foregound bold

if [ "`whoami`x" != "rootx" ];then
    echo -e "${ECHO_STYLE_03}Please run as root\n${ECHO_STYLE_00}"
    exit 1
fi

Datetime=`date +%F' '%T' '%u`
Oracle_SID="catadb"
#Ora_version="19.3.0"
Ora_version="11.2.0"
Grid_BASE="/u01/app/gridbase"
Grid_HOME="/u01/app/gridhome/product/${Ora_version}"
Grid_bash_profile="/home/grid/.bash_profile"
Oracle_BASE="/u01/app/oracle"
#Oracle_HOME="${Oracle_BASE}/product/${Ora_version}/db_1"
Oracle_HOME="${Oracle_BASE}/product/${Ora_version}/dbhome_1"
Oracle_data="/data/oradata"
Oracle_flashra="/data/flash_recovery_area"
OraInventory=/u01/app/oraInventory
Oracle_bash_profile="/home/oracle/.bash_profile"
Scriptpath="/data/scripts"

if [ ! -d $Scriptpath ];then
    mkdir -p $Scriptpath
fi

Logdir="oracle_logs"
Oracle_log="${Scriptpath}/${Logdir}/oracle.log"
if [ ! -d "${Scriptpath}/${Logdir}" ];then
   mkdir -p ${Scriptpath}/${Logdir}
fi

show_version(){
    echo "version: 0.0.1"
    echo "ceated date: 2020-08-03"
}

clean(){
echo
#rm $0
}

echoit(){
if [ $# -ne 2 ];then
    echo -e "${ECHO_STYLE_03}echoit color \"message\"${ECHO_STYLE_00}"
    exit 1
fi
Color="$1"
Msg="$2"
DateFormat="$(date +%Y-%m-%d\ %H:%M:%S)]"
if [ "${Color}x" == "yellowx" ];then
    echo -e "${ECHO_STYLE_01}${DateFormat} ${Msg}${ECHO_STYLE_00}" | tee -a $Oracle_log
elif [ "${Color}x" == "greenx" ];then
    echo -e "${ECHO_STYLE_05}${DateFormat} ${Msg}${ECHO_STYLE_00}" | tee -a $Oracle_log
elif [ "${Color}x" == "redx" ];then
    echo -e "${ECHO_STYLE_06}${DateFormat} ${Msg}${ECHO_STYLE_00}" | tee -a $Oracle_log
else
    echo -e "default color: ${ECHO_STYLE_10}${DateFormat} ${Msg}${ECHO_STYLE_00}" | tee -a $Oracle_log
fi
}

echo_col(){
if [ $# -eq 1 ];then
Len=$1
     echo -e `printf "%-${Len}s" "="|sed "s/ /=/g"`"\n"
else
    echoit "yellow" "Please use echo_col length"
    exit 1
fi
}

yumpkt(){
yum -y groupinstall "X Window System"
yum -y group install "General Purpose Desktop"
yum -y group install "GNOME Desktop"
yum -y group install "Development Tools"
yum -y group install "Compatibility Libraries"
yum -y install binutils-2.* compat-libstdc++-33* elfutils-libelf-0.* elfutils-libelf-devel-* \

gcc-4.* gcc-c++-4.* glibc-2.* glibc-common-2.* glibc-devel-2.* glibc-headers-2.* libaio-0.* libaio-devel-0.* \
libgcc-4.* libstdc++-4.* libstdc++-devel-4.* make-3.* sysstat-7.* unixODBC-2.* unixODBC-devel-2.* 
yum -y install binutils-2.* compat-libstdc++  elfutils-libelf-0.*  gcc-4.* gcc-c++-4.* \
glibc-2.* glibc-common-2.* glibc-devel-2.* glibc-headers-2.* libaio-0.* libaio-devel-0.* \
libgcc-4.* libstdc++-4.* libstdc++-devel-4.* make-3.* sysstat.* unixODBC-2.* unixODBC-devel-2.* 

yum -y install libXp xterm xorg-x11-xauth tree xterm xorg-x11-xauth libnsl.x86_64 libXtst smartmontools ksh
yum -y install -y bc compat-libcap1* compat-libcap* binutils compat-libstdc++-33 elfutils-libelf elfutils-libelf-devel \
gcc gcc-c++ glibc-2.5 glibc-common glibc-devel glibc-headers ksh libaio libaio-devel libgcc libstdc++ libstdc++-devel \
make sysstat unixODBC unixODBC-devel binutils* compat-libstdc* elfutils-libelf* gcc* glibc* ksh* libaio* libgcc* libstdc* \
make* sysstat* libXp* glibc-kernheaders net-tools-* compat-libstdc++* kmod-* vim tigervnc-server screen.x86_64

yum -y install  gcc gcc-c++ make binutils compat-libstdc++-33 compat-libcap1 \
elfutils-libelf elfutils-libelf-devel glibc  glibc-devel glibc-common  \
libaio libaio-devel libgcc libstdc++ libstdc++-devel expat \
pdksh ksh unixODBC unixODBC-devel tigervnc-server \
sysstat lrzsz screen dstat vim unzip rlwrap readline
yum -y install binutils-2.* compat-libstdc++-33* elfutils-libelf-0.* elfutils-libelf-devel-* \
gcc-4.* gcc-c++-4.* glibc-2.* glibc-common-2.* glibc-devel-2.* glibc-headers-2.* libaio-0.* libaio-devel-0.* \
libgcc-4.* libstdc++-4.* libstdc++-devel-4.* make-3.* sysstat-7.* unixODBC-2.* unixODBC-devel-2.* 
yum -y install binutils-2.* compat-libstdc++  elfutils-libelf-0.*  gcc-4.* gcc-c++-4.* glibc-2.* glibc-common-2.* \
glibc-devel-2.* glibc-headers-2.* libaio-0.* libaio-devel-0.* libgcc-4.* libstdc++-4.* libstdc++-devel-4.* make-3.* \
sysstat.* unixODBC-2.* unixODBC-devel-2.* 
yum -y install bc compat-libcap1* compat-libcap* binutils compat-libstdc++-33 elfutils-libelf \
elfutils-libelf-devel gcc gcc-c++ glibc-2.5 glibc-common \
glibc-devel glibc-headers ksh libaio libaio-devel libgcc libstdc++ libstdc++-devel \
make sysstat unixODBC unixODBC-devel binutils* compat-libstdc* elfutils-libelf* \
gcc* glibc* ksh* libaio* libgcc* libstdc* make* sysstat* libXp* glibc-kernheaders \
net-tools-* compat-libstdc++* kmod-* vim tigervnc-server screen.x86_64
yum -y install libXp xterm xorg-x11-xauth tree xterm xorg-x11-xauth libnsl.x86_64 libXtst smartmontools ksh
}

user_add(){
if [ $(egrep '^grid:' /etc/passwd|wc -l) -eq 0 ]&&[ $(egrep '^oracle:' /etc/passwd|wc -l) -eq 0 ];then
    groupadd -g 2000 asmdba
    groupadd -g 2001 asmadmin
    groupadd -g 2002 asmoper

    groupadd -g 3000 oinstall
    groupadd -g 3001 dba
    groupadd -g 3002 oper

    useradd -u 2000 -g oinstall -G dba,asmadmin,asmdba,asmoper -d /home/grid -s /bin/bash -c "grid Infrastructure Owner" grid 
    useradd -u 3000 -g oinstall -G dba,oper,asmdba -d /home/oracle -s /bin/bash -c "Oracle Software Owner" oracle 
    echo "xxx" | passwd --stdin oracle
    echo "xxx" | passwd --stdin grid
    echo_col 80
    id grid
    id oracle
    echo_col 80
else
    echoit "yellow" "The user of oracle or grid is exists"
    echo_col 80
    id grid
    id oracle
    echo_col 80
    echoit "yellow" "Do not continue installation"
    echoit "red" "Please clean up the grid and oracle accounts manually"
    exit 1
fi
}

syscfg(){
if ! egrep "^#set oracle" /etc/sysctl.conf >/dev/null;then
    cp /etc/sysctl.conf /etc/sysctl.conf`date +%F_%H`
    cat > /etc/sysctl.conf <<EOF

#set oracle
net.ipv4.ip_forward = 0
net.ipv4.conf.default.rp_filter = 1
net.ipv4.conf.default.accept_source_route = 0
kernel.sysrq = 0
kernel.core_uses_pid = 1
kernel.threads-max=65535
kernel.msgmni = 16384
kernel.msgmnb = 65535
kernel.msgmax = 65535
kernel.shmmax = 96636764160
kernel.shmall = 4294967296
kernel.shmmni = 4096
kernel.sem = 5010 641280 5010 128
net.ipv4.tcp_max_tw_buckets = 6000
net.ipv4.tcp_sack = 1
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216
net.core.wmem_default = 8388608
net.core.rmem_default = 8388608
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.core.netdev_max_backlog = 32768
net.ipv4.tcp_no_metrics_save = 1
net.core.somaxconn = 32768
net.core.optmem_max = 10000000
net.ipv4.tcp_max_orphans = 32768
net.ipv4.tcp_max_syn_backlog = 32768
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_timestamps = 0
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_syn_retries = 2
net.ipv4.tcp_tw_recycle = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_mem = 94500000 915000000 927000000
net.ipv4.tcp_fin_timeout = 10
net.ipv4.tcp_keepalive_time = 300
net.ipv4.tcp_keepalive_probes=10
net.ipv4.tcp_keepalive_intvl=2
net.ipv4.ip_local_port_range = 9000 65500
net.ipv4.route.gc_timeout = 100
net.ipv4.tcp_congestion_control=cubic
net.ipv4.conf.lo.arp_ignore = 1
net.ipv4.conf.lo.arp_announce = 2
net.ipv4.conf.all.arp_ignore = 1
net.ipv4.conf.all.arp_announce = 2
fs.aio-max-nr = 3145728
fs.file-max = 6815744
vm.swappiness = 1
vm.zone_reclaim_mode = 0
EOF
    sysctl -p
else
    echoit "red" "The sysctl.conf setting of oracle is exists"
fi

if ! egrep "^oracle" /etc/security/limits.conf >/dev/null;then
cat >> /etc/security/limits.conf <<EOF

#set oracle
oracle  soft  nproc    131072
oracle  hard  nproc    131072
oracle  soft  nofile   1024000
oracle  hard  nofile   1024000
oracle  soft  stack    unlimited
oracle  hard  stack    unlimited
oracle  soft  core     unlimited
oracle  hard  core     unlimited
oracle  soft  memlock  unlimited
oracle  hard  memlock  unlimited

EOF
else
    echoit "red" "The limits setting of oracle is exists in limits.conf"
fi

if ! egrep "^grid" /etc/security/limits.conf >/dev/null;then
cat >> /etc/security/limits.conf <<EOF

#set grid
grid  soft  nproc    131072
grid  hard  nproc    131072
grid  soft  nofile   1024000
grid  hard  nofile   1024000
grid  soft  stack    unlimited
grid  hard  stack    unlimited
grid  soft  core     unlimited
grid  hard  core     unlimited
grid  soft  memlock  unlimited
grid  hard  memlock  unlimited

EOF
else
    echoit "red" "The limits setting of grid is exists in limits.conf"
fi

if ! grep "pam_limits.so" /etc/pam.d/login >/dev/null;then
cat >> /etc/pam.d/login <<EOF
#oracle-set
session    required     pam_limits.so
session    required     /lib64/security/pam_limits.so
EOF
else
    echoit "red" "The pam_limits setting of oracle is exists"
fi

}

init(){
syscfg
user_add
if ! grep "ORACLE_SID=+ASM1" $Grid_bash_profile >/dev/null;then
cat >>$Grid_bash_profile << EOF

umask 022
export ORACLE_SID=+ASM1
export ORACLE_BASE=/u01/app/gridbase
export ORACLE_HOME=/u01/app/gridhome/product/${Ora_version}
export LD_LIBRARY_PATH=:\$ORACLE_HOME/lib:\$ORACLE_HOME/lib32
export LIBPATH=\$LD_LIBRARY_PATH
export PATH=\$JAVA_HOME/bin:\$ORACLE_HOME/bin:\$ORACLE_HOME/OPatch:/usr/bin:/etc:/usr/sbin:/usr/ucb:/usr/java5/bin:\$PATH
export PS1='\$LOGNAME@'`hostname`:'\$PWD''$ '
if [ -t 0 ]; then
   stty intr ^C
fi

EOF
else
    echoit "red" "The environment variable setting of grid is exists"
fi

if ! grep "ORACLE_BASE=" $Oracle_bash_profile >/dev/null;then
cat >>$Oracle_bash_profile << EOF

umask 022
export ORACLE_SID=$Oracle_SID
export ORACLE_BASE=/u01/app/oracle
export ORACLE_HOME=\$ORACLE_BASE/product/${Ora_version}/dbhome_1
export DB_HOME=\$ORACLE_HOME
export TNS_ADMIN=\$ORACLE_HOME/network/admin
#export NLS_LANG="Simplified Chinese_china.ZHS16GBK"
export NLS_LANG=AMERICAN_AMERICA.ZHS16GBK
export ORACLE_TERM=xterm
export BASE_PATH=/usr/sbin:\$PATH; 
export PATH=\$ORACLE_HOME/bin:\$BASE_PATH:/usr/local/bin; 
export LD_LIBRARY_PATH=\$ORACLE_HOME/lib:/lib:/usr/lib; 
export CLASSPATH=\$ORACLE_HOME/JRE:\$ORACLE_HOME/jlib:\$ORACLE_HOME/rdbms/jlib; 
stty erase ^h
alias sqlplus='rlwrap sqlplus'
alias rman='rlwrap rman'

EOF
else
    echoit "red" "The environment variable setting of oracle is exists"
fi

if ! grep -o '= "oracle" ] ||' /etc/profile >/dev/null;then
cat >>/etc/profile <<EOF

#set oracle
if [ \$USER = "oracle" ] || [ \$USER = "grid" ]; then
    if [ \$SHELL = "/bin/ksh" ]; then
        ulimit -p 16384
        ulimit -n 65536
    else
        ulimit -u 16384 -n 1024000
    fi
    umask 022
fi

EOF
else
    echoit "red" "The user of oracle or grid is exists in /etc/profile"
fi

if [ ! -d "${Grid_BASE}" ]&&[ ! -d "${Oracle_BASE}" ]&& [ ! -d "${Oracle_data}" ];then
    mkdir -p ${Grid_BASE}
    mkdir -p ${Grid_HOME}
    mkdir -p ${Oracle_BASE}
    mkdir -p ${OraInventory}
    chown -R grid:oinstall ${Grid_BASE}
    chown -R grid:oinstall ${Grid_HOME}
    chown -R grid:oinstall /u01/app/gridhome
    mkdir -p ${Oracle_HOME}
    mkdir -p ${Oracle_data}
    mkdir -p ${Oracle_flashra}
    chown -R oracle:oinstall ${Oracle_BASE}
    chown -R oracle:oinstall ${Oracle_HOME}
    chown -R oracle:oinstall ${Oracle_data}
    chown -R oracle:oinstall ${Oracle_flashra}
    chown -R oracle:oinstall ${OraInventory}
    chmod -R 755 ${Grid_BASE}
    chmod -R 755 ${Grid_HOME}
    chmod -R 755 ${Oracle_BASE}
    chmod -R 755 ${Oracle_HOME}
    chmod -R 755 ${Oracle_data}
    chmod -R 755 ${Oracle_flashra}
    chmod -R 755 ${OraInventory}
else
    echoit "red" "The path of ${Grid_BASE} or ${Oracle_BASE} or ${Oracle_data} is exists"
    echoit "yellow" "Do not continue installation"
    exit 1
fi
}

sshkey(){
Grid_home="/home/grid"
Key_path="${Grid_home}/.ssh"
if [ $(egrep '^grid:' /etc/passwd|wc -l) -eq 1 ]&& [ -d ${Grid_home} ];then
    if [ ! -f ${Key_path}/id_dsa ];then
    su - grid -c "ssh-keygen -t dsa -P 'xxx' -f ${Key_path}/id_dsa"
    su - grid -c "cat ${Key_path}/id_dsa.pub >>${Key_path}/authorized_keys"
    su - grid -c "chmod 600 ${Key_path}/authorized_keys"
    else
        echoit "red" "The ${Key_path}/id_dsa is exists"
    fi
else
    echoit "red" "The user of grid is not exists"
    echoit "yellow" "ssh-keygen failure"
    exit 1
fi
}

yumpkt
init
sshkey
