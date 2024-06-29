#!/bin/bash
###########################################################################################
#  @programe  : auto_setup_mongo.sh
#  @version   : 0.0.3
#  @function@ : Automatic Mongodb multi instance installation
#  @writer    : Huang Ling Fei
#  @date      : 2020-05-26
#  @modify    : 2022-02-15
############################################################################################

PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
# Source function library.
. /etc/init.d/functions
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
Basedir="/app"
Datadir="/data"
Mongo_bash_profile="/home/mongo/.bash_profile"
Scriptpath="/usr/local/scripts"
if [ ! -d $Scriptpath ];then
    mkdir -p $Scriptpath
fi

Add_mongo_conf="${Scriptpath}/add_mongo_ins.ini"
Num=1
Sleeptime=3
Logdir="mongologs"
Mongolog="${Scriptpath}/${Logdir}/setup-mongo.log"
if [ ! -d "${Scriptpath}/${Logdir}" ];then
   mkdir -p ${Scriptpath}/${Logdir}
fi

show_version(){
    echo "version: 0.0.1"
    echo "ceated date: 2020-05-26"
}

show_usage(){
    echo -e "`printf %-16s "Usage: $0"` --help"
    echo -e "`printf %-17s `                         "
    echo -e "`printf %-17s ` Actions:"
    echo -e "`printf %-17s ` --opt=s                 [initmongo|add|start|stop|initrs]"
    echo -e "`printf %-17s ` --type=s                [mongod|arbiter|config|mongos]"
    echo -e "`printf %-17s `                         "
    echo -e "`printf %-17s ` addMongoD:"
    echo -e "`printf %-17s ` --shard=s               Enable sharding or not (Enter true to turn on default false)"
    echo -e "`printf %-17s ` --port=i            -P  Port number to use for mongo installation"
    echo -e "`printf %-17s `                         Replica port 27017 start default 27017"
    echo -e "`printf %-17s `                         shard port 28017 start default 28017"
    echo -e "`printf %-17s ` --replset=s             Replica set name"
    echo -e "`printf %-17s ` --maxconn=i             Mongod instance maxinum connections (default 40000)"
    echo -e "`printf %-17s ` --oplog=i               Mongod oplog size (default 30720MB)"
    echo -e "`printf %-17s ` --wtsize=i              Mongod wiredTiger Cache SizeGB"
    echo -e "`printf %-17s `                         "
    echo -e "`printf %-17s ` addConfig:"
    echo -e "`printf %-17s ` --configsvr=s           Enable configsvr or not (Enter true to turn on, default false)"
    echo -e "`printf %-17s ` --replset=s             Replica set name(if type sets config, the configsvr is true and the default name of replset is configRs)"
    echo -e "`printf %-17s ` --port=i            -P  Port number to use for mongo installation"
    echo -e "`printf %-17s `                         Replica port 20000 start default 20000"
    echo -e "`printf %-17s ` --maxconn=i             Mongod instance maxinum connections (default 40000)"
    echo -e "`printf %-17s ` --oplog=i               Mongod oplog size (default 30720MB)"
    echo -e "`printf %-17s ` --wtsize=i              Mongod wiredTiger Cache SizeGB"
    echo -e "`printf %-17s `                         "
    echo -e "`printf %-17s ` addMongos:"
    echo -e "`printf %-17s ` --configdb=s            The configsvr cluster list"
    echo -e "`printf %-17s `                         When the configSRv Replset default name is configRs and configdb sets 'configRs/......'"
    echo -e "`printf %-17s ` --port=i            -P  Port number to use for mongos installation"
    echo -e "`printf %-17s `                         default port 30000"
    echo -e "`printf %-17s ` --maxconn=i             Mongos instance maxinum connections (default 10000)"
    echo -e "`printf %-17s `                         "
    echo -e "`printf %-17s ` startMongo:"
    echo -e "`printf %-17s ` --enauth=s              enable mongo auth (default false)"
    echo -e "`printf %-17s ` --port=i            -P  Port number to use for starting mongo"
    echo -e "`printf %-17s `                         "
    echo -e "`printf %-17s ` stopMongo:"
    echo -e "`printf %-17s ` --host=s                Host to use for closing mongo (default 127.0.0.1)"
    echo -e "`printf %-17s ` --port=i            -P  Port number to use for closing mongo"
    echo -e "`printf %-17s `                         "
    echo -e "`printf %-17s ` restartMongo:"
    echo -e "`printf %-17s ` --enauth=s              enable mongo auth (default false)"
    echo -e "`printf %-17s ` --port=i            -P  Port number to use for starting mongo"
    echo -e "`printf %-17s `                         "
    echo -e "`printf %-17s ` initRs:"
    echo -e "`printf %-17s ` --configsvr=s           Enable configsvr or not (Enter true to turn on, default false)"
    echo -e "`printf %-17s ` --replset=s             Replica set name(if configsvr sets true, the default name is configRs)"
    echo -e "`printf %-17s ` --dtnd=s                Add data nodes"
    echo -e "`printf %-17s `                         for example --dtnd='host1:port,host2:port,host3:port'"
    echo -e "`printf %-17s ` --arbnd=s               Add arbiter node"
    echo -e "`printf %-17s `                         for example --arbnd='host4:port,host5:port'"
    echo -e "`printf %-17s `                         "
    echo -e "`printf %-17s ` -C|--clean              Delete scripts and logs"
    echo -e "`printf %-17s ` --yum                   yum install related packages for mongo"
    echo -e "`printf %-17s ` --setmtools             Install mongodb slow log tools"
    echo -e "`printf %-17s ` --setmonitor            Install mongo monitor,Includes Falcon basic mongo,cpu"
    echo -e "`printf %-17s ` -v|-V|--version"
    echo -e "`printf %-17s `                         "
    echo -e $"${ECHO_STYLE_05}example: sh $0 --opt=initmongo${ECHO_STYLE_00}"
    echo -e $"${ECHO_STYLE_05}example: sh $0 --opt=add --type=mongod --shard=false --port=27018 --replset=gome_npop --wtsize=5${ECHO_STYLE_00}"
    echo -e $"${ECHO_STYLE_05}example: sh $0 --opt=add --type=arbiter --shard=false --port=29018 --replset=gome_npop --wtsize=5${ECHO_STYLE_00}"
    echo -e $"${ECHO_STYLE_05}example: sh $0 --opt=add --type=mongod --shard=true --port=28017 --replset=shard1 --wtsize=5${ECHO_STYLE_00}"
    echo -e $"${ECHO_STYLE_05}example: sh $0 --opt=add --type=config --port=20000 --replset=configRs20000 --wtsize=5${ECHO_STYLE_00}"
    echo -e $"${ECHO_STYLE_05}example: sh $0 --opt=add --type=config --port=20000 --wtsize=5${ECHO_STYLE_00}"
    echo -e $"${ECHO_STYLE_05}example: sh $0 --opt=add --type=mongos --port=30000 --configdb='configRs20000/10.8.8.8:20000,10.6.6.6:20000,10.1.1.1:20000' --wtsize=5${ECHO_STYLE_00}"
    echo -e $"${ECHO_STYLE_05}example: sh $0 --opt=add --type=mongos --port=30000 --configdb='configRs/10.8.8.8:20000,10.6.6.6:20000,10.1.1.1:20000' --wtsize=5${ECHO_STYLE_00}"
    echo -e $"${ECHO_STYLE_05}example: sh $0 --opt=initrs --replset=gome_npop --dtnd='10.8.8.8:27017,10.6.6.6:27017,10.1.1.1:27017'${ECHO_STYLE_00}"
    echo -e $"${ECHO_STYLE_05}example: sh $0 --opt=initrs --replset=gome_npop --dtnd='10.8.8.8:27017,10.6.6.6:27017' --arbnd='10.3.3.3:29017'${ECHO_STYLE_00}"
    echo -e $"${ECHO_STYLE_05}example: sh $0 --opt=initrs --configsvr=true --replset=configRs20000 --dtnd='10.8.8.8:20000,10.6.6.6:20000,10.1.1.1:20000'${ECHO_STYLE_00}"
    echo -e $"${ECHO_STYLE_05}example: sh $0 --opt=initrs --configsvr=true --dtnd='10.8.8.8:20000,10.6.6.6:20000,10.1.1.1:20000'${ECHO_STYLE_00}"
    echo -e $"${ECHO_STYLE_05}example: sh $0 --opt=start --type=mongod --port=27017${ECHO_STYLE_00}"
    echo -e $"${ECHO_STYLE_05}example: sh $0 --opt=start --type=mongod --enauth=true --port=27017${ECHO_STYLE_00}"
    echo -e $"${ECHO_STYLE_05}example: sh $0 --opt=start --type=arbiter --port=29017${ECHO_STYLE_00}"
    echo -e $"${ECHO_STYLE_05}example: sh $0 --opt=start --type=arbiter --enauth=true --port=29017${ECHO_STYLE_00}"
    echo -e $"${ECHO_STYLE_05}example: sh $0 --opt=start --type=config --port=20000${ECHO_STYLE_00}"
    echo -e $"${ECHO_STYLE_05}example: sh $0 --opt=start --type=config --enauth=true --port=20000${ECHO_STYLE_00}"
    echo -e $"${ECHO_STYLE_05}example: sh $0 --opt=start --type=mongos --port=30000${ECHO_STYLE_00}"
    echo -e $"${ECHO_STYLE_05}example: sh $0 --opt=start --type=mongos --enauth=true --port=30000${ECHO_STYLE_00}"
    echo -e $"${ECHO_STYLE_05}example: sh $0 --opt=stop --host=10.5.5.5 --port=28017${ECHO_STYLE_00}"
    echo -e $"${ECHO_STYLE_05}example: sh $0 --opt=stop --port=28017${ECHO_STYLE_00}"
    echo -e $"${ECHO_STYLE_05}example: sh $0 --opt=restart --type=mongod --enauth=true --port=28017${ECHO_STYLE_00}"
    echo -e $"${ECHO_STYLE_05}example: sh $0 --opt=restart --type=config --enauth=true --port=20000${ECHO_STYLE_00}"
    echo -e $"${ECHO_STYLE_05}example: sh $0 --yum${ECHO_STYLE_00}"
    echo -e $"${ECHO_STYLE_05}example: sh $0 --setmtools${ECHO_STYLE_00}"
    echo -e $"${ECHO_STYLE_05}example: sh $0 --setmonitor${ECHO_STYLE_00}"
}

