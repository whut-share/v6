#!/bin/bash

#检测root账户
[ $(id -u) != "0" ] && { echo "请切换至root账户执行此脚本."; exit 1; }

#全局变量
server_ip=`curl -s https://app.52ll.win/ip/api.php`
separate_lines="####################################################################"
Green_font_prefix="\033[32m" && Red_font_prefix="\033[31m" && Green_background_prefix="\033[42;37m" && Red_background_prefix="\033[41;37m" && Font_color_suffix="\033[0m"
Info="${Green_font_prefix}[信息]${Font_color_suffix}"
Error="${Red_font_prefix}[错误]${Font_color_suffix}"
Tip="${Green_font_prefix}[注意]${Font_color_suffix}"
Libsodiumr_file="/usr/local/lib/libsodium.so"
Gost_script="/root/gost/gost.sh"

#开始菜单
start_menu(){
clear
echo && echo -e "####################################################################
# 版本：V.2.3.5 2018-12-16                                         #
####################################################################
# [1] PM2管理后端                                                  #
# [2] 安装ssr节点                                                  #
# [3] 后端更多选项                                                 #
# [4] 一键安装加速                                                 #
# [5] 一键服务器测速                                               #
# [6] 更多功能                                                     #
####################################################################
# [a]卸载各类云盾 [b]查看回程路由 [c]简易测速 [d]检测BBR安装状态   #
# [e]配置防火墙 [f]列出开放端口 [g]更换默认源                      #
####################################################################
# [x]刷新脚本 [y]更新脚本 [z]退出脚本                              #
# 此服务器IP信息：${server_ip_info}
####################################################################"

read -e -p "请选择安装项[1-8]/[a-g]:" num
clear
case "$num" in
	1)
	pm2_list;;
	2)
	install_node;;
	3)
	python_more;;
	4)
	serverspeeder;;
	5)
    speedtest;;
	6)
	system_more;;
	a)
	uninstall_ali_cloud_shield;;
	b)
    detect_backhaul_routing;;
	c)
	superspeed;;
	d)
	check_bbr_installation;;
	e)
	configure_firewall;;
	f)
	yum install -y net-tools;netstat -lnp;;
	g)
	replacement_of_installation_source;;
	x)
	rm -rf /usr/bin/v6 && cp /root/v6.sh /usr/bin/v6 && chmod +x /usr/bin/v6
	v6;;
	y)
	update_the_shell;;
	z)
	echo "已退出.";exit 0;;
	*)
	clear
	echo -e "${Error}:请输入正确指令"
	sleep 2s
	start_menu
	;;
esac
}

keep_loop(){
#继续还是中止
echo ${separate_lines};echo -n "继续(y)还是中止(n)? [y/n]:"
	read -e -p "(默认: n):" yn
	[[ -z ${yn} ]] && yn="n"
	if [[ ${yn} == [Nn] ]]; then
	echo "已取消..." && exit 1
	else
		clear
		sleep 2s
		start_menu
	fi
}

reboot_system(){
	read -e -p "需重启服务器使配置生效,现在重启? [y/n]" is_reboot
	if [ ${is_reboot} = 'y' ]; then
		reboot
	else
		echo "需重启服务器使配置生效,稍后请务必手动重启服务器.";exit
	fi
}

#检查系统版本
check_sys(){
		if [[ -f /etc/redhat-release ]]; then
			release="centos"
		elif cat /etc/issue | grep -q -E -i "debian"; then
			release="debian"
		elif cat /etc/issue | grep -q -E -i "ubuntu"; then
			release="ubuntu"
		elif cat /etc/issue | grep -q -E -i "centos|red hat|redhat"; then
			release="centos"
		elif cat /proc/version | grep -q -E -i "debian"; then
			release="debian"
		elif cat /proc/version | grep -q -E -i "ubuntu"; then
			release="ubuntu"
		elif cat /proc/version | grep -q -E -i "centos|red hat|redhat"; then
			release="centos"
	        fi
}

#PM2-[1]
pm2_list(){
	echo "选项：[1]安装PM2 [2]配置PM2 [3]更新PM2 [4]卸载PM2"
	read pm2_option
	if [ ${pm2_option} = '1' ]; then
        install_pm2
    elif [ ${pm2_option} = '2' ]; then
        check_sys
        echo "$release"
        if [ ${release} = 'centos' ]; then
			use_centos_pm2
		else
			use_debian_pm2
		fi
    elif [ ${pm2_option} = '3' ]; then
        if [ ! -f /usr/bin/pm2 ]; then
            install_pm2
        else
            update_pm2
        fi
    elif [ ${pm2_option} = '4' ]; then
            if [ ! -f /usr/bin/pm2 ]; then
            echo "已经卸载pm2"
        else
            remove_pm2
        fi
	else
	echo "选项不在范围,操作中止.";exit 0
	fi
}

