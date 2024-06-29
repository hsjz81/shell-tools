#!/bin/bash
###########################################################################################
#  @programe  : auto_setup_mysql.sh
#  @version   : 0.0.5
#  @function@ : Automatic MySQL multi instance installation
#  @writer    : Huang Ling Fei
#  @date : 2017-05-26
############################################################################################

PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
# Source function library.
. /etc/init.d/functions
export ECHO_STYLE_00="\033[0m"        # default style(black background, white foreground)
export ECHO_STYLE_01="\033[41;33;1m"  # red background, yellow foregound bold
export ECHO_STYLE_02="\033[45;37;5m"  # purple background, white foregound flicher
export ECHO_STYLE_03="\033[31;5m"     # red foregound flicker
export ECHO_STYLE_04="\033[36;5m"     # green mint foregound flicker
export ECHO_STYLE_05="\033[32;1m"     # green foregound bold
export ECHO_STYLE_06="\\033[31m"      # red
export ECHO_STYLE_07="\033[35m"       # purple
export ECHO_STYLE_08="\\033[45;30m"   # purple background, black foregound bold
export ECHO_STYLE_09="\\033[45m"      # purple background, white foregound bold
export ECHO_STYLE_10="\\033[44m"      # blue background, white foregound bold

mysqlpath="/app/mysql/bin"
mysqlbasedir="/app/mysql"
initmysqldata="/data/mysqldata.init"

checkinfo(){
scriptpath="/usr/local/scripts"
if [ ! -d $scriptpath ];then
    mkdir -p $scriptpath
fi
wget -q -t 2 -T 3 http://tools-dba.xxx/script/dbascript/showinfo.sh -O /usr/local/scripts/showinfo.sh 
sh /usr/local/scripts/showinfo.sh $Check
}