clean(){
echo
#rm $0
}

getargs(){
Match_optargarg=""
Args=`getopt -o vVPC: --long help,clean,version,opt:,type:,shard::,configsvr::,configdb:,host::,port::,replset:,maxconn::,oplog::,wtsize:,dtnd:,arbnd::,enauth:: -n "$0" -- "$@"`
if [ $? != 0 ];then
    echo -e "${ECHO_STYLE_03} getopt ERROR: unknown argument!...${ECHO_STYLE_00}\n"
    show_usage
    exit 1
fi 
eval set -- "$Args"

while true
    do
        case "$1" in
            --opt)
                if echo $2|egrep "^initmongo$|^add$|^start$|^stop$|^restart$|^initrs$" >/dev/null;then
                    Opt=$2
                    if [ "${Opt}x" == "initmongox" ];then
                        break
                    fi
                else
                    echo -e "${ECHO_STYLE_05}Please enter the --opt=[initmongo|add|start|stop|restart|initrs] ${ECHO_STYLE_00}\n"
                    exit 1
                fi
                shift 2
                ;;
            --type)
                if echo $2|egrep "mongod|arbiter|config|mongos" >/dev/null;then
                    Type=$2
                else
                    echo -e "${ECHO_STYLE_05}Please enter the type=[mongod|arbiter|config|mongos] ${ECHO_STYLE_00}\n"
                    exit 1
                fi
                shift 2
                ;;
            --shard)
                if echo $2|egrep "^true$|^false$" >/dev/null;then
                    Shard=$2
                else
                    echo -e "${ECHO_STYLE_05}Please enter the --shard=[true|false] ${ECHO_STYLE_00}\n"
                    exit 1
                fi
                shift 2
                ;;
            --configsvr)
                if echo $2|egrep "^true$|^false$" >/dev/null;then
                    Configsvr=$2
                else
                    echo -e "${ECHO_STYLE_05}Please enter the --configsvr=[true|false] ${ECHO_STYLE_00}\n"
                    exit 1
                fi
                shift 2
                ;;
            --host)
                if echo $2|egrep '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$' >/dev/null;then
                    Host=$2
                else
                    echo -e "${ECHO_STYLE_05}Please enter correct IP address format ${ECHO_STYLE_00}\n"
                    exit 1
                fi
                shift 2
                ;;
            -P|--port)
                if [ ${#2} -eq 5 ]&& echo $2|egrep -v '[a-zA-Z]' >/dev/null;then
                    Port=$2
                else
                    echo -e "${ECHO_STYLE_05}Please enter five digit port value OR the port contains characters${ECHO_STYLE_00}\n"
                    exit 1
                fi
                shift 2
                ;;
            --replset)
                if echo $2|egrep '^[a-zA-Z]([0-9]*)' >/dev/null;then
                    Replset=$2
                else
                    echo -e "${ECHO_STYLE_05}Please start with a letter${ECHO_STYLE_00}\n"
                    exit 1
                fi
                shift 2
                ;;
            --maxconn)
                if echo $2|egrep -v '[a-zA-Z]' >/dev/null;then
                    Max_conn=$2
                else
                    echo -e "${ECHO_STYLE_05}Please enter digit value and cannot contain characters${ECHO_STYLE_00}\n"
                    exit 1
                fi
                shift 2
                ;;
            --oplog)
                if echo $2|egrep -v '[a-zA-Z]' >/dev/null;then
                    Oplog_size=$2
                else
                    echo -e "${ECHO_STYLE_05}Please enter digit value and cannot contain characters${ECHO_STYLE_00}\n"
                    exit 1
                fi
                shift 2
                ;;
            --wtsize)
                if echo $2|egrep -v '[a-zA-Z]' >/dev/null;then
                    Wt_cache_size=$2
                else
                    echo -e "${ECHO_STYLE_05}Please enter digit value and cannot contain characters${ECHO_STYLE_00}\n"
                    exit 1
                fi
                shift 2
                ;;
            --dtnd)
                if echo $2|egrep '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}:[0-9]{5}.+:[0-9]{5}$' >/dev/null;then
                    Data_nodes=$2
                else
                    echo -e "${ECHO_STYLE_05}Please enter 'host1:port,host2:port'${ECHO_STYLE_00}\n"
                    exit 1
                fi
                shift 2
                ;;
            --arbnd)
                if echo $2|egrep '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}:[0-9]{5}$|^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}:[0-9]{5}.+:[0-9]{5}$' >/dev/null;then
                    Arbiter_nodes=$2
                else
                    echo -e "${ECHO_STYLE_05}Please enter 'host1:port' or 'host1:port,host2:port'${ECHO_STYLE_00}\n"
                    exit 1
                fi
                shift 2
                ;;
            --configdb)
                if echo $2|egrep '^configRs([0-9]*)/[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}:[0-9]{5}.+:[0-9]{5}$' >/dev/null;then
                    Configdb=$2
                else
                    echo -e "${ECHO_STYLE_05}Please enter 'configRs[0-9]*/host1:port,host2:port,host3:port'${ECHO_STYLE_00}\n"
                    exit 1
                fi
                shift 2
                ;;
            --enauth)
                if echo $2|egrep "^true$|^false$" >/dev/null;then
                    Enauth=$2
                else
                    echo -e "${ECHO_STYLE_05}Please enter the --enauth=[true|false] ${ECHO_STYLE_00}\n"
                    exit 1
                fi
                shift 2
                ;;
            --)
                shift
                break
                ;;
            *)
                echo -e "${ECHO_STYLE_06}ERROR: unknown argument! ${ECHO_STYLE_00}\n" && show_usage && exit 1
                ;;
        esac
    done