install_pm2(){
    #检查系统版本
    check_sys

	#判断/usr/bin/pm2文件是否存在
    if [ ! -f /usr/bin/pm2 ]; then
        echo "检查到您未安装pm2,脚本将先进行安装"
        #安装Node.js
        if [[ ${release} = "centos" ]]; then
            yum -y install xz
            yum -y install wget
        else
            apt -y install xz-utils
            apt -y install wget
        fi
	    #编译Node.js
        wget -N https://nodejs.org/dist/v9.11.2/node-v9.11.2-linux-x64.tar.xz
        tar -xvf node-v9.11.2-linux-x64.tar.xz
        #设置权限
        chmod +x /root/node-v9.11.2-linux-x64/bin/node
        chmod +x /root/node-v9.11.2-linux-x64/bin/npm
        #创建软连接
        rm -rf "/usr/bin/node"
        rm -rf "/usr/bin/npm"
        ln -s /root/node-v9.11.2-linux-x64/bin/node /usr/bin/node
        ln -s /root/node-v9.11.2-linux-x64/bin/npm /usr/bin/npm
        #升级Node
        npm i -g npm
        npm install -g npm
        #安装PM2
        npm install -g pm2 --unsafe-perm
    	 #创建软连接x2
    	if [ ! -f /usr/bin/pm2 ]; then
    		ln -s /root/node-v9.11.2-linux-x64/bin/pm2 /usr/bin/pm2
        else
    	    rm -rf "/usr/bin/pm2"
    	    ln -s /root/node-v9.11.2-linux-x64/bin/pm2 /usr/bin/pm2
        fi
        rm -rf /root/*.tar.xz

        # 替换掉默认的NOFILE限制
          # 替换掉默认的NOFILE限制
        sed -i 's/LimitNOFILE=infinity/LimitNOFILE=512000/' /root/node-v9.11.2-linux-x64/lib/node_modules/pm2/lib/templates/init-scripts/systemd.tpl
        sed -i 's/LimitNPROC=infinity/LimitNPROC=512000/' /root/node-v9.11.2-linux-x64/lib/node_modules/pm2/lib/templates/init-scripts/systemd.tpl
    else
        echo "已经安装pm2，请配置pm2"
    fi
}

use_centos_pm2(){
    if [ ! -f /usr/bin/killall ]; then
	    echo "检查到您未安装psmisc,脚本将先进行安装"
	    yum -y install psmisc
    fi

    #清空
    pm2 delete all

    #判断内存
    all=`free -m | awk 'NR==2' | awk '{print $2}'`
    used=`free -m | awk 'NR==2' | awk '{print $3}'`
    free=`free -m | awk 'NR==2' | awk '{print $4}'`

    echo "Memory usage | [All：${all}MB] | [Use：${used}MB] | [Free：${free}MB]"
    sleep 2s
    #判断几个后端
    ssr_dirs=()
    while IFS=  read -r -d $'\0'; do
        ssr_dirs+=("$REPLY")
    done < <(find /root/  -maxdepth 1 -name "shadowsocks*" -print0)

    ssr_names=()
    for ssr_dir in "${ssr_dirs[@]}"
    do
        ssr_names+=($(basename "$ssr_dir"))
    done

    max_memory_limit=512
    if [ $all -le 256 ] ; then
        max_memory_limit=192
    elif [ $all -le 512 ] ; then
        max_memory_limit=320
    fi

    rm -rf "/usr/bin/srs"
    echo "#!/bin/bash" >> /usr/bin/srs
    for ssr_name in "${ssr_names[@]}"
    do
        pm2 start /root/${ssr_name}/server.py --name $(echo ${ssr_name} | sed 's/shadowsocks-//') --max-memory-restart ${max_memory_limit}M  -o /dev/null -e /dev/null
		echo "pm2 restart $(echo ${ssr_name} | sed 's/shadowsocks-//')" >> /usr/bin/srs
    done
	chmod +x /usr/bin/srs


	rm -rf "/usr/bin/grs"
	#加入gost支持
    if [[ -e ${Gost_script} ]]; then
		source ${Gost_script}
		echo "#!/bin/bash" >> /usr/bin/grs
		echo "pm2 list|grep relay|awk '{print \$4}'|xargs pm2 restart" >> /usr/bin/grs
		chmod +x /usr/bin/grs
	fi

    #更换DNS至8888/1001
    if grep -Fq "8.8.8.8" "/etc/resolv.conf"
    then
        echo "已经update resolv.conf"
    else
        cp /etc/resolv.conf /etc/resolv.conf.bak
        /usr/bin/chattr -i /etc/resolv.conf && wget -N https://github.com/Super-box/v3/raw/master/resolv.conf -P /etc && /usr/bin/chattr +i /etc/resolv.conf
    fi

    # 取消文件数量限制
   if grep -Fq "hard nofile 512000" "/etc/security/limits.conf"
    then
        echo "已经update limits.conf"
    else
	    sed -i '$a * hard nofile 512000\n* soft nofile 512000\nroot hard nofile 512000\nroot soft nofile 512000' /etc/security/limits.conf
    fi

    # 取消systemd文件数量限制
    if grep -Fq "DefaultLimitCORE=infinity" "/etc/systemd/system.conf"
    then
        echo "已经update systemd.conf"
    else
	    sed -i '$a DefaultLimitCORE=infinity\nDefaultLimitNOFILE=512000\nDefaultLimitNPROC=512000' /etc/systemd/system.conf
		sed -i '$a DefaultLimitCORE=infinity\nDefaultLimitNOFILE=512000\nDefaultLimitNPROC=512000' /etc/systemd/user.conf
        systemctl daemon-reload
    fi

    #创建crontab
    if [ ! -f /etc/cron.d/456cron ] ; then
	    echo "未设置定时任务"
	else
        rm -rf /etc/cron.d/456cron
    fi

	echo 'SHELL=/bin/sh' >>  /etc/cron.d/456cron
	echo 'PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin' >>  /etc/cron.d/456cron

    if [ ! -f /root/ddns/cf-ddns.sh ] ; then
        echo "未检测到cf-ddns.sh"
    else
	    echo "添加DDNS定时启动"
        sleep 2s
        echo '###DDNS' >> /etc/cron.d/456cron
        echo '*/10 * * * * root bash /root/ddns/cf-ddns.sh 2>&1 > /dev/null' >> /etc/cron.d/456cron
    fi
    if [ ! -f /root/Application/telegram-socks/server.js ] ; then
        echo "未检测到socks5"
    else
	    echo "添加socks5定时启动"
        sleep 2s
        echo '###Socks5' >> /etc/cron.d/456cron
        echo '* */1 * * * root systemctl restart telegram 2>&1 > /dev/null' >> /etc/cron.d/456cron
    fi
    if [ ! -f /usr/local/gost/gostproxy ] ; then
        echo "未检测到gost"
    else
	    echo "添加gost定时启动"
        sleep 2s
        echo '###Gost' >> /etc/cron.d/456cron
        echo '0 3 * * * root gost start 2>&1 > /dev/null' >> /etc/cron.d/456cron
    fi

	if [ ! -f /root/rclone.cron ] ; then
        echo "未检测到rclone"
    else
	    echo "添加rclone定时同步"
        sleep 2s
        echo '###rclone' >> /etc/cron.d/456cron
        cat /root/rclone.cron >> /etc/cron.d/456cron
    fi
    #PM2定时重启
    echo '#DaliyJob' >> /etc/cron.d/456cron
    echo '1 */6 * * * root /usr/bin/pm2 flush 2>&1 > /dev/null' >> /etc/cron.d/456cron
    echo '2 3 */2 * * root /usr/bin/srs 2>&1 > /dev/null' >> /etc/cron.d/456cron
	echo '6 3 * * * root /usr/bin/grs > /dev/null' >> /etc/cron.d/456cron
    #清理缓存
    echo '5 3 * * * root /usr/bin/sync && echo 1 > /proc/sys/vm/drop_caches' >> /etc/cron.d/456cron
    echo '10 3 * * * root /usr/bin/sync && echo 2 > /proc/sys/vm/drop_caches' >> /etc/cron.d/456cron
    echo '15 3 * * * root /usr/bin/sync && echo 3 > /proc/sys/vm/drop_caches' >> /etc/cron.d/456cron
	#重启cron并备份
    /sbin/service crond restart
    #查看cron进程
    crontab -l
    sleep 2s
    #创建开机自启动
	pm2 save
	pm2 startup
	systemctl daemon-reload
	systemctl restart pm2-root

	#完成提示
	echo "########################################
# SS NODE 已安装完成                   #
########################################"
}