initmysql(){
datadir="/data"
softpath="/data/soft/"
if [ -d /home/mysql ]&& id mysql >/dev/null;then
    echo -e "The mysql account or the mysql home already exist\n"
else
    useradd mysql
fi
if [ -z "`mount|awk '/\/data/'`" ]&&[ ! -L "${datadir}" ];then
    if [ ! -d "${datadir}" ]&&[ -n "`mount|awk '/\/app/'`" ];then
        mkdir -p /app/data
        ln -s /app/data/ /data
    else
        echo "${datadir} is a directory or app not mount on disk please check it"
        exit 1
    fi
else
    echo  "${datadir} mount on disk or exsist a symbolic link"
fi

getconf(){
scriptpath="/usr/local/scripts"
mysql_pktconf="mysql-versionl-list"
if [ ! -d $scriptpath ];then
    mkdir -p $scriptpath
fi
mypktconf_url="http://tools-dba.xxx/dbasoft/MySQL/${mysql_pktconf}"
testcode=$(wget -S ${mypktconf_url} -O ${scriptpath}/${mysql_pktconf} 2>&1|grep -i -oP '(?<=HTTP/[0-9].[0-9]\s)[0-9]{3}(?=\s.*)')
if [ ${testcode} -ne 200 ];then
    echo "download config file is error and code:${testcode}"
    exit 1
fi
}
getconf

Tmpfile=`mktemp`
awk -F'[ \t]+' '{if(!NF || /^#/){next} else if (match($1 , /^\[([a-zA-Z].*)\]/, arry)){v=arry[1]} else {print v,$NF}}' ${mysql_pktconf} > ${Tmpfile}

declare -A dbinfo
getdbinfo(){
while read line
    do
        key=$(echo $line|awk -F'[ ]+' '{print$1}')
        value=$(echo $line|awk -F'[ ]+' '{print$2}')
        if [ -n "${key}" -a -n "${value}" ];then
            dbinfo+=([${key}]="${value},")
        fi
    done<${Tmpfile}
mkdir -p /tmp/temp
cd /tmp/temp
rm ${Tmpfile}
}
getdbinfo

select_mysqlv(){
mysqlv_arr=(${!dbinfo[@]})
for i in ${!mysqlv_arr[@]}
    do  
        echo -e ${ECHO_STYLE_05}${i}${ECHO_STYLE_00}"):"${mysqlv_arr[$i]}
    done
echo -e ${ECHO_STYLE_05}q${ECHO_STYLE_00}"):"exit
}

get_mysqlpkt(){
key=$1
value=${dbinfo[$key]}
value_length=${#dbinfo[$key]}
if [ ${value_length} -ne 0 ];then
    mysqlpkt_arr=(${dbinfo[${key}]//,/ })
    for i in ${!mysqlpkt_arr[@]}
        do
            echo -e ${ECHO_STYLE_05}${i}${ECHO_STYLE_00}"):"${mysqlpkt_arr[$i]}
        done
    echo -e "${ECHO_STYLE_05}q${ECHO_STYLE_00}):exit"
    echo -e "${ECHO_STYLE_05}b${ECHO_STYLE_00}):Go back to your superior and re-select the mysql version"
else
    echo -e "\n===please check key name: $key $value===\n"
fi
}

choise_mysql(){
while true
    do
        select_mysqlv
        echo -e "\n####Please select the version number of MySQL package####"
        read -p ":" select_mysqlv
        case $select_mysqlv in
             [0-9]*) 
                 if [ $select_mysqlv -le ${#mysqlv_arr[@]} ];then
                 mysql_pkt=""
                 while true
                     do
                         mysql_vname=${mysqlv_arr[$select_mysqlv]}
                         echo "Select MySql_vname: ==${mysql_vname}=="
                         if [ -z "$mysql_pkt" -a -n "$mysql_vname" ];then
                             get_mysqlpkt $mysql_vname
                             echo -e  "\n####Please select the file number of MySQL package####"
                             read -p ":" select_mysqlpkt
                             case $select_mysqlpkt in 
                                  [0-9]*) 
                                      if [ $select_mysqlpkt -le ${#mysqlpkt_arr[@]} ];then
                                          mysql_pkt=${mysqlpkt_arr[$select_mysqlpkt]}
                                      else
                                          echo -e "\n==== you input ${select_mysqlpkt} please enter less than ${#mysqlpkt_arr} number====\n"
                                          echo -e "Please choose again......\n"
                                      fi
                                      ;; 
               
                                  q|Q) 
                                      echo -e "you select q to exit........\n"
                                      exit 1
                                      ;; 
                                  b|B) 
                                      echo -e "you select b Go back to your superior and re-select the  mysql package version........\n"
                                      break 1
                                      ;; 
                                  *) 
                                     echo -e "please choise the number of mysql package\n"
                                     ;;
                             esac    
                         else
                             linux_release=$(cat /etc/redhat-release)
                             echo -e "\n####${ECHO_STYLE_01}Linux system version: ${linux_release}${ECHO_STYLE_00}####"
                             echo -e "\n====${ECHO_STYLE_10}You Select Package: ${mysql_pkt}${ECHO_STYLE_00}====\n"
                             echo -e "${ECHO_STYLE_05}b${ECHO_STYLE_00}):Go back re-select the mysql installation package"
                             echo -e "${ECHO_STYLE_05}run${ECHO_STYLE_00}):Please input run to start installing MySQL"
                             read -p ":" run
                             if [ "$run"x == "bx" ];then
                                 mysql_pkt="" #go bak re-select
                             elif [ "$run"x == "runx" ];then
                                 initmysqlfile=$mysql_pkt
                                 break 2 #exit and installing MySQL
                             fi
                         fi
                     done
                 else
                     echo -e "\n==== you input ${select_mysqlv} please enter less than ${#mysqlv_arr[@]} number====\n"
                     echo -e "Please choose again......\n"
                 fi
                 ;;
             q|Q) 
                 echo -e "you select q to exit........\n"
                 exit 1
                 ;; 
             *) 
                echo -e "please choise the number of mysql version\n"
                ;;
        esac    
done
}
choise_mysql

if [ ! -f ${softpath}${initmysqlfile} ];then
    wget -q -t 2 -T 3 http://tools-dba.xxx/dbasoft/MySQL/${initmysqlfile} -P ${softpath}
else
    echo "The ${softpath}${initmysqlfile} is exist"
fi
md5url="http://tools-dba.xxx/dbasoft/MySQL/${initmysqlfile}.md5"
testcode=$(curl -I -s ${md5url}|grep -i -oP '(?<=HTTP/[0-9].[0-9]\s)[0-9]{3}(?=\s.*)')
if [ ${testcode} -eq 200 ];then
    filemd5=$(curl -s ${md5url})
else
    echo "filemd5 is error and url down code:${testcode}"
    exit 1
fi
md5result=$(md5sum ${softpath}${initmysqlfile}|awk '{printf$1}')
if [ -n "${md5result}" ]&&[ ${md5result} == ${filemd5} ] && [ ! -d ${mysqlbasedir} ];then
    tar -zxvpPf ${softpath}${initmysqlfile}
    mkdir -p /tmp/temp;cd /tmp/temp
    rm ${softpath}${initmysqlfile}
else
    echo "Please check md5 or the ${mysqlbasedir} is exist"
    exit 1

fi
chown mysql:mysql -R ${mysqlbasedir}
chown mysql:mysql -R ${initmysqldata}
if [ -f /home/mysql/.mylogin.cnf ];then
    chown mysql:mysql -R /home/mysql
fi

#deploy ssh key
echo -e "====deploy ssh key====\n"
wget -q -t 2 -T 3 http://tools-dba.xxx/script/dbascript/auto_deploykey.sh -O /tmp/auto_deploykey.sh 
sh /tmp/auto_deploykey.sh 
}

