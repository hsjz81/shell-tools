#!/bin/bash
###########################################################################################
#  @programe  : fping.sh
#  @version   : 0.0.1
#  @function@ : Fast ping hosts and statistic result
#  @modify    : Huang Ling Fei
#  @date      : 2017-06-20
############################################################################################

PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
homedir="/data/logs"
logdir="${homedir}/pinglogs"
if [ ! -d "${logdir}" ];then
   mkdir -p ${logdir}
fi
iplist=(
xxxx
xxxx
)
packetsize=$1;packetsize=${packetsize:=64}
for ip in ${iplist[@]}
    do
        log="$homedir/fping_result_${packetsize}_${ip}.log"
        while true
            do
                date=`date +%F"_"%H:%M:%S_%N`  
                pinglogfile="${homedir}/pinglogs/${ip}_${packetsize}_${date}.log"
                ping -W 1 -c 100 -i 0.2 -s ${packetsize} $ip >> ${pinglogfile} 2>&1
                num=$(awk -F'[ |%]' '/packet/{print$6}' ${pinglogfile})    
                Timeout=$(cat ${pinglogfile}|awk -F'[ |/]' '/rtt/{if($8>=3)print}')
                if [ "$num" -gt 0 -o -n "$Timeout" ];then
                    if [ "$num" -gt 3 ];then
                       echo -e "Date : $date Host : $ip Problem : Ping is failed: ${num}% packet loss\n ${pinglogfile}\n" >>$log
                    fi
                    if [ -n "$Timeout" ];then
                       echo -e "Date : $date Host : $ip  ping timeout, average delay: ${Timeout}\n ${pinglogfile}\n" >>$log
                    fi
                else  
                    cd $homedir
                    rm $pinglogfile -rf
                fi
            done &
    done
