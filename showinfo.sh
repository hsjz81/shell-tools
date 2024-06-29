#!/bin/bash
###########################################################################################
#  @programe  : showinfo.sh 
#  @version   : 0.0.5
#  @function@ : Check system information and display
#  @modify    : Huang Ling Fei
#  @date      : 2020-02-25
############################################################################################

PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
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

Check=$1;Check=${Check:='normal'}
Ntp_sip="xxx"
echohd(){
    Repeat=$(printf "%-30s" "="|sed "s/ /=/g")
    echo -e "\n${Repeat} ${ECHO_STYLE_09} $1 ${ECHO_STYLE_00} ${Repeat}"
}

echo_subhd(){
     Repeat=$(printf "%-20s"|sed "s/ /-/g")
     echo -e "\n`printf %-10s` ${Repeat}"
     echoit "${ECHO_STYLE_05} $1 ${ECHO_STYLE_00}"
     echo -e "`printf %-10s` ${Repeat}"
}

echoit(){
    if [ $# -eq 1 ];then
        echo -e "`printf %-10s` $1"
    fi
    if [ $# -eq 2 ];then
        echo -e "`printf %-10s` $1:$2"
    fi
}

echo_warn(){
     Repeat=$(printf "%-20s"|sed "s/ /*/g")
     echo -e "\n`printf %-10s` ${Repeat}"
     echoit "${ECHO_STYLE_01} $1 !!!${ECHO_STYLE_00}"
     echo -e "`printf %-10s` ${Repeat}"
}

clean(){
Cln_file="$0"
rm "$Cln_file"
}

system_info(){
    echohd "服务器信息"
    dmidecode -t system\
    |awk 'BEGIN{FS=":"} \
          {if ($1~/Manufacturer/){print "Manufacturer:_",$2}\
          else if ($1~/Product Name/){print "Product Name:_",$2}\
          else if ($1~/Version/){print "Version:_",$2}\
          else if ($1~/UUID/){print "UUID:_",$2}\
          else if ($1~/Wake-up Type/){print "Wake-up Type:_",$2}\
          else if ($1~/SKU Number/){print "SKU Number:_",$2}\
          else if ($1~/Family/){print "Family:_",$2}}'\
    |column -s'_' -t|while read line;
    do
        echoit "$line"
    done
}

cpu_info(){
    echohd "cpu配置"
    Processor=$(awk 'BEGIN{FS=":";max=0} {if ($1~/processor/){if($2+0>max+0) max=$2 fi}}END{print max+1}' /proc/cpuinfo)
    echoit "cpu颗数" " ${Processor}"
    Model_name=$(awk 'BEGIN{FS=":"} {if ($1~/model name/){model=$2 fi}}END{print model}' /proc/cpuinfo)
    echoit "cpu型号" "${Model_name}"
}

mem_info(){
    echohd "内存配置"
    free -m|while read line;
    do
        echoit "$line"
    done
}

disk_info(){
    echohd "磁盘配置"
    df -h|awk '$1!~/tmpfs/'|while read line;
    do
        echoit "$line"
    done
}

net_info(){
    echohd '网络配置'
    ip a|gawk 'BEGIN{FS=":"}{
        if ($1~/^[0-9]/&&$2!~/lo/){
            dev=$2;cmd="ethtool "dev
            i=0 #初始变量i=0,很重要
            delete cmd_out;#删除之前的数组很重要否则会在原数组增加内容,很重要
            while(cmd|getline) cmd_out[++i]=$0;close(cmd);{
                Lt=length(cmd_out);
                for (i=1; i<=Lt ;++i) {
                    Rt=cmd_out[i]; 
                    if (Rt~/Link detected/) {split(Rt,S);Link=S[2];
                    }
                    else if (Rt~/Speed/) {split(Rt,S);Speed=S[2];
                    } 
                    else if (Rt~/Duplex/) {split(Rt,S);Duplex=S[2];
                    }
                } 
    
                {
                print "*******************"
                print "\033[32;1m","网卡:",dev,"\033[0m"
                print "*******************"
                if (Link~/yes/) 
                    {print "状态:  UP"}
                else
                    {print "状态:  DOWN"}
                print "速率:",Speed
                print "模式:",Duplex
                }      
            }
            cmd="ip add show dev "dev
            i=0 #初始变量i=0,很重要
            delete cmd_out;#删除之前的数组很重要否则会在原数组增加内容,很重要
            while(cmd|getline) cmd_out[++i]=$0;{
                Lt=length(cmd_out);
                for (i=1; i<=Lt ;++i) {
                    Rt=cmd_out[i]; 
                    if (Rt~/inet/) {split(Rt,S," ");Ip=S[2];print "IP:",Ip}
                }      
            }
            
        }
    }
    '\
    |while read line;
         do
             echoit "$line"
         done
     echoit "-------------------"
     echoit "${ECHO_STYLE_05}路由信息${ECHO_STYLE_00}"
     echoit "-------------------"
    ip route\
    |while read line;
         do
             echoit "$line"
         done
}

sys_info(){
    echohd "系统信息"
    echo_subhd "linux系统版本"
    echoit "`cat /etc/redhat-release`"
    selinux_info
    lang_info
    ulimit_info
}

lang_info(){
    echo_subhd "字符集设置"
    Lang=$(locale|grep LANG)
    echoit "${Lang}"
    if [ "${Lang}x" != "LANG=en_US.UTF-8x" ];then
        echo_warn "LANG设置${Lang}请检查并设置为LANG=en_US.UTF-8"
        if [ "${Check}x" = "forcex" ];then
            exit 1
        fi
    fi
}

selinux_info(){
    echo_subhd "SELinux"
    Sestatus=$(sestatus|awk '{print$3}')
    echoit "${Sestatus}"
    if [ "${Sestatus}x" != "disabledx" ];then
        echo_warn "selinux设置${Sestatus}请检查并关闭"
        if [ "${Check}x" = "forcex" ];then
            exit 1
        fi
    fi
}

ulimit_info(){
    echo_subhd "文件描述符配置"
    awk '$1!~/^$|#/{print}' /etc/security/limits.conf /etc/security/limits.d/*\
    |while read line;
         do
             echoit "$line"
         done
    Unlimit=$(ulimit -a|awk '/open files/{print$NF}')
    if [ ${Unlimit} -lt 655360 ];then
        echo_warn "文件描述符 ulimit=${Unlimit}小于655360 请检查"
        if [ "${Check}x" = "forcex" ];then
            exit 1
        fi
    fi
}

check_ntp(){

    Chkntp_tmp="/tmp/checkntp"
    echohd "检查时间"
    echo_subhd "检查时间同步服务"
    Ntpstat="$(ntpstat 2>&1)"
    if [ $? -ne 0 ];then
        echoit "检查报错: !!!"
        echo_warn "$Ntpstat"
    else
       echoit "检查结果:"
       echoit "********************"
       echo $Ntpstat\
       |while read line;
            do
                echoit "$line"
            done
       echoit "********************"
    fi

    echo_subhd "与时间服务器对比时间"
    ntpdate -q ${Ntp_sip} 2>&1|\
    awk -v Ntp_sip="${Ntp_sip}" '$1!~/^server/{
         Sec=NF-1
         if($NF=="sec"){
             Diff_time=int($Sec+0.5)
             if(Diff_time>0){
                 print "*******************"
                 print"\033[41;33;1m","比时间服务器慢: ",Diff_time,"秒!!!!","\033[0m"
                 print "*******************"
                 print "Exit=exit"
             }else if(Diff_time==0){
                 print "*******************"
                 print"\033[32;1m","时间同步正常: ",Diff_time,"秒","\033[0m"
                 print "*******************"
             }else if(Diff_time<0){
                 print "*******************"
                 print"\033[41;33;1m","比时间服务器快: ",0-Diff_time,"秒!!!!","\033[0m"
                 print "*******************"
                 print "Exit=exit"
             }
         }
         else{
             printf("连接%s报错:%s\n",Ntp_sip,$0)
             print "Exit=exit"
         }
    }'> ${Chkntp_tmp}
    while read line;
        do
            if echo "$line"|egrep -v 'Exit=exit' >/dev/null 2>&1;then
                echoit "$line"
            else
                echo_warn "请检查同步时间配置!!!"
                if [ "${Check}x" = "forcex" ];then
                    exit 1
                fi
            fi
        done <${Chkntp_tmp}
}
show_info(){
    system_info
    cpu_info
    mem_info
    disk_info
    net_info
    sys_info
    check_ntp
    clean
}
show_info