use_debian_pm2(){
    if [ ! -f /usr/bin/killall ]; then
	    echo "检查到您未安装psmisc,脚本将先进行安装"
	    apt-get install psmisc
    fi
	#清空
    pm2 delete all
    #判断内存
    all=`free -m | awk 'NR==2' | awk '{print $2}'`
    used=`free -m | awk 'NR==2' | awk '{print $3}'`
    free=`free -m | awk 'NR==2' | awk '{print $4}'`
    echo "Memory usage | [All：${all}MB] | [Use：${used}MB] | [Free：${free}MB]"
    sleep 2s
    #判断几个后端
    ssr_dirs=()
    while IFS=  read -r -d $'\0'; do
        ssr_dirs+=("$REPLY")
    done < <(find /root/  -maxdepth 1 -name "shadowsocks*" -print0)
    ssr_names=()
    for ssr_dir in "${ssr_dirs[@]}"
    do
        ssr_names+=($(basename "$ssr_dir"))
    done

	max_memory_limit=320
    if [ $all -le 256 ] ; then
        max_memory_limit=192
    elif [ $all -le 512 ] ; then
        max_memory_limit=300
    fi

	rm -rf "/usr/bin/srs"
    echo "#!/bin/bash" >> /usr/bin/srs
    for ssr_name in "${ssr_names[@]}"
    do
        pm2 start /root/${ssr_name}/server.py --name $(echo ${ssr_name} | sed 's/shadowsocks-//') --max-memory-restart ${max_memory_limit}M  -o /dev/null -e /dev/null
		echo "pm2 restart $(echo ${ssr_name} | sed 's/shadowsocks-//')" >> /usr/bin/srs
    done
	chmod +x /usr/bin/srs


	rm -rf "/usr/bin/grs"
	#加入gost支持
    if [[ -e ${Gost_script} ]]; then
		source ${Gost_script}
		echo "#!/bin/bash" >> /usr/bin/grs
		echo "pm2 list|grep relay|awk '{print \$4}'|xargs pm2 restart" >> /usr/bin/grs
		chmod +x /usr/bin/grs
	fi

    #更换DNS至8888/1001
    if grep -Fq "8.8.8.8" "/etc/resolv.conf"
    then
        echo "已经update resolv.conf"
    else
        cp /etc/resolv.conf /etc/resolv.conf.bak
        /usr/bin/chattr -i /etc/resolv.conf && wget -N https://github.com/Super-box/v3/raw/master/resolv.conf -P /etc && /usr/bin/chattr +i /etc/resolv.conf
    fi

	# 取消文件数量限制
   if grep -Fq "hard nofile 512000" "/etc/security/limits.conf"
    then
        echo "已经update limits.conf"
    else
	    sed -i '$a * hard nofile 512000\n* soft nofile 512000\nroot hard nofile 512000\nroot soft nofile 512000' /etc/security/limits.conf
    fi

    # 取消systemd文件数量限制
    if grep -Fq "DefaultLimitCORE=infinity" "/etc/systemd/system.conf"
    then
        echo "已经update systemd.conf"
    else
	    sed -i '$a DefaultLimitCORE=infinity\nDefaultLimitNOFILE=512000\nDefaultLimitNPROC=512000' /etc/systemd/system.conf
		sed -i '$a DefaultLimitCORE=infinity\nDefaultLimitNOFILE=512000\nDefaultLimitNPROC=512000' /etc/systemd/user.conf
        systemctl daemon-reload
    fi

    #创建crontab任务
    if [ ! -f /etc/cron.d/456cron ] ; then
	    echo "未部署定时任务"
	else
        rm -rf /etc/cron.d/456cron
    fi

	echo 'SHELL=/bin/bash' >>  /etc/cron.d/456cron
	echo 'PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin' >>  /etc/cron.d/456cron

    if [ ! -f /root/ddns/cf-ddns.sh ] ; then
    	echo "未检测到cf-ddns.sh"
    else
	    echo "添加DDNS定时启动"
        sleep 2s
        echo '###DDNS' >>  /etc/cron.d/456cron
        echo '*/10 * * * * root bash /root/ddns/cf-ddns.sh 2>&1 > /dev/null' >>  /etc/cron.d/456cron
    fi

    if [ ! -f /usr/local/gost/gostproxy ] ; then
        echo "未检测到gost"
    else
    	#Gost定时重启
	    echo "添加gost定时启动"
        sleep 2s
        echo '###Gost' >>  /etc/cron.d/456cron
        echo '0 1 * * * root gost start 2>&1 > /dev/null' >>  /etc/cron.d/456cron
    fi

	if [ ! -f /root/rclone.cron ] ; then
        echo "未检测到rclone"
    else
	    echo "添加rclone定时同步"
        sleep 2s
        echo '###rclone' >> /etc/cron.d/456cron
        cat /root/rclone.cron >> /etc/cron.d/456cron
    fi
	
    #PM2定时重启
    echo '#DaliyJob' >>  /etc/cron.d/456cron
    echo '1 */6 * * * root /usr/bin/pm2 flush 2>&1 > /dev/null' >>  /etc/cron.d/456cron
    echo '2 3 */2 * * root /usr/bin/srs > /dev/null' >>  /etc/cron.d/456cron
	echo '6 3 * * * root /usr/bin/grs > /dev/null' >>  /etc/cron.d/456cron
    #清理缓存
    echo '5 3 * * * root /usr/bin/sync && echo 1 > /proc/sys/vm/drop_caches' >>  /etc/cron.d/456cron
    echo '10 3 * * * root /usr/bin/sync && echo 2 > /proc/sys/vm/drop_caches' >>  /etc/cron.d/456cron
    echo '15 3 * * * root /usr/bin/sync && echo 3 > /proc/sys/vm/drop_caches' >>  /etc/cron.d/456cron
    #cron重启
    service cron restart
    service cron reload

    #查看cron进程
    crontab -l
    sleep 2s
    #创建开机自启动
	pm2 save
	pm2 startup
	#完成提示
	echo "########################################
# SS NODE 已安装完成                   #
########################################"
}

update_pm2(){
    #更新node.js
	npm i -g npm
	npm install -g npm
    #更新PM2
    npm install pm2@latest -g
    #PM2 update
    sleep 1s
    pm2 save
    pm2 update
    pm2 startup
}

remove_pm2(){
	if [ ! -f /usr/bin/pm2 ]; then
		echo "PM2已卸载"
	else
		npm uninstall -g pm2
		sleep 1s
		npm uninstall -g npm
		sleep 1s
		#卸载Node.js
		rm -rf "/usr/bin/node"
	    rm -rf "/usr/bin/npm"
	    rm -rf "/root/.npm"
        #卸载PM2
		rm -rf "/usr/bin/pm2"
		rm -rf "/root/.pm2"
		rm -rf /root/node*
		sleep 1s
		echo "PM2完成卸载"
		fi
}

Get_Dist_Version()
{
    if [ -s /usr/bin/python3 ]; then
        Version=`/usr/bin/python3 -c 'import platform; print(platform.linux_distribution()[1][0])'`
    elif [ -s /usr/bin/python2 ]; then
        Version=`/usr/bin/python2 -c 'import platform; print platform.linux_distribution()[1][0]'`
    fi
}


