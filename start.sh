#!/bin/bash

workDir="data"; # 定义节点数据存放目录

# 判断目录中是否存在配置文件
if [ ! -f "genesis.json" ]; then
echo "当前目录中不存在配置文件，请创建genesis.json"
fi

# 判断目录中是否存在geth
if [ -f "geth" ]; then
chmod 777 ./geth
else 
echo "当前目录不存在geth可执行文件，请自行下载"
fi

PORT=0
#判断当前端口是否被占用，没被占用返回0，反之1
function Listening {
   TCPListeningnum=`netstat -an | grep ":$1 " | awk '$1 == "tcp" && $NF == "LISTEN" {print $0}' | wc -l`
   UDPListeningnum=`netstat -an | grep ":$1 " | awk '$1 == "udp" && $NF == "0.0.0.0:*" {print $0}' | wc -l`
   (( Listeningnum = TCPListeningnum + UDPListeningnum ))
   if [ $Listeningnum == 0 ]; then
       echo "0"
   else
       echo "1"
   fi
}

#指定区间随机数
function random_range {
   shuf -i $1-$2 -n1
}

#得到随机端口
function get_random_port {
   templ=0
   while [ $PORT == 0 ]; do
       temp1=`random_range $1 $2`
       if [ `Listening $temp1` == 0 ] ; then
              PORT=$temp1
       fi
   done
   echo $PORT
   return $?
}

while (true)
do
echo "欢迎使用以太坊节点管理系统，输入序号选择不同的功能"
echo "1.创建一个节点 2.启动一个节点 3.查看所有的节点 4.停止一个节点 0.退出系统"
read order

case "$order" in 
	1)
		while (true)
		do
		read -p "请输入节点名称（字母+数组）：" nodeName
		if [ -d "./${workDir}/${nodeName}" ]; then
			echo "该节点名称已经存在"
		else 
			./geth --datadir ./${workDir}/${nodeName} init ./genesis.json		
			echo "节点${nodeName}创建成功"
			break;
		fi
		done	
		;;
	2)
		read -p "请输入要启动的节点名称：" nodeName
		# 校验节点名称是否存在，如果不存在则询问是否要初始化该节点
		if [ ! -d "./${workDir}/${nodeName}" ]; then
			echo "该节点名称不存在"
			read -p "是否要初始化${nodeName}节点（Y/N）：" yn
			if [ "$yn" == 'Y' ] || [ "$yn" == 'y'  ]; then
				./geth --datadir ./${workDir}/${nodeName} init ./genesis.json
                       		echo "节点${nodeName}创建成功"	
			else
				break;
			fi
							
		fi
		# 创建日志文件
		if [ ! -f "log" ]; then
			mkdir log
		fi
		touch ./log/${nodeName}.log
		# 找寻端口，从30303开始，找到一个没有被占用的端口
		port1=$(get_random_port 30303 33333) # 节点port
		port2=$(get_random_port 8545 9999) # rpc port		
		echo $port1
		echo $port2
		# 节点静默启动
		nohup ./geth --datadir ./${workDir}/${nodeName} --allow-insecure-unlock --port ${port1} --identity ${nodeName} --networkid 613 --rpc --ipcdisable  --rpccorsdomain "*" --rpcapi "db,eth,net,web3,personal,admin,miner" --rpcport ${port2} 2>> ./log/${nodeName}.log &
		echo "节点启动成功,节点端口为${port1},rpc端口为${port2}";
		;;		
	*)
		exit;
esac
done