init_mysqlpath(){
if grep PATH="${mysqlpath}" /home/mysql/.bash_profile >/dev/null;then
    echo "mysql path already exists"
else
    sed -i "s#PATH=#PATH=${mysqlpath}:#" /home/mysql/.bash_profile 
    cat >>/home/mysql/.bash_profile <<EOF
export MYSQL_PS1="\u@\d>"
export LANG=en_US.UTF-8
EOF
fi

if grep "add for mysql" /etc/security/limits.conf >/dev/null;then
    echo "mysql limit already exists"
else
    cat >>/etc/security/limits.conf <<EOF
##add for mysql
mysql soft nofile 653360
mysql hard nofile 653360
mysql soft nproc 163840
mysql hard nproc 163840
mysql soft stack unlimited
mysql hard stack unlimited
EOF
cat /etc/security/limits.conf
fi

if grep "add for mysql" /etc/sysctl.conf >/dev/null;then
    echo "mysql sysctl already exists"
else
    cat >>/etc/sysctl.conf <<EOF
##add for mysql
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
vm.swappiness = 5
vm.zone_reclaim_mode = 0
EOF
cat /etc/sysctl.conf
sysctl -p
fi

if [ -n "`mount|awk '/\/data/'`" ];then
    datadisk="`mount|awk -F '[0-9:/ ]+' '/\/data/{print$3}'`"
    echo -e "datadisk=${datadisk}\n"
elif [ -z "`mount|awk '/\/data/'`" -a  -n "`mount|awk '/\/app/'`" ];then
    datadisk="`mount|awk -F '[0-9:/ ]+' '/\/app/{print$3}'`"
    echo -e "datadisk=${datadisk}\n"
else
    echo -e "No data or app directory is mounted\n" 
    exit 1
fi

if grep "add for mysql" /etc/rc.d/rc.local >/dev/null;then
    echo "mysql limit already exists"
else
    cat >>/etc/rc.d/rc.local <<EOF
##add for mysql
if test -f /sys/kernel/mm/transparent_hugepage/enabled; then
   echo never > /sys/kernel/mm/transparent_hugepage/enabled
fi
if test -f /sys/kernel/mm/transparent_hugepage/defrag; then
   echo never > /sys/kernel/mm/transparent_hugepage/defrag
fi

echo "deadline"> /sys/block/${datadisk}/queue/scheduler
echo "16" > /sys/block/${datadisk}/queue/read_ahead_kb
echo "512" > /sys/block/${datadisk}/queue/nr_requests
echo "512" > /sys/block/${datadisk}/device/queue_depth
echo "1" > /sys/block/${datadisk}/queue/rq_affinity
echo 0 > /sys/block/${datadisk}/queue/rotational
EOF
cat /etc/rc.d/rc.local

#set 
if test -f /sys/kernel/mm/transparent_hugepage/enabled; then
   echo never > /sys/kernel/mm/transparent_hugepage/enabled
fi
if test -f /sys/kernel/mm/transparent_hugepage/defrag; then
   echo never > /sys/kernel/mm/transparent_hugepage/defrag
fi

echo "deadline"> /sys/block/${datadisk}/queue/scheduler
echo "16" > /sys/block/${datadisk}/queue/read_ahead_kb
echo "512" > /sys/block/${datadisk}/queue/nr_requests
echo "512" > /sys/block/${datadisk}/device/queue_depth
echo "1" > /sys/block/${datadisk}/queue/rq_affinity
echo 0 > /sys/block/${datadisk}/queue/rotational

fi
}
alias_mysql(){
mysql_bash_profile="/home/mysql/.bash_profile"
if ! egrep "mysql.${port}.login" "${mysql_bash_profile}" >/dev/null;then
    echo """alias mysql.${port}.login='mysql --defaults-file=/app/mysql/etc/my${port}.cnf --login-path=mysql.local'"""
    echo """alias mysql.${port}.login='mysql --defaults-file=/app/mysql/etc/my${port}.cnf --login-path=mysql.local'""" >>"${mysql_bash_profile}" 
else
    echo "alias mysql.${port}.login already exists"
fi
if ! egrep "mysql.${port}.up" "${mysql_bash_profile}"  >/dev/null;then
    echo """alias mysql.${port}.up='mysqld_safe --defaults-file=/app/mysql/etc/my${port}.cnf &'"""
    echo """alias mysql.${port}.up='mysqld_safe --defaults-file=/app/mysql/etc/my${port}.cnf &'""" >>"${mysql_bash_profile}" 
else
   echo "alias mysql.${port}.up already exists"
fi
if ! egrep "mysql.${port}.down" "${mysql_bash_profile}"  >/dev/null;then
    echo """alias mysql.${port}.down='mysqladmin --defaults-file=/app/mysql/etc/my${port}.cnf --login-path=mysql.local shutdown'"""
#    echo """alias mysql.${port}.down='mysqladmin --defaults-file=/app/mysql/etc/my${port}.cnf --login-path=mysql.local shutdown'""" >>"${mysql_bash_profile}" 
else
    echo "alias mysql.${port}.down already exists"
fi
}