install_centos_ssr(){
    if [ ! -f /usr/bin/git ]; then
       yum -y install git
    fi

    read -e -p "后端名字是:(默认: idou):" Username
	[[ -z ${Username} ]] && Username="idou"

	git clone -b 456Dev "https://github.com/old-boys/shadowsocks.git" "/root/shadowsocks-${Username}"

	read -e -p "节点ID是:" UserNodeId
	read -e -p "数据库地址是:" UserDbHost
	read -e -p "数据库名称:" UserDbName
	read -e -p "数据库用户:" UserDbUser
	read -e -p "数据库密码:" UserDbPass

	read -e -p "NF启用DNS(默认:0): " EnableNFDns
	[[ -z ${EnableNFDns} ]] && EnableNFDns="0"
	if [ ${EnableNFDns} = '1' ]; then
		read -e -p "NF Dns地址: " NFDnsProxy
		net_line=`grep -n 'netflix dns' /root/shadowsocks-${Username}/userapiconfig.py | cut -d: -f 1`
		let nf_enable_line=net_line+1
		let nf_dns_line=net_line+2
		sed -i  "${nf_enable_line}s/^.*$/USE_NETFLIX_DNS = ${EnableNFDns}/"  /root/shadowsocks-${Username}/userapiconfig.py
		sed -i  "${nf_dns_line}s/^.*$/NETFLIX_DNS = '${NFDnsProxy}'/"  /root/shadowsocks-${Username}/userapiconfig.py
	fi

    sed -i "2s#1#${UserNodeId}#" /root/shadowsocks-${Username}/userapiconfig.py
    sed -i "31s#127.0.0.1#${UserDbHost}#" /root/shadowsocks-${Username}/userapiconfig.py
    sed -i "33s#ss#${UserDbUser}#" /root/shadowsocks-${Username}/userapiconfig.py
    sed -i "34s#ss#${UserDbPass}#" /root/shadowsocks-${Username}/userapiconfig.py
    sed -i "35s#shadowsocks#${UserDbName}#" /root/shadowsocks-${Username}/userapiconfig.py

	#更换DNS至8888/1001
    if grep -Fq "8.8.8.8" "/etc/resolv.conf"
    then
        echo "已经update resolv.conf"
    else
		cp /etc/resolv.conf /etc/resolv.conf.bak
	    /usr/bin/chattr -i /etc/resolv.conf && wget -N https://github.com/Super-box/v3/raw/master/resolv.conf -P /etc && /usr/bin/chattr +i /etc/resolv.conf
    fi

	cd /root
	Get_Dist_Version

	if [ ! -f /root/.update ]; then
		yum -y update --exclude=kernel*
		yum -y install git gcc python-setuptools lsof lrzsz python-devel libffi-devel openssl-devel iptables iptables-services
		yum -y groupinstall "Development Tools"
		yum -y install python-pip
		#第二次pip supervisor是否安装成功
		if [ -z "`pip`" ]; then
		curl -O https://bootstrap.pypa.io/get-pip.py
			python get-pip.py
			rm -rf *.py
		fi
		#第三次检测pip supervisor是否安装成功
		if [ -z "`pip`" ]; then
			if [ -z "`easy_install`"]; then
				wget http://peak.telecommunity.com/dist/ez_setup.py
				python ez_setup.py
			fi
			easy_install pip
		fi

		python -m pip install --upgrade pip

		pip install -I requests==2.9

		touch /root/.update
	fi


    if [[ -e ${Libsodiumr_file} ]]; then
		echo -e "libsodium 已安装"
	else
		echo -e "libsodium 未安装，开始安装..."
        wget https://raw.githubusercontent.com/whut-share/v6/master/libsodium-1.0.18.tar.gz
	    tar xf libsodium-1.0.18.tar.gz && cd libsodium-1.0.18
	    ./configure && make -j2 && make install
	    echo /usr/local/lib > /etc/ld.so.conf.d/usr_local_lib.conf
        ldconfig
    fi

	cd /root/shadowsocks-${Username}

	#第一次安装
	pip install -r requirements.txt

	#第二次检测是否成功
	if [ -z "`python -c 'import requests;print(requests)'`" ]; then
		mkdir python && cd python
		git clone https://github.com/shazow/urllib3.git && cd urllib3
		python setup.py install && cd ..
		git clone https://github.com/nakagami/CyMySQL.git && cd CyMySQL
		python setup.py install && cd ..
		git clone https://github.com/requests/requests.git && cd requests
		python setup.py install && cd ..
		git clone https://github.com/pyca/pyopenssl.git && cd pyopenssl
		python setup.py install && cd ..
		git clone https://github.com/cedadev/ndg_httpsclient.git && cd ndg_httpsclient
		python setup.py install && cd ..
		git clone https://github.com/etingof/pyasn1.git && cd pyasn1
		python setup.py install && cd ..
		rm -rf python
	fi
	systemctl stop firewalld.service
	systemctl disable firewalld.service
}

install_ubuntu_ssr(){

    if [ ! -f /usr/bin/git ]; then
        apt -y install git
    fi

    read -e -p "后端名字是:(默认: idou):" Username
	[[ -z ${Username} ]] && Username="idou"

	git clone -b 456Dev "https://github.com/old-boys/shadowsocks.git" "/root/shadowsocks-${Username}"

	if [ ! -f /root/.update ]; then
		apt-get -y update
		apt-get -y install build-essential wget iptables git supervisor lsof python-pip
		pip install -I requests==2.9

		touch /root/.update
	fi

	read -e -p "节点ID是:" UserNodeId
	read -e -p "数据库地址是:" UserDbHost
	read -e -p "数据库名称:" UserDbName
	read -e -p "数据库用户:" UserDbUser
	read -e -p "数据库密码:" UserDbPass

	read -e -p "NF启用DNS(默认:0): " EnableNFDns
	[[ -z ${EnableNFDns} ]] && EnableNFDns="0"
	if [ ${EnableNFDns} = '1' ]; then
		read -e -p "NF Dns地址: " NFDnsProxy
		net_line=`grep -n 'netflix dns' /root/shadowsocks-${Username}/userapiconfig.py | cut -d: -f 1`
		let nf_enable_line=net_line+1
		let nf_dns_line=net_line+2
		sed -i  "${nf_enable_line}s/^.*$/USE_NETFLIX_DNS = ${EnableNFDns}/"  /root/shadowsocks-${Username}/userapiconfig.py
		sed -i  "${nf_dns_line}s/^.*$/NETFLIX_DNS = '${NFDnsProxy}'/"  /root/shadowsocks-${Username}/userapiconfig.py
	fi

    sed -i "2s#1#${UserNodeId}#" /root/shadowsocks-${Username}/userapiconfig.py
    sed -i "31s#127.0.0.1#${UserDbHost}#" /root/shadowsocks-${Username}/userapiconfig.py
    sed -i "33s#ss#${UserDbUser}#" /root/shadowsocks-${Username}/userapiconfig.py
    sed -i "34s#ss#${UserDbPass}#" /root/shadowsocks-${Username}/userapiconfig.py
    sed -i "35s#shadowsocks#${UserDbName}#" /root/shadowsocks-${Username}/userapiconfig.py

	#更换DNS至8888/1001
    if grep -Fq "8.8.8.8" "/etc/resolv.conf"
    then
        echo "已经update resolv.conf"
    else
		cp /etc/resolv.conf /etc/resolv.conf.bak
	    /usr/bin/chattr -i /etc/resolv.conf && wget -N https://github.com/Super-box/v3/raw/master/resolv.conf -P /etc && /usr/bin/chattr +i /etc/resolv.conf
    fi

	#编译安装libsodium
    if [[ -e ${Libsodiumr_file} ]]; then
		echo -e "libsodium 已安装"
	else
		echo -e "libsodium 未安装，开始安装..."
        wget https://raw.githubusercontent.com/whut-share/v6/master/libsodium-1.0.18.tar.gz
	    tar xf libsodium-1.0.18.tar.gz && cd libsodium-1.0.18
	    ./configure && make -j2 && make install
	    echo /usr/local/lib > /etc/ld.so.conf.d/usr_local_lib.conf
        ldconfig
    fi

	pip install cymysql -i https://pypi.org/simple/

	#clone shadowsocks

	cd /root
	cd /root/shadowsocks-${Username}

	#第一次安装
	pip install -r requirements.txt
	#第二次检测是否成功
	if [ -z "`python -c 'import requests;print(requests)'`" ]; then
		mkdir python && cd python
		git clone https://github.com/shazow/urllib3.git && cd urllib3
		python setup.py install && cd ..
		git clone https://github.com/nakagami/CyMySQL.git && cd CyMySQL
		python setup.py install && cd ..
		git clone https://github.com/requests/requests.git && cd requests
		python setup.py install && cd ..
		git clone https://github.com/pyca/pyopenssl.git && cd pyopenssl
		python setup.py install && cd ..
		git clone https://github.com/cedadev/ndg_httpsclient.git && cd ndg_httpsclient
		python setup.py install && cd ..
		git clone https://github.com/etingof/pyasn1.git && cd pyasn1
		python setup.py install && cd ..
		rm -rf python
	fi
	chmod +x *.sh
}