if [ -z "${Opt}" ];then
    echo -e "${ECHO_STYLE_03}please enter opt${ECHO_STYLE_00}" 
    echo -e "${ECHO_STYLE_03}--opt=[initmong|add] ${ECHO_STYLE_00}\n" 
    exit 1
elif [ "${Opt}x" == "initmongox" ];then
    echo -e "Start initial install the Mongo instance\n"
elif [ "${Opt}x" == "addx" ];then
    if [ -z "${Type}" ];then
        echo -e "${ECHO_STYLE_03}please enter type${ECHO_STYLE_00}" 
        echo -e "${ECHO_STYLE_03}--type=[mongod|arbiter|config|mongos] ${ECHO_STYLE_00}\n" 
        exit 1
    elif [ "${Type}x" == "configx" ];then
        Shard=${Shard:=true}
        Configsvr=${Configsvr:=true}
        if [ -z "${Replset}" ];then
            Replset="configRs" 
        fi
    elif [ "${Type}x" == "mongosx" ];then
        Shard=${Shard:=true}
    fi
    
    if [ -z "${Shard}" ];then
        Shard=${Shard:=false}
        echo -e "${ECHO_STYLE_05}the shardsvr set the default ${Shard}${ECHO_STYLE_00}\n" 
    fi

    if [ -z "${Configsvr}" ];then
        Configsvr=${Configsvr:=false}
        echo -e "${ECHO_STYLE_05}the configsvr set the default ${Configsvr}${ECHO_STYLE_00}\n" 
    fi
    
    if [ -z "${Port}" ];then
        if [ "${Shard}x" = "falsex" ];then
            Port=${Port:=27017} 
            echo -e "${ECHO_STYLE_05}the port set the default ${Port}${ECHO_STYLE_00}\n" 
        elif [ "${Shard}x" = "truex" ];then
            Port=${Port:=28017} 
            echo -e "${ECHO_STYLE_05}the port set the default ${Port}${ECHO_STYLE_00}\n" 
        elif [ "${Configsvr}x" = "truex" ];then
            Port=${Port:=20000}
            echo -e "${ECHO_STYLE_05}the configsvr port set the default ${Port}${ECHO_STYLE_00}\n" 
        elif [ -n "${Configdb}" ];then
            Port=${Port:=30000}
            echo -e "${ECHO_STYLE_05}the mongos port set the default ${Port}${ECHO_STYLE_00}\n" 
        else
            echo -e "${ECHO_STYLE_03}please enter port${ECHO_STYLE_00}" 
            echo -e "${ECHO_STYLE_03}--port=i ${ECHO_STYLE_00}\n" 
            exit 1
        fi
    else
        if [ "${Type}x" = "mongodx" ];then
            if [ "${Shard}x" = "falsex" ]&&echo $Port|egrep -v '^27[0-9]{3}$' >/dev/null;then
                echo -e "${ECHO_STYLE_06} The shard setting is ${Shard} port needs to start with 27 or 29${Port}${ECHO_STYLE_00}\n" 
                exit 1
            elif [ "${Shard}x" = "truex" ]&&echo $Port|egrep -v '^28[0-9]{3}$' >/dev/null;then
                echo -e "${ECHO_STYLE_06} The shard setting is ${Shard} port needs to start with 28 ${Port}${ECHO_STYLE_00}\n" 
                exit 1
            fi
        fi

        if [ "${Type}x" = "arbiterx" ]&&echo $Port|egrep -v '^29[0-9]{3}$' >/dev/null;then
            echo -e "${ECHO_STYLE_06} The type setting is ${Type} port needs to start with 29 ${Port}${ECHO_STYLE_00}\n" 
            exit 1
        elif [ "${Type}x" = "configx" ]&&echo $Port|egrep -v '^200[0-9]{2}$' >/dev/null;then
            echo -e "${ECHO_STYLE_06} The type setting is ${Type} port needs to start with 200 ${Port}${ECHO_STYLE_00}\n" 
        elif [ "${Type}x" = "mongosx" ]&&echo $Port|egrep -v '^300[0-9]{2}$' >/dev/null;then
            echo -e "${ECHO_STYLE_06} The type setting is ${Type} port needs to start with 300 ${Port}${ECHO_STYLE_00}\n" 
        fi
    fi
    
    if [ -z "${Replset}" ]&&[ "${Type}x" != "mongosx" ];then
        echo -e "${ECHO_STYLE_03}please enter replset${ECHO_STYLE_00}" 
        echo -e "${ECHO_STYLE_03}--replset=s ${ECHO_STYLE_00}\n" 
        exit 1
    fi
    
    if [ -z "${Max_conn}" ];then
        if [ "${Type}x" = "mongosx" ];then
            Max_conn=${Max_conn:=10000}
        elif [ "${Type}x" = "configx" ];then
            Max_conn=${Max_conn:=40000}
        elif [ "${Type}x" = "mongodx" -o "${Type}x" = "arbiterx" ];then
            Max_conn=${Max_conn:=40000}
        fi
        echo -e "${ECHO_STYLE_05}the maxConns set the default ${Max_conn}${ECHO_STYLE_00}\n" 
    fi
    
    if [ -z "${Oplog_size}" ];then
        Oplog_size=${Oplog_size:=30720}
        echo -e "${ECHO_STYLE_05}the oplogSize set the default ${Oplog_size}${ECHO_STYLE_00}\n" 
    fi
    
    if [ -z "${Wt_cache_size}" ]&&[ "${Type}x" != "mongosx" ];then
        echo -e "${ECHO_STYLE_03}please enter wtsize${ECHO_STYLE_00}" 
        echo -e "${ECHO_STYLE_03}--wtsize=i ${ECHO_STYLE_00}\n" 
        exit 1
    fi
    echo "`printf %-120s|sed 's/ /=/g'`"
    echo -e "\n${ECHO_STYLE_01}Opt:${Opt}, Type:${Type}, Port:${Port}, Configsvr:${Configsvr}, Shard:${Shard}, Replset:${Replset}, \
Max_conn:${Max_conn}, Oplog_size:${Oplog_size}MB, Wt_cache_size:${Wt_cache_size}GB, \
Configdb:${Configdb}${ECHO_STYLE_00}\n"
    echo -e "${ECHO_STYLE_02}Please check the input parameters again !!!!${ECHO_STYLE_00}"
    echo "`printf %-120s|sed 's/ /=/g'`"
elif [ "${Opt}x" == "startx" ];then
    if [ -z "${Type}" ];then
        echo -e "${ECHO_STYLE_03}please enter type${ECHO_STYLE_00}" 
        echo -e "${ECHO_STYLE_03}--type=[mongod|arbiter|config|mongos] ${ECHO_STYLE_00}\n" 
        exit 1
    else
        if [ -z "${Enauth}" ];then
            Enauth=${Enauth:=false}
            echo -e "${ECHO_STYLE_05}the auth set the default ${Enauth} ${Shard}${ECHO_STYLE_00}\n" 
        fi
        if [ -z "${Port}" ];then
            echo -e "${ECHO_STYLE_03}please enter port${ECHO_STYLE_00}" 
            echo -e "${ECHO_STYLE_03}--port=i ${ECHO_STYLE_00}\n" 
            exit 1
        else
            echo -e "\n${ECHO_STYLE_01}Opt:${Opt}, Type:${Type}, Enauth:${Enauth}, Port:${Port}${ECHO_STYLE_00}\n"
        fi
    fi