addmysql(){
echo -e 16bitip:$bitip port:$port innodb_poolsize:$innodb_poolsize "\n"
addmysql_path="/data/my${port}"
if [ -d ${initmysqldata} ]&&[ ! -d ${addmysql_path} ];then
    echo "cp -r ${initmysqldata} ${addmysql_path}"
    cp -r ${initmysqldata} ${addmysql_path}
    echo "chown mysql:mysql -R ${addmysql_path}"
    chown mysql:mysql -R ${addmysql_path}
    chmod 7777 ${addmysql_path}/tmp
else
    echo "If ${addmysql_path} already exists do not setup it or ${initmysqldata} not exists please run initmysql"
    exit 1
fi
defaultmysqlcnf="${mysqlbasedir}/etc/my3306.cnf.default"
addmysqlcnf="${mysqlbasedir}/etc/my${port}.cnf"
if [ -f ${defaultmysqlcnf} ]&&[ ! -f ${addmysqlcnf} ];then
    echo "cp ${defaultmysqlcnf} ${addmysqlcnf}"
    cp ${defaultmysqlcnf} ${addmysqlcnf}
    echo ""sed -i -e "'s/{3306}/${port}/g'" -e "'s/{16bitip}/${bitip}/g'" -e "'s/{innodb_poolsize}/${innodb_poolsize}/g'" ${addmysqlcnf}""
    sed -i -e "s/{3306}/${port}/g" -e "s/{16bitip}/${bitip}/g" -e "s/{innodb_poolsize}/${innodb_poolsize}/g" ${addmysqlcnf}
    echo "chown mysql:mysql -R ${addmysqlcnf}"
    chown mysql:mysql -R ${addmysqlcnf}
    check_vldpw=$(grep 'validate_password' $addmysqlcnf|wc -l)
    if ((check_vldpw==0));then
        sed -i '/\[mysqld_safe\]/i\\!include /app/mysql/etc/validate_password.cnf' $addmysqlcnf
        cat > /app/mysql/etc/validate_password.cnf <<EOF
[mysqld]
plugin-load-add="validate_password=validate_password.so"
# set validate_password
validate_password_policy=MEDIUM
validate_password_length=13
validate_password_number_count=1
validate_password_mixed_case_count=1
validate_password_special_char_count=0
EOF
    else
        sed -i 's/validate_password_policy.*/validate_password_policy=MEDIUM/g' $addmysqlcnf
        sed -i 's/validate_password_length.*/validate_password_length=13/g' $addmysqlcnf
        sed -i 's/validate_password_number_count.*/validate_password_number_count=1/g' $addmysqlcnf
        sed -i 's/validate_password_mixed_case_count.*/validate_password_mixed_case_count=1/g' $addmysqlcnf
        sed -i 's/validate_password_special_char_count.*/validate_password_special_char_count=0/g' $addmysqlcnf
    fi
else
    echo "${defaultmysqlcnf} does not exist or ${addmysqlcnf} already exists"
fi
}