install_node(){
	#check os version
	check_sys(){
		if [[ -f /etc/redhat-release ]]; then
			release="centos"
		elif cat /etc/issue | grep -q -E -i "debian"; then
			release="debian"
		elif cat /etc/issue | grep -q -E -i "ubuntu"; then
			release="ubuntu"
		elif cat /etc/issue | grep -q -E -i "centos|red hat|redhat"; then
			release="centos"
		elif cat /proc/version | grep -q -E -i "debian"; then
			release="debian"
		elif cat /proc/version | grep -q -E -i "ubuntu"; then
			release="ubuntu"
		elif cat /proc/version | grep -q -E -i "centos|red hat|redhat"; then
			release="centos"
	    fi
		bit=`uname -m`
	}
	install_ssr_for_each(){
		check_sys
		if [[ ${release} = "centos" ]]; then
			install_pm2
			install_centos_ssr
			use_centos_pm2
		else
			install_pm2
			install_ubuntu_ssr
			use_debian_pm2
		fi
	}

    install_ssr_for_each
	# 取消文件数量限制
    if grep -Fq "hard nofile 512000" "/etc/security/limits.conf"
    then
        echo "已经update limits.conf"
    else
	    sed -i '$a * hard nofile 512000\n* soft nofile 512000\nroot hard nofile 512000\nroot soft nofile 512000' /etc/security/limits.conf
    fi
    #iptables -P INPUT ACCEPT
    #iptables -F
    #iptables -X


#########################################################################################"
	clear;echo "########################################
# SS NODE 已安装完成                   #
########################################
# 启动SSR：pm2 start ssr               #
# 停止SSR：pm2 stop ssr                #
# 重启SSR：pm2 restart ssr             #
# 或：srs                              #
########################################"
}

#More-[5]
python_more(){
    echo "选项：[1]安装Gost服务器  [3]安装ocserv"
	read more_option
	if [ ${more_option} = '1' ]; then
		install_gost
	elif [ ${more_option} = '2' ]; then
		install_ocserv
	else
		echo "选项不在范围,操作中止.";exit 0
	fi
}

install_gost(){
           #检查文件gost.sh是否存在,若不存在,则下载该文件
		if [ ! -f /root/gost.sh ]; then
		   wget -N --no-check-certificate https://code.aliyun.com/supppig/gost/raw/master/gost.sh
            chmod +x gost.sh
            fi
            bash gost.sh
	    }

install_ocserv(){
        check_sys
        echo "$release"
        if [ ${release} = 'centos' ]; then
        	yum update -y
	        yum install ocserv radiusclient-ng unzip -y

                if ! wget -N --no-check-certificate https://github.com/Super-box/a5/raw/master/ocserv.zip -O /etc/ocserv.zip; then
		    echo -e "${Error} ocserv 服务 配置文件下载失败 !" && exit
	        fi
            unzip -o /etc/ocserv.zip -d /etc

                if ! wget -N --no-check-certificate https://github.com/Super-box/a5/raw/master/radiusclient-ng.zip -O /etc/radiusclient-ng.zip; then
		    echo -e "${Error} radius 服务 配置文件下载失败 !" && exiy
	        fi
                unzip -o /etc/radiusclient-ng.zip -d /etc

                if ! wget -N --no-check-certificate https://github.com/Super-box/v3/raw/master/setiptables.sh -O /root/setiptables.sh; then
                echo -e "${Error} iptables文件下载失败 !" && exit
	        fi
	            chmod +x /root/setiptables.sh
                bash /root/setiptables.sh
                rm -rf /root/setiptables.sh

                if ! wget --no-check-certificate https://raw.githubusercontent.com/ToyoDAdoubi/doubi/master/service/ocserv_debian -O /etc/init.d/ocserv; then
		        echo -e "${Error} ocserv 服务 管理脚本下载失败 !" && exit
	        fi
	            chmod +x /etc/init.d/ocserv
	            echo -e "${Info} ocserv 服务 管理脚本下载完成 !"
                /etc/rc.d/init.d/ocserv stop
	            chkconfig --add /etc/rc.d/init.d/ocserv
	            chkconfig /etc/rc.d/init.d/ocserv on
	            systemctl enable ocserv.service
	            systemctl restart ocserv.service
	            systemctl status ocserv.service
		else
			echo "懒得写了"

		fi
        }


#一键全面测速-[7]
speedtest(){
	#检查文件ZBench-CN.sh是否存在,若不存在,则下载该文件
	if [ ! -f /root/ZBench-CN.sh ]; then
		wget https://raw.githubusercontent.com/FunctionClub/ZBench/master/ZBench-CN.sh
		chmod +x ZBench-CN.sh
	fi
	   #执行测试
	   bash /root/ZBench-CN.sh
}

#More-[8]
system_more(){
    echo "选项：[1]添加SWAP [2]更改SSH端口 [3]DDNS动态脚本"
	read more_option
        if [ ${more_option} = '1' ]; then
            swap
	    elif [ ${more_option} = '2' ]; then
		    install_ssh_port
	    elif [ ${more_option} = '3' ]; then
	        ddns
	    else
		    echo "选项不在范围,操作中止.";exit 0
	    fi
}