elif [ "${Opt}x" == "stopx" ];then
    if [ -z "${Host}" ];then
        Host=${Host:=127.0.0.1}
        echo -e "${ECHO_STYLE_05}the host set the default 127.0.0.1${ECHO_STYLE_00}\n"
    fi
    if [ -z "${Port}" ];then
        echo -e "${ECHO_STYLE_03}please enter port${ECHO_STYLE_00}" 
        echo -e "${ECHO_STYLE_03}--port=i ${ECHO_STYLE_00}\n" 
        exit 1
    else
        echo -e "\n${ECHO_STYLE_01}Opt:${Opt}, Host:${Host}, Port:${Port}${ECHO_STYLE_00}\n"
    fi
elif [ "${Opt}x" == "restartx" ];then
    if [ -z "${Type}" ];then
        echo -e "${ECHO_STYLE_03}please enter type${ECHO_STYLE_00}" 
        echo -e "${ECHO_STYLE_03}--type=[mongod|arbiter|config] ${ECHO_STYLE_00}\n" 
        exit 1
    else
        if [ -z "${Port}" ];then
            echo -e "${ECHO_STYLE_03}please enter port${ECHO_STYLE_00}" 
            echo -e "${ECHO_STYLE_03}--port=i ${ECHO_STYLE_00}\n" 
            exit 1
        else
            if [ -z "${Enauth}" ];then
                Enauth=${Enauth:=false}
                echo -e "${ECHO_STYLE_05}the auth set the default ${Shard}${ECHO_STYLE_00}\n" 
            fi
            echo -e "\n${ECHO_STYLE_01}Opt:${Opt}, Type:${Type}, Enauth:${Enauth}, Port:${Port}${ECHO_STYLE_00}\n"
        fi
    fi
elif [ "${Opt}x" == "initrsx" ];then
    if [ -z "${Replset}" ];then
        echo -e "${ECHO_STYLE_03}please enter replset${ECHO_STYLE_00}" 
        echo -e "${ECHO_STYLE_03}--replset=s ${ECHO_STYLE_00}\n" 
        exit 1
    fi
    if [ -z "${Data_nodes}" ];then\
        echo -e "${ECHO_STYLE_03}Data nodes must be specified to initailize replication\n${ECHO_STYLE_00}"
        echo -e "${ECHO_STYLE_03}--dtnd='s' ${ECHO_STYLE_00}\n" 
        exit 1
    fi
    echo -e "\n${ECHO_STYLE_01}Opt:${Opt}, Replset:${Replset}, Data_nodes:'${Data_nodes}', Arbiter_nodes:'${Arbiter_nodes}${ECHO_STYLE_00}'\n"
fi
}

getconf(){
Mongo_pktconf="mongo-versionl-list"
Mongopktconf_url="http://tools-dba.xxx /dbasoft/Mongo/${Mongo_pktconf}"
Testcode=$(wget -S ${Mongopktconf_url} -O ${Scriptpath}/${Mongo_pktconf} 2>&1|grep -i -oP '(?<=HTTP/[0-9].[0-9]\s)[0-9]{3}(?=\s.*)')
if [ ${Testcode} -ne 200 ];then
    echo -e "download config file is error and code:${Testcode}\n"
    if [ ! -f ${Scriptpath}/${Mongo_pktconf} ];then
        echo "There is no mongo-versionl-list config file locally"
        exit 1
    fi
fi
}
getconf

Tmpfile=`mktemp`
awk -F'[ \t]+' '{if(!NF || /^#/){next} else if (match($1 , /^\[([a-zA-Z].*)\]/, arry)){v=arry[1]} else {print v,$NF}}' ${Mongo_pktconf} > ${Tmpfile}
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
Pwd="`pwd`"
mkdir -p /tmp/temp;cd /tmp/temp
rm ${Tmpfile}
cd $Pwd
}
getdbinfo

select_mongov(){
mongov_arr=(${!dbinfo[@]})
for i in ${!mongov_arr[@]}
    do  
        echo -e ${ECHO_STYLE_05}${i}${ECHO_STYLE_00}"):"${mongov_arr[$i]}
    done
echo -e ${ECHO_STYLE_05}q${ECHO_STYLE_00}"):"exit
}

get_mongopkt(){
key=$1
value=${dbinfo[$key]}
value_length=${#dbinfo[$key]}
if [ ${value_length} -ne 0 ];then
    mongopkt_arr=(${dbinfo[${key}]//,/ })
    for i in ${!mongopkt_arr[@]}
        do
            echo -e ${ECHO_STYLE_05}${i}${ECHO_STYLE_00}"):"$(echo ${mongopkt_arr[$i]}|awk -F'[=:]+' '{print$6}')
        done
    echo -e "${ECHO_STYLE_05}q${ECHO_STYLE_00}):exit"
    echo -e "${ECHO_STYLE_05}b${ECHO_STYLE_00}):Go back to your superior and re-select the mongo version"
else
    echo -e "\n===please check key name: $key $value===\n"
fi
}

choise_mongo(){
while true
    do
        select_mongov
        echo -e "\n####Please select the version number of Mongo package####"
        read -p ":" select_mongov
        case $select_mongov in
             [0-9]*) 
                 if [ $select_mongov -le ${#mongov_arr[@]} ];then
                 mongo_pkt=""
                 while true
                     do
                         mongo_vname=${mongov_arr[$select_mongov]}
                         if [ -z "$mongo_pkt" -a -n "$mongo_vname" ];then
                             get_mongopkt $mongo_vname
                             echo -e  "\n####Please select the file number of Mongo package####"
                             read -p ":" select_mongopkt
                             case $select_mongopkt in 
                                  [0-9]*) 
                                      if [ $select_mongopkt -le ${#mongopkt_arr[@]} ];then
                                          Mongo_basedir="${Basedir}/$(echo ${mongopkt_arr[$select_mongopkt]}|awk -F'[=:]+' '{print$2}')"
                                          Mongo_datadir="${Datadir}/$(echo ${mongopkt_arr[$select_mongopkt]}|awk -F'[=:]+' '{print$4}')"
                                          mongo_pkt=$(echo ${mongopkt_arr[$select_mongopkt]}|awk -F'[=:]+' '{print$6}')
                                          echo "mongo_basedir=${Mongo_basedir},mongo_datadir=${Mongo_datadir}" >${Add_mongo_conf}
                                      else
                                          echo -e "\n==== you input ${select_mongopkt} please enter less than ${#mongopkt_arr} number====\n"
                                          echo -e "Please choose again......\n"
                                      fi
                                      ;; 
               
                                  q|Q) 
                                      echo -e "you select q to exit........\n"
                                      exit 1
                                      ;; 
                                  b|B) 
                                      echo -e "you select b Go back to your superior and re-select the  mongo package version........\n"
                                      break 1
                                      ;; 
                                  *) 
                                     echo -e "please choise the number of mongo package\n"
                                     ;;
                             esac    
                         else
                             linux_release=$(cat /etc/redhat-release)
                             echo -e "\n####${ECHO_STYLE_09}Linux system version: ${linux_release}${ECHO_STYLE_00}####"
                             echo -e "\n====${ECHO_STYLE_10}You Select Package: ${mongo_pkt}${ECHO_STYLE_00}====\n"
                             echo -e "${ECHO_STYLE_05}b${ECHO_STYLE_00}):Go back re-select the mongo installation package"
                             echo -e "${ECHO_STYLE_05}run${ECHO_STYLE_00}):Please input run to start installing Mongo"
                             read -p ":" run
                             if [ "$run"x == "bx" ];then
                                 mongo_pkt="" #go bak re-select
                             elif [ "$run"x == "runx" ];then
                                 Init_mongofile=$mongo_pkt
                                 break 2 #exit and installing Mongo
                             fi
                         fi
                     done
                 else
                     echo -e "\n==== you input ${select_mongov} please enter less than ${#mongov_arr[@]} number====\n"
                     echo -e "Please choose again......\n"
                 fi
                 ;;
             q|Q) 
                 echo -e "you select q to exit........\n"
                 exit 1
                 ;; 
             *) 
                echo -e "please choise the number of mongo version\n"
                ;;
        esac    
done
}