dbagent(){
scriptpath="/usr/local/scripts"
if [ ! -d ${scriptpath} ];then
    mkdir -p ${scriptpath}
fi

wget -q -t 2 -T 3 http://tools-dba.xxx/script/dbascript/AGENT/db_agent.tar.gz -O /usr/local/scripts/db_agent.tar.gz
tar -xvf /usr/local/scripts/db_agent.tar.gz -C /usr/local/scripts/
if [ $? -eq 0 -a -f "${scriptpath}/db_agent" ];then
    echo -e '==start db_agent ==\n'
    cd ${scriptpath}
    chmod +x db_agent && nohup ./db_agent >db_agent.log &
fi
cat >>/etc/rc.d/rc.local <<EOF
#start db_agent
cd /usr/local/scripts/;nohup ./db_agent >db_agent.log &
EOF
}

yumpkt(){
yum install -y readline-devel \
libaio libaio-devel bison bison-devel libtool \
libxml* libxml2 libxml2-devel zlib*  zlib-devel fiex*  libmcrypt* libtool-ltdl-devel* \
perl-DBI perl-DBD-MySQL ncurses ncurses-devel expat-devel bzr \
sysstat lrzsz screen dstat vim unzip bc
} 

falcon_agent(){
curl --retry 3 --retry-max-time 5 http://yum.pt.xxx/files/falconinstall.local.sh -x xxx:80 -o /tmp/falconinstall.local.sh && bash /tmp/falconinstall.local.sh
if [ $? -ne 0 ];then
    echo -e "Successful installation of Falcon agent\n" 
else
    echo -e "Installation failure Falcon agent\n" 
    exit 1
fi
}




set_pt_orzdba(){
wget -q -t 2 -T 3 http://tools-dba.xxx/script/dbascript/deploy_orzdba.sh -O /tmp/deploy_pt_orzdba.sh
sh /tmp/deploy_pt_orzdba.sh
wget -q -t 2 -T 3 tools-dba.xxx/script/dbascript/deploy_percona-toolkit.sh -O /tmp/deploy_percona-toolkit.sh
sh /tmp/deploy_percona-toolkit.sh
wget -q -t 2 -T 3 http://tools-dba.xxx/script/dbascript/deploy_xtraBackup.sh -O /tmp/deploy_xtraBackup.sh && sh /tmp/deploy_xtraBackup.sh
}




dbserver(){
wget  -q -t 2 -T 3 http://tools-dba.xxx/dbasoft/dbserverinstall.sh -O /tmp/bserverinstall.sh && sh /tmp/dbserverinstall.sh
}