swap(){
	echo "选项：[1]500M [2]1G [3]删除SWAP"
		read swap
	if [ ${swap} = '1' ]; then
		#判断/var/swapfile1文件是否存在
		if [ ! -f /var/swapfile1 ]; then
			#增加500Mb的Swap分区
			dd if=/dev/zero of=/var/swapfile1 bs=1024 count=512000
			mkswap /var/swapfile1;chmod 0644 /var/swapfile1;swapon /var/swapfile1
			echo "/var/swapfile1 swap swap defaults 0 0" >> /etc/fstab
			echo "已经成功添加SWAP"
		else
			echo "检查到您已经添加SWAP,无需重复添加"
		fi

	elif [ ${swap} = '2' ]; then
		#判断/var/swapfile1文件是否存在
		if [ ! -f /var/swapfile1 ]; then
		dd if=/dev/zero of=/var/swapfile1 bs=1024 count=1048576
	        mkswap /var/swapfile1;chmod 0644 /var/swapfile1;swapon /var/swapfile1
	        echo '/var/swapfile1 swap swap default 0 0' >> /etc/fstab
	        echo "已经成功添加SWAP"
		else
			echo "检查到您已经添加SWAP,无需重复添加"
		fi

	elif [ ${swap} = '3' ]; then
		#判断/var/swapfile1文件是否存在
		if [ ! -f /var/swapfile1 ]; then
 		    echo "检查到您未添加SWAP"
		else
	        swapoff /var/swapfile1
                sed -i "/swapfile1/d" /etc/fstab
                rm -rf /var/swapfile1
		fi
	else
		echo "选项不在范围.";exit 0
	fi
}

install_ssh_port(){
	#检查文件sshport.sh是否存在,若不存在,则下载该文件
	if [ ! -f /root/sshport.sh ]; then
		wget -N —no-check-certificate https://www.moerats.com/usr/down/sshport.sh
	    chmod +x sshport.sh
	fi
	    ./sshport.sh
        service restart sshd
}

ddns(){
    echo "选项：[1]安装 [2]配置 [3]运行"
	read ddns
	if [ ${ddns} = '1' ]; then
	    if [ ! -f /root/ddns/cf-ddns.sh ]; then
	    	echo "DDNS未配置，开始下载";
            wget -N —no-check-certificate "https://raw.githubusercontent.com/whut-share/v6/master/cf-ddns.sh" -P /root/ddns
            chmod +x /root/ddns/cf-ddns.sh
	    fi
	    #清屏
		clear

		read -e -p "cf email: " CfEmail
		read -e -p "cf domain: " CfDomain
		read -e -p "cf subdomain: " CfSubDomain

		cf_emn_line=`grep -n 'cf email' /root/ddns/cf-ddns.sh | cut -d: -f 1`
		let cf_email_line=cf_emn_line+1
		sed -i  "${cf_email_line}s/^.*$/auth_email='${CfEmail}'/"  /root/ddns/cf-ddns.sh

		cf_dmn_line=`grep -n 'cf domain' /root/ddns/cf-ddns.sh | cut -d: -f 1`
		let cf_domain_line=cf_dmn_line+1
		let cf_subdomain_line=cf_dmn_line+2
		sed -i  "${cf_domain_line}s/^.*$/zone_name='${CfDomain}'/"  /root/ddns/cf-ddns.sh
		sed -i  "${cf_subdomain_line}s/^.*$/record_name='${CfSubDomain}'/"  /root/ddns/cf-ddns.sh

		#运行
		bash /root/ddns/cf-ddns.sh

    elif [ ${ddns} = '2' ]; then
		#清屏
		clear
		#输出当前配置
		cf_emn_line=`grep -n 'cf email' /root/ddns/cf-ddns.sh | cut -d: -f 1`
		let cf_email_line=cf_emn_line+1

		cf_dmn_line=`grep -n 'cf domain' /root/ddns/cf-ddns.sh | cut -d: -f 1`
		let cf_domain_line=cf_dmn_line+1
		let cf_subdomain_line=cf_dmn_line+2

		echo "当前DDNS配置如下:"
		echo "------------------------------------"
		sed -n '${cf_email_line}p' /root/ddns/cf-ddns.sh
		sed -n '${cf_domain_line}p' /root/ddns/cf-ddns.sh
		sed -n '${cf_subdomain_line}p' /root/ddns/cf-ddns.sh
		echo "------------------------------------"
		#获取新配置信息
        read -e -p "new cf email: " CfEmail
		read -e -p "new cf domain: " CfDomain
		read -e -p "new cf subdomain: " CfSubDomain

		#修改
        sed -i  "${cf_email_line}s/^.*$/auth_email = ${CfEmail}/"  /root/ddns/cf-ddns.sh
		sed -i  "${cf_domain_line}s/^.*$/zone_name = '${CfDomain}'/"  /root/ddns/cf-ddns.sh
		sed -i  "${cf_subdomain_line}s/^.*$/record_name = '${CfSubDomain}'/"  /root/ddns/cf-ddns.sh

        bash /root/ddns/cf-ddns.sh
    elif [ ${ddns} = '3' ]; then
		#运行
		bash /root/ddns/cf-ddns.sh
	else
		echo "选项不在范围.";exit 0
	fi
}