initmongo(){
choise_mongo

if [ -d /home/mongo ]&& id mongo >/dev/null;then
    echo -e "The mongo account or the mongo home already exist\n"
else
    useradd mongo
fi
if [ -z "`mount|awk '/\/data/'`" ]&&[ ! -L "${Datadir}" ];then
    if [ ! -d "${Datadir}" ]&&[ -n "`mount|awk '/\/app/'`" ];then
        mkdir -p /app/data
        ln -s /app/data/ /data
    else
        echo "${Datadir} is a directory or app not mount on disk please check it"
        exit 1
    fi
else
    echo  "${Datadir} mount on disk or exsist a symbolic link"
fi

Softpath="/data/soft/"
if [ ! -d $Softpath ];then
    mkdir -p $Softpath
fi
Pwd="`pwd`"
mkdir -p /tmp/temp;cd /tmp/temp
if [ ! -f ${Softpath}${Init_mongofile} ];then
    wget http://tools-dba.xxx/dbasoft/Mongo/${Init_mongofile} -O ${Softpath}${Init_mongofile}
else
    echo "The ${Softpath}${Init_mongofile} is exist"
fi
Md5url="http://tools-dba.xxx/dbasoft/Mongo/${Init_mongofile}.md5"
Testcode=$(curl -I -s ${Md5url}|grep -i -oP '(?<=HTTP/[0-9].[0-9]\s)[0-9]{3}(?=\s.*)')
if [ ${Testcode} -eq 200 ];then
    Filemd5=$(curl -s ${Md5url})
else
    echo "Filemd5 is error and url down code:${Testcode}"
    exit 1
fi
Md5result=$(md5sum ${Softpath}${Init_mongofile}|awk '{printf$1}')
if [ ! -d ${Mongo_basedir} ];then
    if [ -n "${Md5result}" ]&&[ ${Md5result} == ${Filemd5} ];then
        tar -zxvpPf ${Softpath}${Init_mongofile}
        rm ${Softpath}${Init_mongofile}
    else
        echo "Please check the ${Softpath}${Init_mongofile} md5"
        rm ${Softpath}${Init_mongofile}
        exit 1
    
    fi
else
    echo "The ${Mongo_basedir} is exist"
    rm ${Softpath}${Init_mongofile}
    exit 1
fi
cd $Pwd
}

init_mongopath(){
if grep "transparent_hugepage" /etc/rc.local >/dev/null;then
    echo "mongo transparent_hugepage set exists"
else
    cat >>/etc/rc.local <<EOF

#set mongodb
if test -f /sys/kernel/mm/transparent_hugepage/enabled; then
   echo never > /sys/kernel/mm/transparent_hugepage/enabled
fi
if test -f /sys/kernel/mm/transparent_hugepage/defrag; then
   echo never > /sys/kernel/mm/transparent_hugepage/defrag
fi

EOF
fi

if test -f /sys/kernel/mm/transparent_hugepage/enabled; then
   echo never > /sys/kernel/mm/transparent_hugepage/enabled
fi

if test -f /sys/kernel/mm/transparent_hugepage/defrag; then
   echo never > /sys/kernel/mm/transparent_hugepage/defrag
fi

if grep "add for mongo" /etc/security/limits.conf >/dev/null;then
    echo "mongo limit already exists"
else
    cat >>/etc/security/limits.conf <<EOF

##add for mongo
mongo soft nofile 653360
mongo hard nofile 653360
mongo soft nproc 326680
mongo hard nproc 326680
mongo soft stack unlimited
mongo hard stack unlimited
EOF
cat /etc/security/limits.conf
fi

if grep "add for mongo" /etc/sysctl.conf >/dev/null;then
    echo "mongo sysctl already exists"
else
    cat >>/etc/sysctl.conf <<EOF

##add for mongo
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
cat /etc/sysctl.conf
sysctl -p
fi
}

alias_mongod(){
if [ "${Type}x" == "mongosx" ];then
   Mongo_cmd="mongos"
else
   Mongo_cmd="mongod"
fi

Pwd_file="/home/mongo/.user.root.cnf"
if [ ! -f $Pwd_file ];then
    cat >$Pwd_file<< eof
db.getSisterDB("admin").auth("root","gOme_@Root")
eof
fi
chown mongo:mongo $Pwd_file
chmod 600 $Pwd_file

if ! egrep "mongo.${Port}.login" "${Mongo_bash_profile}" >/dev/null;then
    echo """alias mongo.${Port}.login='${Mongo_basedir}/bin/mongo 127.0.0.1:${Port}/admin --shell $Pwd_file'"""
    echo -e "\n#set mongo alias" >>"${Mongo_bash_profile}"
    echo """alias mongo.${Port}.login='${Mongo_basedir}/bin/mongo 127.0.0.1:${Port}/admin --shell $Pwd_file'""" >>"${Mongo_bash_profile}"
else
    echo -e "alias mongo.${Port}.login already exists\n"
fi

if ! egrep "mongo.${Port}.up" "${Mongo_bash_profile}"  >/dev/null;then
    echo """alias mongo.${Port}.up='numactl --interleave=all ${Mongo_basedir}/bin/${Mongo_cmd} -f ${Mongo_basedir}/etc/${Mongo_type_insname}.conf'"""
    echo """alias mongo.${Port}.up='numactl --interleave=all ${Mongo_basedir}/bin/${Mongo_cmd} -f ${Mongo_basedir}/etc/${Mongo_type_insname}.conf'""" >>"${Mongo_bash_profile}"
else
   echo -e "alias mongo.${Port}.up already exists\n"
fi

if ! egrep "${Mongo_basedir}/bin/${Mongo_cmd} -f ${Mongo_basedir}/etc/${Mongo_type_insname}.conf" /etc/rc.local >/dev/null;then
    cat >>/etc/rc.local<<EOF

#set start mongodb
su - mongo -c 'numactl --interleave=all ${Mongo_basedir}/bin/${Mongo_cmd} -f ${Mongo_basedir}/etc/${Mongo_type_insname}.conf'
EOF
else
   echo -e "The mongodb start setting already exists\n"
fi
}


get_key(){
Shard=$1
if [ "${Shard}x" == "truex" ]||[ "${Configsvr}x" == "truex" ];then
    Replset="Gome_mongo_shard"
else
    Replset=$2
fi
Mongod_key_file="${Mongo_basedir}/etc/keyfile_${Mongo_port}"
echo "`date '+%Y-%m-%d'` 自定义密码随机串 on ${Replset}"|openssl enc -base64 >${Mongod_key_file}
touch ${Mongod_key_file}
chmod 600 ${Mongod_key_file}
chown mongo:mongo ${Mongod_key_file}
}

