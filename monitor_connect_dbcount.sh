#!/bin/bash
###########################################################################################
#  @programe  : monitor_connect_dbcount.sh                                          
#  @version   : 0.0.3                                                       
#  @function@ : Statistics the number of the  db connections                                  
#  @writer    : Huang Ling Fei                                              
#  @date      : 2016-08-22                                                 
############################################################################################

PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
export PATH

Dbname=`hostname`
Sname="${Dbname}-$(ifconfig|awk '/addr:10\./{print$2}'|cut -d\. -f3-4)"
Datetime=`date +%F' '%T' '%u`
Maxconnect=$1;Maxconnect=${Maxconnect:=500}
Semail=$2
Logpath='/xxx/logs/'
if [ ! -d "$Logpath" ];then
   mkdir -p $Logpath
fi
Log=${Logpath}monitorcdb$(date +%F).log
Tmpfile=`mktemp`
Tmplistenfile=`mktemp`

Mailfrom="xxx"
Smtp="xxx"
Username="xxx"
Pass="xxx"
Mailto="xxx"
Mailcc="xxx,
xxx"

arraytmp="/tmp/checkresult"
declare -a checkresult
T='mysql redis tnslsnr memcache mongod mongos'
array(){
ss -lnpt >$Tmplistenfile
for p in $T
    do
        cat $Tmplistenfile|awk -v a="$p" -v b='*:' '{if($NF~/'$p'/) print a,$4}'|awk -F':' '{print$1,$NF}' >>$arraytmp
    done
i=0
while read line
    do 
        checkresult[$i]="$line"
        let i=i+1 
    done <$arraytmp
}
array

netstat -ant |grep -v 'LISTEN'|sed 's/::ffff://g' >>$Tmpfile

echo -e "start statistics the number of the db connections $Datetime\n" >>$Log

for ((i=0;i<$(echo ${#checkresult[*]});i++))
do
    Serverport=$(echo ${checkresult[$i]}|awk '{print$NF}')
    echo -e "==============Serverport ${checkresult[$i]} ==============\n" >>$Log

    Cdbcount=$(cat $Tmpfile|awk '{if($4~/'$Serverport'/) print}'|awk -F\: '{print$1" "$2" "$3}'|awk '{print$6" "$8}'|awk '{++S[$1]} END {for (i in S){if(S[i]>=1) print i,S[i]}}'|sort)
    Substatuscount=$(cat $Tmpfile|awk '$4~/'$Serverport'/'|awk -F\: '{print$1" "$2" "$3}'|awk '{print$4" "$6" "$8}'|sort|uniq -c|sort -nr)
    Cstatussummary=$(cat $Tmpfile|awk '/tcp/ {++S[$NF]} END {for (i in S) print i,S[i]}'|sort)
    Sumconnect=$(cat $Tmpfile|awk '{if($4~/'$Serverport'/) print}'|awk 'END{print NR}')
    if [ ! "x$Cdbcount" = "x" ];then
        echo "----------------------Sub status count-----------------------" >>$Log
        echo -e "$Substatuscount\n" >>$Log
        if [ $Sumconnect -ge $Maxconnect ]&&[ -n "$Semail" ];then
            echo "====================================================" >>$Log
            echo "start send Email `date +%F' '%T`" >>$Log
            echo "$Cdbcount" >>$Log
            /usr/local/bin/sendEmail -f $Mailfrom -t $Mailto -cc $Mailcc -u "The database current number of connections for $Sname" -s $Smtp -xu $Username -xp $Pass -o message-charset=utf-8 \
-m "The $Sname db current number of connections is
==============================================
$Cdbcount
----------Connection status summary-----------
$Cstatussummary"
        fi
    else
        echo -e "------------------------------------------------------------\n" >>$Log
        echo -e "the  number of the  db connections is ok\n" >>$Log
    fi
done

echo "-----------------Connection status summary------------------" >>$Log
echo "$Cstatussummary" >>$Log
echo -e "------------------------------------------------------------\n" >>$Log
echo -e "###############################################################################\n"  >>$Log
mkdir -p /tmp/temp
cd /tmp/temp
rm $Tmpfile
rm $Tmplistenfile
:>/tmp/checkresult
#start gzip log 7 day ago 
Mysqlconnectlog=$(find ${Logpath} -type f -name "monitorcdb*log"  -atime +7)
if [ -n "$Mysqlconnectlog" ];then
   gzip $Mysqlconnectlog
fi
#start del log 60 day ago 
find ${Logpath} -type f -mtime +60 -name "monitorcdb*log.gz"|xargs -n 2 -P 2 -i rm {}