#卸载各类云盾-[a]
uninstall_ali_cloud_shield(){
	echo "请选择：[1]卸载阿里云盾 [2]卸载腾讯云盾";read uninstall_ali_cloud_shield

	if [ ${uninstall_ali_cloud_shield} = '1' ]; then
        yum -y install redhat-lsb
        var=`lsb_release -a | grep Gentoo`
        if [ -z "${var}" ]; then
	        var=`cat /etc/issue | grep Gentoo`
        fi

        if [ -d "/etc/runlevels/default" -a -n "${var}" ]; then
	        LINUX_RELEASE="GENTOO"
        else
	        LINUX_RELEASE="OTHER"
        fi

        stop_aegis(){
	        killall -9 aegis_cli >/dev/null 2>&1
	        killall -9 aegis_update >/dev/null 2>&1
	        killall -9 aegis_cli >/dev/null 2>&1
	        killall -9 AliYunDun >/dev/null 2>&1
	        killall -9 AliHids >/dev/null 2>&1
	        killall -9 AliYunDunUpdate >/dev/null 2>&1
            printf "%-40s %40s\n" "Stopping aegis" "[  OK  ]"
        }

        remove_aegis(){
            if [ -d /usr/local/aegis ]; then
                rm -rf /usr/local/aegis/aegis_client
                rm -rf /usr/local/aegis/aegis_update
	            rm -rf /usr/local/aegis/alihids
            fi
        }

        uninstall_service() {

            if [ -f "/etc/init.d/aegis" ]; then
		        /etc/init.d/aegis stop  >/dev/null 2>&1
		        rm -f /etc/init.d/aegis
            fi

	        if [ $LINUX_RELEASE = "GENTOO" ]; then
		        rc-update del aegis default 2>/dev/null
		        if [ -f "/etc/runlevels/default/aegis" ]; then
			        rm -f "/etc/runlevels/default/aegis" >/dev/null 2>&1;
		        fi
            elif [ -f /etc/init.d/aegis ]; then
                /etc/init.d/aegis  uninstall
	            for ((var=2; var<=5; var++)) do
			        if [ -d "/etc/rc${var}.d/" ]; then
				        rm -f "/etc/rc${var}.d/S80aegis"
		            elif [ -d "/etc/rc.d/rc${var}.d" ]; then
				        rm -f "/etc/rc.d/rc${var}.d/S80aegis"
			        fi
		        done
                fi

        }

        stop_aegis
        uninstall_service
        remove_aegis

        printf "%-40s %40s\n" "Uninstalling aegis"  "[  OK  ]"

        var=`lsb_release -a | grep Gentoo`
        if [ -z "${var}" ]; then
    	    var=`cat /etc/issue | grep Gentoo`
        fi

        if [ -d "/etc/runlevels/default" -a -n "${var}" ]; then
    	    LINUX_RELEASE="GENTOO"
        else
    	    LINUX_RELEASE="OTHER"
        fi

        stop_aegis(){
    	    killall -9 aegis_cli >/dev/null 2>&1
    	    killall -9 aegis_update >/dev/null 2>&1
    	    killall -9 aegis_cli >/dev/null 2>&1
            printf "%-40s %40s\n" "Stopping aegis" "[  OK  ]"
        }

        stop_quartz(){
    	    killall -9 aegis_quartz >/dev/null 2>&1
            printf "%-40s %40s\n" "Stopping quartz" "[  OK  ]"
        }

        remove_aegis(){
            if [ -d /usr/local/aegis ]; then
                rm -rf /usr/local/aegis/aegis_client
                rm -rf /usr/local/aegis/aegis_update
            fi
        }

        remove_quartz(){
            if [ -d /usr/local/aegis ]; then
    	        rm -rf /usr/local/aegis/aegis_quartz
            fi
        }

        uninstall_service() {

            if [ -f "/etc/init.d/aegis" ]; then
    		    /etc/init.d/aegis stop  >/dev/null 2>&1
    		    rm -f /etc/init.d/aegis
            fi

    	    if [ $LINUX_RELEASE = "GENTOO" ]; then
    		    rc-update del aegis default 2>/dev/null
    		    if [ -f "/etc/runlevels/default/aegis" ]; then
    			    rm -f "/etc/runlevels/default/aegis" >/dev/null 2>&1;
    		    fi
            elif [ -f /etc/init.d/aegis ]; then
                /etc/init.d/aegis  uninstall
    	        for ((var=2; var<=5; var++)) do
    			    if [ -d "/etc/rc${var}.d/" ]; then
    				    rm -f "/etc/rc${var}.d/S80aegis"
    		        elif [ -d "/etc/rc.d/rc${var}.d" ]; then
    				    rm -f "/etc/rc.d/rc${var}.d/S80aegis"
    			    fi
    		    done
                fi

        }
        stop_aegis
        stop_quartz
        uninstall_service
        remove_aegis
        remove_quartz
        printf "%-40s %40s\n" "Uninstalling aegis_quartz"  "[  OK  ]"
        pkill aliyun-service
        rm -fr /etc/init.d/agentwatch /usr/sbin/aliyun-service
        rm -rf /usr/local/aegis*
        iptables -I INPUT -s 140.205.201.0/28 -j DROP
        iptables -I INPUT -s 140.205.201.16/29 -j DROP
        iptables -I INPUT -s 140.205.201.32/28 -j DROP
        iptables -I INPUT -s 140.205.225.192/29 -j DROP
        iptables -I INPUT -s 140.205.225.200/30 -j DROP
        iptables -I INPUT -s 140.205.225.184/29 -j DROP
        iptables -I INPUT -s 140.205.225.183/32 -j DROP
        iptables -I INPUT -s 140.205.225.206/32 -j DROP
        iptables -I INPUT -s 140.205.225.205/32 -j DROP
        iptables -I INPUT -s 140.205.225.195/32 -j DROP
        iptables -I INPUT -s 140.205.225.204/32 -j DROP
    elif [ ${uninstall_ali_cloud_shield} = '2' ]; then
        #检查文件uninstal_qcloud.sh是否存在,若不存在,则下载该文件
	    if [ ! -f /root/uninstal_qcloud.sh ]; then
	    	curl -sSL https://down.oldking.net/Script/uninstal_qcloud.sh
	    	chmod +x uninstal_qcloud.sh
	    fi
        sudo bash uninstal_qcloud.sh
    else
    	echo "选项不在范围内,更新中止.";exit 0
    fi
}

#回程路由测试-[b]
nali_test(){
	echo "请输入目标IP：";read purpose_ip
	nali-traceroute -q 1 ${purpose_ip}
}

besttrace_test(){
	echo "请输入目标IP：";read purpose_ip
	cd /root/besttrace
	./besttrace -q 1 ${purpose_ip}
}

mtr_test(){
	echo "请输入目标IP：";read purpose_ip
	echo "请输入测试次数："
	read MTR_Number_of_tests
	mtr -c ${MTR_Number_of_tests} --report ${purpose_ip}
}