add_mongod(){
if [ ! -f "${Add_mongo_conf}" ];then
    choise_mongo
else
    Mongo_basedir=$(awk -F'[=, ]+' '{print$2}' $Add_mongo_conf)
    Mongo_datadir=$(awk -F'[=, ]+' '{print$4}' $Add_mongo_conf)
    if [ -z "$Mongo_basedir" -o -z "$Mongo_datadir" ];then
        echo -e "\nMongo_basedir=${Mongo_basedir} or Mongo_datadir=${Mongo_datadir}\n"
        echo "Mongo_basedir or Mongo_datadir get failed Please check the $Add_mongo_conf"
        exit 1
    fi
fi
Mongo_type=$1
Mongo_port=$2
Mongo_type_insname=${Mongo_type}${Mongo_port}
Shardsvr=$3
Replset=$4
Max_conn=$5
Oplog_size=$6
Wt_cache_size=$7
Mongo_ins_datadir="${Mongo_datadir}/${Mongo_type_insname}"
Mongod_default_conf="${Mongo_basedir}/etc/shard.conf.default"
Mongod_conf_file="${Mongo_basedir}/etc/${Mongo_type_insname}.conf"
Mongod_key_file="${Mongo_basedir}/etc/keyfile_${Mongo_port}"
if ! egrep "mongo.${Port}.login" "${Mongo_bash_profile}" >/dev/null;then
    if [ ! -z "${Mongo_basedir}" -a ! -z "${Mongo_datadir}" ];then
        if [ -f ${Mongod_default_conf} ];then
            if [ ! -d ${Mongo_ins_datadir} ]&&[ ! -f ${Mongod_conf_file} ]&&[ ! -f ${Mongod_key_file} ];then
                mkdir -p ${Mongo_ins_datadir}/{db,log,run}
                cp ${Mongod_default_conf} ${Mongod_conf_file}
                sed -i -e "s/{27017}/${Mongo_port}/g" -e "s/{shard}/${Mongo_type_insname}/g" -e "s/{replset}/${Replset}/g" \
                       -e "s/{max_conn}/${Max_conn}/g" -e "s/{oplog_size}/${Oplog_size}/g" \
                       -e "s/{wt_cache_size}/${Wt_cache_size}/g" ${Mongod_conf_file}

                if [ "${Shardsvr}x" == "truex" ];then
                    sed -i "/shardsvr=true/s/^#//" ${Mongod_conf_file}
                fi

                get_key "${Shard}" "${Replset}"
                chown mongo:mongo -R ${Mongo_basedir}/etc
                chown mongo:mongo -R ${Mongo_ins_datadir}
                alias_mongod
                start_mongo "${Port}"
            else
                echo -e "The mongo datadir ${Mongo_ins_datadir} Or conf file ${Mongod_conf_file} Or key file ${Mongod_key_file} already exists\n"
                exit 1 
            
            fi
        else
            echo -e "The mongo defautl conf file ${Mongod_default_conf}  not exists\n"
            echo -e "please initialize Mongo installation\n"
            exit 1 
        fi
    else
        echo -e "The Mongo_basedir or Mongo_datadir variable not obtained\n"
        exit 1
    fi
else
    echo -e "The mongo instance ${Port} already exists\n"
    exit 1
fi
}

add_config(){
if [ ! -f "${Add_mongo_conf}" ];then
    choise_mongo
else
    Mongo_basedir=$(awk -F'[=, ]+' '{print$2}' $Add_mongo_conf)
    Mongo_datadir=$(awk -F'[=, ]+' '{print$4}' $Add_mongo_conf)
    if [ -z "$Mongo_basedir" -o -z "$Mongo_datadir" ];then
        echo -e "\nMongo_basedir=${Mongo_basedir} or Mongo_datadir=${Mongo_datadir}\n"
        echo "Mongo_basedir or Mongo_datadir get failed Please check the $Add_mongo_conf"
        exit 1
    fi
fi
Mongo_type=$1
Mongo_port=$2
Configsvr=$3
Mongo_type_insname=${Mongo_type}${Mongo_port}
Shard="true"
Replset=$4
Max_conn=$5
Oplog_size=$6
Wt_cache_size=$7
Mongo_ins_datadir="${Mongo_datadir}/${Mongo_type_insname}"
Mongod_default_conf="${Mongo_basedir}/etc/shard.conf.default"
Config_conf_file="${Mongo_basedir}/etc/${Mongo_type_insname}.conf"
Mongod_key_file="${Mongo_basedir}/etc/keyfile_${Mongo_port}"
if ! egrep "mongo.${Port}.login" "${Mongo_bash_profile}" >/dev/null;then
    if [ ! -z "${Mongo_basedir}" -a ! -z "${Mongo_datadir}" ];then
        if [ -f ${Mongod_default_conf} ];then
            if [ ! -d ${Mongo_ins_datadir} ]&&[ ! -f ${Config_conf_file} ]&&[ ! -f ${Mongod_key_file} ];then
                if [ "${Mongo_type}x" == "configx" ]&&[ "${Configsvr}x" != "truex" ];then
                    echo -e "\n${ECHO_STYLE_06}Type setting config configsvr must be set to true${ECHO_STYLE_00}\n"
                    exit 1 
                fi 
                mkdir -p ${Mongo_ins_datadir}/{db,log,run}
                cp ${Mongod_default_conf} ${Config_conf_file}
                sed -i -e "s/{27017}/${Mongo_port}/g" -e "s/{shard}/${Mongo_type_insname}/g" -e "s/{replset}/${Replset}/g" \
                       -e "s/{max_conn}/${Max_conn}/g" -e "s/{oplog_size}/${Oplog_size}/g" \
                       -e "s/{wt_cache_size}/${Wt_cache_size}/g" ${Config_conf_file}

                if [ "${Configsvr}x" == "truex" ];then
                    if ! egrep "^configsvr=true" ${Config_conf_file} >/dev/null;then
                        sed -i '/replSet=/i\configsvr=true' ${Config_conf_file}
                    else
                        echo -e "\n${ECHO_STYLE_06}Warning!!! configsvr is set to true${ECHO_STYLE_00}\n"
                    fi
                fi

                get_key "${Shard}" "${Replset}"
                chown mongo:mongo -R ${Mongo_basedir}/etc
                chown mongo:mongo -R ${Mongo_ins_datadir}
                alias_mongod
                start_mongo "${Port}"
            else
                echo -e "The mongo datadir ${Mongo_ins_datadir} Or conf file ${Config_conf_file} Or key file ${Mongod_key_file} already exists\n"
                exit 1 
            
            fi
        else
            echo -e "The mongo defautl conf file ${Mongod_default_conf}  not exists\n"
            echo -e "please initialize Mongo installation\n"
            exit 1 
        fi
    else
        echo -e "The Mongo_basedir or Mongo_datadir variable not obtained\n"
        exit 1
    fi
else
    echo -e "The mongo instance ${Port} already exists\n"
    exit 1
fi
}

get_mongos_conf(){
Mongos_conf_file=$1
Mongo_port=$2
Configdb_sets=$3
Mongo_basedir=$4
Mongo_datadir=$5
Mongos_db=$6
Max_conn=$7
if [ ! -f ${Mongos_conf_file} ];then
    cat >${Mongos_conf_file} <<EOF
bind_ip=0.0.0.0
port={30000}
configdb={configdb_sets}
logpath={mongo_datadir}/{mongos_db}/log/mongos.log
pidfilepath={mongo_datadir}/{mongos_db}/run/mongos.pid
#keyFile={mongo_basedir}/etc/keyfile_{30000}
nounixsocket=false
unixSocketPrefix={mongo_datadir}/{mongos_db}/run
logappend=true
logRotate=rename
maxConns={max_conn}
slowms=100
fork=true
EOF
sed -i -e "s#{30000}#${Mongo_port}#g" -e "s#{configdb_sets}#${Configdb_sets}#g" -e "s#{mongo_basedir}#${Mongo_basedir}#g" -e "s#{mongo_datadir}#${Mongo_datadir}#g" \
       -e "s#{mongos_db}#${Mongos_db}#g" -e "s#{max_conn}#${Max_conn}#g" ${Mongos_conf_file}

else
    echo -e "The mongos conf file ${Mongos_conf_file} already exists\n"
    exit 1
fi
}