case $1 in
        initmypath)
                init_mysqlpath
                ;;
        aliasmysql)
                shift
                if [ $# -eq 1 ]&&[ ${#1} -le 5 ]&& echo $1|egrep -v '[a-zA-Z]' >/dev/null;then
                    port=$1
                    alias_mysql
                else
                    echo -e "${ECHO_STYLE_01}Please enter a four-digit port value OR the port contains characters${ECHO_STYLE_00}"
                    echo -e $"${ECHO_STYLE_05}example: sh $0 aliasmysql 3307${ECHO_STYLE_00}\n"
                    exit 0
                fi
                ;;
        initmysql)
                checkinfo
                set_sshkey
                initmysql
                init_mysqlpath
                dbagent
                dbserver
                yumpkt
                #falcon_agent
                #set_mymon
                set_qulin_dbmonitor
                #falcon_mysql
                set_pt_orzdba
                ;;
        addmysql)
                shift
                if [ $# -ge 1 ]&&[ ${#1} -le 5 ]&& echo $1|egrep -v '[a-zA-Z]' >/dev/null;then
                    port=$1
                    bitip=$(ip a|awk '/inet 10\./{print$2}'|awk -F'/' '{if(NR==1) print$1}'|cut -d\. -f3-4|sed  's/\.//')
                else
                    echo -e "${ECHO_STYLE_05}Please enter a four-digit port value OR the port contains characters${ECHO_STYLE_00}\n"
                    exit 0
                fi
                shift
                if [ $# -eq 1 ]&& echo $1|egrep '^[0-9]+[gGmM]{1}$' >/dev/null;then
                    innodb_poolsize=$(echo $1|awk '{print toupper($0)}')
                elif [ $# -eq 0 ];then
                    echo -e "${ECHO_STYLE_01}The default value for the system is 80% without the input innodb_buffer_pool_size${ECHO_STYLE_00}\n"
                    innodb_poolsize=$(free -m|awk '/Mem:/{print int($2*0.8)"M"}')
                    echo -e "${ECHO_STYLE_05}Please enter yes to confirm that memory is allocated by 80% and continue to execute${ECHO_STYLE_00}"
                    while read line
                        do 
                            if [ ${line} != "yes" ];then
                                echo -e "Input error\n" 
                                exit 1 
                            else
                                echo -e "${ECHO_STYLE_03}innodb_buffer_pool_size ${innodb_poolsize}${ECHO_STYLE_00}" 
                                break
                            fi
                        done
                else
                    echo -e "${ECHO_STYLE_01}The innodb_buffer_pool_size please enter the number + m or g units${ECHO_STYLE_00}\n"
                    exit 0
                fi
                addmysql
                alias_mysql
                ;;
        dbagent)
                dbagent 
                ;;
        yum)
                yumpkt
                ;;
        flcagent)
                falcon_agent 
                ;;
        sshkey)
                set_sshkey
                ;;
        setmymon)
                set_mymon
                ;;
        flcmysql)
                falcon_mysql
                ;;
        setptorz)
                set_pt_orzdba
                ;;
        chkinfo)
                shift
                if [ $# -eq 1 ]&& echo $1|egrep '^force$' >/dev/null;then
                    Check=$1
                fi
                checkinfo
                ;;
            *)
                echo -e $"${ECHO_STYLE_01}Usage: sh $0 {initmypath|aliasmysql port|initmysql|addmysql port innodb_buffer_pool_size}|dbagent|yum|flcagent|set_sshkey|chkinfo}${ECHO_STYLE_00}\n"
                echo -e $"${ECHO_STYLE_05}example: sh $0 initmysql${ECHO_STYLE_00}"
                echo -e $"${ECHO_STYLE_05}example: sh $0 addmysql 3307 20480m${ECHO_STYLE_00}"
                echo -e $"${ECHO_STYLE_05}example: sh $0 dbagent${ECHO_STYLE_00}"
                echo -e $"${ECHO_STYLE_05}example: sh $0 yum${ECHO_STYLE_00}"
                echo -e $"${ECHO_STYLE_05}example: sh $0 flcagent${ECHO_STYLE_00}"
                echo -e $"${ECHO_STYLE_05}example: sh $0 sshkey${ECHO_STYLE_00}"
                echo -e $"${ECHO_STYLE_05}example: sh $0 chkinfo [force]${ECHO_STYLE_00}"
                echo -e $"${ECHO_STYLE_05}example: sh $0 setmymon${ECHO_STYLE_00}"
                echo -e $"${ECHO_STYLE_05}example: sh $0 flcmysql${ECHO_STYLE_00}"
                echo -e $"${ECHO_STYLE_05}example: sh $0 setptorz${ECHO_STYLE_00}"
                ;;
esac