detect_backhaul_routing(){
	echo "选项：[1]Nali [2]BestTrace [3]MTR"
	read detect_backhaul_routing_version
	if [ ${detect_backhaul_routing_version} = '1' ]; then
		#判断/root/nali-ipip/configure文件是否存在
		if [ ! -f /root/nali-ipip/configure ]; then
			echo "检查到您未安装,脚本将先进行安装..."
			yum -y update;yum -y install traceroute git gcc make
			git clone https://github.com/dzxx36gyy/nali-ipip.git
			cd nali-ipip
			./configure && make && make install
			clear;nali_test
		else
			nali_test
		fi
	elif [ ${detect_backhaul_routing_version} = '2' ]; then
		#判断/root/besttrace/besttrace文件是否存在
		if [ ! -f /root/besttrace/besttrace ]; then
			echo "检查到您未安装,脚本将先进行安装..."
			yum update -y
			yum install traceroute unzip -y
			wget -N --no-check-certificate "https://cdn.ipip.net/17mon/besttrace4linux.zip"
			unzip besttrace4linux.zip -d besttrace && cd besttrace && chmod +x *
			clear;
            rm -rf /root/*.zip
            besttrace_test
		else
			besttrace_test
		fi
	elif [ ${detect_backhaul_routing_version} = '3' ]; then
		#判断/usr/sbin/mtr文件是否存在
		if [ ! -f /usr/sbin/mtr ]; then
			echo "检查到您未安装,脚本将先进行安装..."
			yum update -y;yum install mtr -y
			clear;mtr_test
		else
			mtr_test
		fi
	else
		echo "选项不在范围.";exit 0
	fi
}

#简易测速-[c]
superspeed(){
	#检查文件superspeed.sh是否存在,若不存在,则下载该文件
	if [ ! -f /root/superspeed.sh ]; then
		wget -N --no-check-certificate "https://github.com/Super-box/v3/raw/master/superspeed.sh" /root/superspeed.sh
		chmod +x /root/superspeed.sh
	fi
	#执行测试
    ./superspeed.sh
}

#检测BBR安装状态-[d]
check_bbr_installation(){
	echo "查看内核版本,含有4.12即可";uname -r
	echo "------------------------------------------------------------"
	echo "返回：net.ipv4.tcp_available_congestion_control = bbr cubic reno 即可";sysctl net.ipv4.tcp_available_congestion_control
	echo "------------------------------------------------------------"
	echo "返回：net.ipv4.tcp_congestion_control = bbr 即可";sysctl net.ipv4.tcp_congestion_control
	echo "------------------------------------------------------------"
	echo "返回：net.core.default_qdisc = fq 即可";sysctl net.core.default_qdisc
	echo "------------------------------------------------------------"
	echo "返回值有 tcp_bbr 模块即说明bbr已启动";lsmod | grep bbr
}

#更换默认源-[g]
replacement_of_installation_source(){
	echo "请选择更换目标源： [1]网易163 [2]阿里云 [3]自定义 [4]恢复默认源"
	read change_target_source

	#备份
	mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.bak

	#执行
	if [ ${change_target_source} = '1' ]; then
		echo "更换目标源:网易163,请选择操作系统版本： [1]Centos 5 [2]Centos 6 [3]Centos 7"
		read operating_system_version
		if [ ${operating_system_version} = '1' ]; then
			wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.163.com/.help/CentOS5-Base-163.repo;yum clean all;yum makecache
		elif [ ${operating_system_version} = '2' ]; then
			wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.163.com/.help/CentOS6-Base-163.repo;yum clean all;yum makecache
		elif [ ${operating_system_version} = '3' ]; then
			wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.163.com/.help/CentOS7-Base-163.repo;yum clean all;yum makecache
		fi
	elif [ ${change_target_source} = '2' ]; then
		echo "更换目标源:阿里云,请选择操作系统版本： [1]Centos 5 [2]Centos 6 [3]Centos 7"
		read operating_system_version
		if [ ${operating_system_version} = '1' ]; then
			wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-5.repo;yum clean all;yum makecache
		elif [ ${operating_system_version} = '2' ]; then
			wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-6.repo;yum clean all;yum makecache
		elif [ ${operating_system_version} = '3' ]; then
			wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo;yum clean all;yum makecache
		fi
	elif [ ${change_target_source} = '3' ]; then
		echo "更换目标源:自定义,请确定您需使用的自定义的源与您的操作系统相符！";echo "请输入自定义源地址："
		read customize_the_source_address
		wget -O /etc/yum.repos.d/CentOS-Base.repo ${customize_the_source_address};yum clean all;yum makecache
	elif [ ${change_target_source} = '4' ]; then
		rm -rf /etc/yum.repos.d/CentOS-Base.repo
		mv /etc/yum.repos.d/CentOS-Base.repo.bak /etc/yum.repos.d/CentOS-Base.repo
		yum clean all;yum makecache
	fi
}

#配置防火墙-[e]
configure_firewall(){
	echo "请选择操作： [1]关闭firewall"
	read firewall_operation

	if [ ${firewall_operation} = '1' ]; then
		echo "停止firewall..."
		systemctl stop firewalld.service
		echo "禁止firewall开机启动"
		systemctl disable firewalld.service
		echo "查看默认防火墙状态,关闭后显示notrunning,开启后显示running"
		firewall-cmd --state
	else
		echo "选项不在范围,操作中止.";exit 0
	fi
}

update_the_shell(){
	rm -rf /root/v6.sh v6.sh.*
	wget -N "https://raw.githubusercontent.com/whut-share/v6/master/v6.sh" /root/v6.sh

	#将脚本作为命令放置在/usr/bin目录内,最后执行
	rm -rf /usr/bin/v6;cp /root/v6.sh /usr/bin/v6;chmod +x /usr/bin/v6
	v6
}

###待更新
safe_dog(){
	#判断/usr/bin/sdui文件是否存在
	if [ ! -f /usr/bin/sdui ]; then
		echo "检查到您未安装,脚本将先进行安装..."
		wget -N —no-check-certificate  "http://sspanel-1252089354.coshk.myqcloud.com/safedog_linux64.tar.gz"
		tar xzvf safedog_linux64.tar.gz
		mv safedog_an_linux64_2.8.19005 safedog
		cd safedog;chmod +x *.py
		yum -y install mlocate lsof psmisc net-tools
		./install.py
		echo "安装完成,请您重新执行脚本."
	else
		sdui
	fi
}

install_fail2ban(){
	echo "脚本来自:http://www.vpsps.com/225.html";echo "使用简介:https://linux.cn/article-5067-1.html";echo "感谢上述贡献者."
	echo "选择选项: [1]安装fail2ban [2]卸载fail2ban [3]查看封禁列表 [4]为指定IP解锁";read fail2ban_option
	if [ ${fail2ban_option} = '1' ]; then
		wget -N —no-check-certificate"http://sspanel-1252089354.coshk.myqcloud.com/fail2ban.sh";bash fail2ban.sh
	elif [ ${fail2ban_option} = '2' ]; then
		wget -N —no-check-certificate"https://raw.githubusercontent.com/FunctionClub/Fail2ban/master/uninstall.sh";bash uninstall.sh
	elif [ ${fail2ban_option} = '3' ]; then
		echo ${separate_lines};fail2ban-client ping;echo -e "\033[31m[↑]正常返回值:Server replied: pong\033[0m"
		#iptables --list -n;echo -e "\033[31m#当前iptables禁止规则\033[0m"
		fail2ban-client status;echo -e "\033[31m[↑]当前封禁列表\033[0m"
		fail2ban-client status ssh-iptables;echo -e "\033[31m[↑]当前被封禁的IP列表\033[0m"
		sed -n '12,14p' /etc/fail2ban/jail.local;echo -e "\033[31m[↑]当前fail2ban配置\033[0m"
	elif [ ${fail2ban_option} = '4' ]; then
		echo "请输入需要解锁的IP地址:";read need_to_unlock_the_ip_address
		fail2ban-client set ssh-iptables unbanip ${need_to_unlock_the_ip_address}
		echo "已为${need_to_unlock_the_ip_address}解除封禁."
	else
		echo "选项不在范围.";exit 0
	fi
}

install_shell(){
	if [ ! -f /usr/bin/v6 ]; then
		cp /root/v6.sh /usr/bin/v6 && chmod +x /usr/bin/v6
	else
		rm -rf /usr/bin/v6
		cp /root/v6.sh /usr/bin/v6 && chmod +x /usr/bin/v6
		clear;echo "Tips:您可通过命令[v6]快速启动本脚本!"
	fi
}

get_server_ip_info(){
	if [ ! -f /root/.server_ip_info.txt ]; then
		curl -s myip.ipip.net > /root/.server_ip_info.txt
	else
		rm -rf /root/.server_ip_info.txt
		curl -s myip.ipip.net > /root/.server_ip_info.txt
	fi
	read server_ip_info < /root/.server_ip_info.txt
}

#安装本脚本,获取服务器IP信息
install_shell
get_server_ip_info
start_menu

i=1
while((i <= 100))
do
keep_loop
done

#END 2018年12月16日