add_mongos(){
Shard="true"
if [ ! -f "${Add_mongo_conf}" ];then
    choise_mongo
else
    Mongo_basedir=$(awk -F'[=, ]+' '{print$2}' $Add_mongo_conf)
    Mongo_datadir=$(awk -F'[=, ]+' '{print$4}' $Add_mongo_conf)
    if [ -z "$Mongo_basedir" -o -z "$Mongo_datadir" ];then
        echo -e "\nMongo_basedir=${Mongo_basedir} or Mongo_datadir=${Mongo_datadir}\n"
        echo "Mongo_basedir or Mongo_datadir get failed Please check the $Add_mongo_conf"
        exit 1
    fi
fi
Mongo_type=$1
Mongo_port=$2
Mongo_type_insname=${Mongo_type}${Mongo_port}
Max_conn=$3
Mongo_ins_datadir="${Mongo_datadir}/${Mongo_type_insname}"
Mongos_conf_file="${Mongo_basedir}/etc/${Mongo_type_insname}.conf"
Mongos_key_file="${Mongo_basedir}/etc/keyfile_${Mongo_port}"
if ! egrep "mongo.${Port}.login" "${Mongo_bash_profile}" >/dev/null;then
    if [ ! -z "${Mongo_basedir}" -a ! -z "${Mongo_datadir}" ];then
        if [ -f ${Mongod_default_conf} ];then
            if [ ! -d ${Mongo_ins_datadir} ]&&[ ! -f ${Mongos_conf_file} ]&&[ ! -f ${Mongos_key_file} ];then
                mkdir -p ${Mongo_ins_datadir}/{db,log,run}
                get_mongos_conf "${Mongos_conf_file}" "${Mongo_port}" "${Configdb}" "${Mongo_basedir}" "${Mongo_datadir}" "${Mongo_type_insname}" "${Max_conn}"
                get_key "${Shard}" "${Replset}"
                chown mongo:mongo -R ${Mongo_basedir}/etc
                chown mongo:mongo -R ${Mongo_ins_datadir}
                alias_mongod
                #start_mongo "${Port}" #是否开启认证，需要手动启动指定
            else
                echo -e "The mongo datadir ${Mongo_ins_datadir} Or conf file ${Mongod_conf_file} Or key file ${Mongod_key_file} already exists\n"
                exit 1 
            
            fi
        else
            echo -e "The mongo defautl conf file ${Mongod_default_conf}  not exists\n"
            echo -e "please initialize Mongo installation\n"
            exit 1 
        fi
    else
        echo -e "The Mongo_basedir or Mongo_datadir variable not obtained\n"
        exit 1
    fi
else
    echo -e "The mongo instance ${Port} already exists\n"
    exit 1
fi
}

mongo_run(){
Cmd=$@
Mongo_client=$(egrep -i "mongo.${Port}.login" ${Mongo_bash_profile}|awk -F "[' ]+" '{print$3}')
Connrt=$(su - mongo -c "${Mongo_client:=mongo} ${Host:=127.0.0.1}:${Port}/admin $Cmd")
if [ $? -ne 0 ];then
    echo -e "Run failure\n" |tee -a ${Mongolog}
    return 1
fi
}

start_mongo(){
Port=$1
echo -e "---------start mongod${port}---------\n" |tee -a ${Mongolog}
Trlt="$(ss -lnpt|awk -v port="$Port" -v tresult="false" -F'['*:' ]+' '{if($NF ~ /mongo/){if ($4 == port){tresult="true"}}}END{print tresult}')"
if [ "${Trlt}x" == "truex" ];then
    echo -e "The port $Port is already running\n"
    exit 1
fi
Mongo_upcmd=$(egrep -i "mongo.${Port}.up" ${Mongo_bash_profile}|awk -F"'" '{print$2}')
if [ -z "${Mongo_upcmd}" ];then
    echo -e "Fail to get mongo conf file\n"
    echo -e "Please run su - mongo and alias command,check if the mongo.port.up exists\n"
    exit 1
else
    Mongo_cnf="$(echo ${Mongo_upcmd}|awk '{print$NF}')"
    Mongo_dbpath="$(awk -F '[ =]+' '{sub(/^[\t ]+/,"");{if ($1=="dbpath") print$NF}}' ${Mongo_cnf})"
    if [ "${Type}x" != "mongosx" ]&&[ ! -d "${Mongo_dbpath}" ];then
        echo -e "Please check if the Dbpath ${Mongo_dbpath} exists\n" |tee -a ${Mongolog}
        exit 1
    fi
fi
if [ -f "${Mongo_cnf}" ];then
    if [ "${Enauth}x" == "truex" ];then
        if [ "${Type}x" == "mongosx" ];then
            sed -i "/keyFile=.*/s/^#//" ${Mongo_cnf}
        else
            sed -i "/keyFile=.*/s/^#//" ${Mongo_cnf}
            sed -i "/auth=true/s/^#//" ${Mongo_cnf}
        fi
    fi

    su - mongo -c "${Mongo_upcmd}"
    while :
        do
            if ((Num<=9));then
                sleep ${Sleeptime}
                mongo_run "--quiet --eval 'db.getName()'"
                if [ "$Connrt" = "admin" ];then
                    echo -e "${ECHO_STYLE_05}mongo is run ok\n${ECHO_STYLE_00}" |tee -a ${Mongolog}
                    break
                else
                    echo -e "continue wite for mongo start\n" |tee -a ${Mongolog}
                fi
            else
                echo -e "please check the mongo${Port}\n" |tee -a ${Mongolog}
                exit 1
            fi
            let Num+=${Sleeptime}
        done
else
    echo -e "please check the startup mongo command\n" |tee -a ${Mongolog}
    exit 1
fi
}

stop_mongo(){
Host=$1 #暂时输入默认使用127.1连接
Port=$2
echo -e "---------stop mongo${port}---------\n" |tee -a ${Mongolog}
Trlt="$(ss -lnpt|awk -v port="$Port" -v tresult="false" -F'['*:' ]+' '{if($NF ~ /mongo/){if ($4 == port){tresult="true"}}}END{print tresult}')"
if [ "${Trlt}x" == "falsex" ];then
    echo -e "The mongo port $Port is not running\n"
    exit 1
fi
mongo_run "--eval 'db.shutdownServer()'"
if [ $? -ne 0 ];then
    echo -e "Failed to close Mongo\n" |tee -a ${Mongolog}
    exit 1
else
    echo -e "${ECHO_STYLE_05}Mongo closed successfully\n${ECHO_STYLE_00}" |tee -a ${Mongolog}
fi
}

restart_mongo(){
Host=$1 #重启只支持本地执行，所以使用127.1连接
Port=$2
stop_mongo "${Host}" "${Port}"
start_mongo "${Port}"
}

init_replicate(){
Rsinit_jsfile="/tmp/rsinit.js"
:>$Rsinit_jsfile

if [ -z "${Data_nodes}" -o -z "${Replset}" ];then
    echo -e "Data nodes and Replset name must be specified to initailize replication\n"
elif [ -n "${Data_nodes}" -a -z "${Arbiter_nodes}" ];then
    echo -e "Data nodes has been specified\n"
    initate_cmd "${Replset}" "${Data_nodes}" "${Arbiter_nodes}" >>$Rsinit_jsfile
    run_initate "${Replset}"
elif [ -n "${Data_nodes}" -a -n "${Arbiter_nodes}" ];then
    echo -e "Data and arbiter have nodes been specified\n"
    initate_cmd "${Replset}" "${Data_nodes}" "${Arbiter_nodes}" >>$Rsinit_jsfile
    run_initate "${Replset}"
fi
:>$Rsinit_jsfile
}

initate_cmd(){
Replset="$1"
Data_nodes="$2"
Arbiter_nodes="$3"
Id=0

echo "config = {"_id":'${Replset}',"
if [ "${Configsvr}x" = "truex" ];then
    echo "configsvr: true,"
fi
echo "`printf %-10s`members:["
if [ -n "${Data_nodes}" ];then
    while read line
    do
       if [ -n "$line" ];then
           if [ $Id -eq 0 ];then
               echo "`printf %-19s`{"_id":$Id,host:'$line',priority:2},"
           else
               echo "`printf %-19s`{"_id":$Id,host:'$line',priority:1},"
           fi
           let Id+=1
       fi
    done <<< "$(echo "${Data_nodes}"|awk '{split($0,ay,",");{for (i in ay) print ay[i]}}')"
fi
if [ -n "${Arbiter_nodes}" ];then
    echo "${Arbiter_nodes}"|awk '{split($0,ay,",");{for (i in ay) print ay[i]}}'|while read line
    do
        if [ -n "$line" ];then
            echo "`printf %-19s`{"_id":$Id,host:'$line',arbiterOnly:true},"
            let Id+=1
        fi
    done
fi
echo "`printf %-18s`]"
echo "`printf %-9s`};"
echo "rs.initiate(config);"
}

run_initate(){
Replset="$1"
#初始副本是连接数据节点参数的第一个ip:port
if [ ! -z "${Data_nodes}" ];then
    Host="$(echo "${Data_nodes}"|awk -F'[,:]' '{print$1}')"
    Port="$(echo "${Data_nodes}"|awk -F'[,:]' '{print$2}')"
    Mongo_client=$(egrep -i "mongo.${Port}.login" ${Mongo_bash_profile}|awk -F "[' ]+" '{print$3}')
    Mongo_upcmd=$(egrep -i "mongo.${Port}.up" ${Mongo_bash_profile}|awk -F"'" '{print$2}')
    if [ -z "${Mongo_upcmd}" ];then
        echo -e "Fail to get mongo conf file\n"
        echo -e "Please run su - mongo and alias command,check if the mongo.port.up exists\n"
        exit 1
    else
        Mongo_cnf="$(echo ${Mongo_upcmd}|awk '{print$NF}')"
        Conf_replSet="$(awk -F '[ =]+' '{sub(/^[\t ]+/,"");{if ($1=="replSet") print$NF}}' ${Mongo_cnf})"
        if [ -n "$Conf_replSet}" ]&&[ "${Conf_replSet}x" = "${Replset}x" ];then
            echo -e "${ECHO_STYLE_05}The replSet of conf check ok\n${ECHO_STYLE_00}" 
        else
            echo -e "The replSet of conf check fail ${ECHO_STYLE_03}Conf_replSet:${Conf_replSet} Replset:${Replset}\n${ECHO_STYLE_00}"
            exit 1
        fi
    fi

    Rep_list=(${Data_nodes} ${Arbiter_nodes})
    for rep in ${Rep_list[@]}
    do
        while read line
        do
            Connrt=$(${Mongo_client:=mongo} ${line}/admin --quiet --eval 'db.getName()')
            if [ "$Connrt" = "admin" ];then
                echo -e "${ECHO_STYLE_05}mongo $line connection is ok\n${ECHO_STYLE_00}" |tee -a ${Mongolog}
            else
                echo -e "Unable to connect to mongo $line\n" |tee -a ${Mongolog}
                exit 1
            fi
        done <<< "$(echo "${rep}"|awk '{split($0,ay,",");{for (i in ay) print ay[i]}}')"
    done

    ${Mongo_client:=mongo} ${Host:=127.0.0.1}:${Port}/admin <<EOF 
    $(cat $Rsinit_jsfile)
EOF
    if [ $? -ne 0 ];then
        echo -e "Failed to init Mongo replicate\n" |tee -a ${Mongolog}
        exit 1
    else
        echo -e "${ECHO_STYLE_05}Mongo replicated successfully\n${ECHO_STYLE_00}" |tee -a ${Mongolog}
        while true
            do
                if ((Num<=300));then
                    sleep ${Sleeptime}
                    Master_conn=$(${Mongo_client:=mongo} ${Host:=127.0.0.1}:${Port}/admin --quiet --eval 'rs.isMaster().primary')
                    if [ -n "$Master_conn" ]&& echo "$Master_conn"|egrep '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}:[0-9]{5}$' >/dev/null;then
                        add_grant
                        break
                    else
                        echo -e "Continue witing ${Num} for repliacate normal\n" |tee -a ${Mongolog}
                    fi
                else
                    echo -e "${ECHO_STYLE_06}Please check whether there is a primary role\n${ECHO_STYLE_00}"
                    exit 1
                fi
                let Num+=${Sleeptime}
            done

    fi
fi
}

#创建账号
add_grant(){
echo -e "===Start grant===\n"
${Mongo_client:=mongo} ${Master_conn}/admin --quiet <<EOF 
use admin
db.createUser(
  {
    user: "xxx",
    pwd: "xxx",
    roles: [ { role: "root", db: "admin" } ]
  }
);



db.createUser(
  {
    user: "xxx",
    pwd: "xxx",
    roles: [ { role: "clusterMonitor",db: "admin" },
             { role: "readAnyDatabase",db: "admin" }
           ],
  }
);



db.getSiblingDB("admin").createRole({ "role": "listCollections",
      "privileges": [
         { "resource": { "anyResource": true },
           "actions": [ "listCollections" ]
         }
      ],
      "roles": []
   }
);


var cfg=rs.conf()
cfg.members[0].priority=1
rs.reconfig(cfg)
EOF
if [ $? -eq 0 ];then
    echo -e "${ECHO_STYLE_05}Grant successfully\n${ECHO_STYLE_00}" |tee -a ${Mongolog}
else
    echo -e "${ECHO_STYLE_03}Grant failure\n${ECHO_STYLE_00}" |tee -a ${Mongolog}
    exit 1
fi
}

yumpkt(){
yum install -y readline-devel openssl-libs* \
sysstat lrzsz screen dstat vim unzip numactl.x86_64
} 

install_mtools(){
wget -S http://tools-dba.xxx/script/dbascript/deploy_mongodb-mtools.sh -O /usr/local/scripts/deploy_mongodb-mtools.sh 
sh /usr/local/scripts/deploy_mongodb-mtools.sh
}


setup_monitor(){

}


case $1 in
        --help)
            show_usage; exit 0
            ;;
        -v|-V|--version)
            show_version; exit 0
            ;;
        --opt=initmongo)
            getargs $@
            initmongo
            init_mongopath
            yumpkt
            install_mtools
            setup_monitor
            ;;
        --opt=add)
            getargs $@
            if [ "${Type}x" = "mongodx" -o "${Type}x" = "arbiterx" ];then
                add_mongod "${Type}"  "${Port}" "${Shard}" "${Replset}" "${Max_conn}" "${Oplog_size}" "${Wt_cache_size}"
            elif [ "${Type}x" == "configx"  ];then
                add_config "${Type}"  "${Port}" "${Configsvr}" "${Replset}" "${Max_conn}" "${Oplog_size}" "${Wt_cache_size}"
            elif [ "${Type}x" = "mongosx" ];then
                add_mongos "${Type}" "${Port}" "${Max_conn}"
            fi
            ;;
        --opt=start)
            getargs $@
            if [ "${Type}x" = "mongodx" -o "${Type}x" = "arbiterx" ];then
                start_mongo "${Port}"
            elif [ "${Type}x" = "configx" ];then
                start_mongo "${Port}"
            elif [ "${Type}x" = "mongosx" ];then
                start_mongo "${Port}"
            fi
            ;;
        --opt=stop)
            getargs $@
            stop_mongo "${Host}" "${Port}"
            ;;
        --opt=restart)
            getargs $@
            if [ "${Type}x" = "mongodx" -o "${Type}x" = "arbiterx" ];then
                restart_mongo "127.0.0.1" "${Port}" #重启只支持本机执行所以ip使用127.0.0.1
            elif [ "${Type}x" = "configx" ];then
                restart_mongo "127.0.0.1" "${Port}" #重启只支持本机执行所以ip使用127.0.0.1
            elif [ "${Type}x" = "mongosx" ];then
                restart_mongo "127.0.0.1" "${Port}" #重启只支持本机执行所以ip使用127.0.0.1
            fi
            ;;
        --opt=initrs)
            getargs $@
            init_replicate
            ;;
        -C|--clean)
           clean
           ;;
        --yum)
           yumpkt
           ;;
        --setmtools)
           install_mtools
           ;;
        --setmonitor)
           setup_monitor
           ;;
        *)
           show_usage 
           ;;
esac
