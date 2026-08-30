#!/bin/bash
# this script is created by Fuyao.
# e_mail:fuyao.lee@qq.com
# version:1.0
. /etc/init.d/functions
export LANG=zh_CN.UTF-8
#一级菜单
menu1()
{
 clear
 cat <<EOF
----------------------------------------
|****   欢迎使用Oracle11g安装脚本    ****|
|****         作者:李福耀            ****|
----------------------------------------
1. 安装 Oracle 11g 软件
2. 创建数据库实例
3. 任意键退出
EOF
        read -ep "请选择[1-2]:" num1
}
install_oracle()
{
	if [ ! -e "/home/install-software.sh" -o ! -e "/home/create-database.sh" ]
	 then
	  echo "安装脚本不存在,程序退出。"
	  exit 1
	fi

	
echo ">>> 创建Oracle用户和用户组 ......"
#如果需要设置用户密码则跑这一句 passwd oracle(oracle)	
#创建oracle用户，并加入到oinstall和dba用户组
groupadd oinstall
groupadd dba
useradd -g oinstall -G dba oracle

	
#安装依赖文件，并配置基础文件
echo ">>> 正在检查需要的依赖包 ......"
rpm -q binutils compat-libstdc++-33 elfutils-libelf elfutils-libelf-devel glibc glibc-common glibc-devel gcc gcc-c++ libaio-devel libaio libgcc libstdc++ libstdc++-devel make sysstat unixODBC unixODBC-devel ksh numactl-devel zip unzip
if [ $? -eq 0 ] ;then
 echo "依赖包检查通过"
else
 echo "缺少必要的依赖包,正在联网下载……"
 yum install -y binutils compat-libstdc++-33 elfutils-libelf elfutils-libelf-devel glibc glibc-common glibc-devel gcc gcc-c++ libaio-devel libaio libgcc libstdc++ libstdc++-devel make sysstat unixODBC unixODBC-devel ksh numactl-devel zip unzip > /dev/null
 if [ $? -eq 0 ];then
  echo "依赖包安装成功"
 else
  echo "依赖包安装失败，请检查网络问题。"
  exit 1
 fi
fi

#检查Oracle安装包

if [ -e "/home/linux.x64_11gR2_database_1of2.zip" ]&&[ -e "/home/linux.x64_11gR2_database_2of2.zip" ];then
  mv /home/linux.x64_11gR2_database_1of2.zip /home/oracle
  mv /home/linux.x64_11gR2_database_2of2.zip /home/oracle
else
  echo "安装包不存在，请把它放到/home目录下，并按要求命名。"
  exit 1
fi

#修改本机host
echo ">>> 开始配置Oracle网络 ......"
 read -ep "请输入本机ip:" ip
 echo "$ip orcl orcl"  >> /etc/hosts
 cat >> /etc/sysconfig/network <<EOF
network=yes
hostname=orcl
EOF

#优化OS内核参数
#内核参数kernel.shmall，内存16G时建议设为4194304类推8G应为2097152,类似4G:1048576
#kernel.shmmax设置为物理内存的一半,8G:4294967296计算方式为4*1024*1024*1024，所以4G应为2147483648
echo ">>> 开始优化系统参数 ......" 
cat >> /etc/sysctl.conf <<EOF
fs.file-max = 6815744
fs.aio-max-nr = 1048576
kernel.shmall = 1048576
kernel.shmmax = 2147483648
kernel.shmmni = 4096
kernel.sem = 250 32000 100 128
net.ipv4.ip_local_port_range = 9000 65500
net.core.rmem_default = 4194304
net.core.rmem_max = 4194304
net.core.wmem_default = 262144
net.core.wmem_max = 1048576
EOF

#使参数生效
sysctl -p

#限制oracle用户可以使用的最大文件数，最大线程，最大内存等资源使用量。
cat >> /etc/security/limits.conf <<EOF
oracle soft nproc 2047
oracle hard nproc 16384
oracle soft nofile 1024
oracle hard nofile 65536
EOF

#用来验证登陆用的配置文件,pam验证，验证的规则就是在这里面定义的，如果符合才让你登陆。
cat >> /etc/pam.d/login <<EOF
session required /lib64/security/pam_limits.so 
session required pam_limits.so
EOF

#系统的变量相关。这里修改会对所有用户起作用。
cat >> /etc/profile <<EOF
if [ $USER = "oracle" ]; then
if [ $SHELL = "/bin/ksh" ]; then
ulimit -p 16384
ulimit -n 65536
else
ulimit -u 16384 -n 65536
fi
fi
EOF

#设置生效
source /etc/profile



echo ">>> 创建oracle安装目录 ......"

#创建oracle安装目录 根据实际情况可做改动
mkdir -p /u01/app/oracle/product/11.2.0/db_1
mkdir -p /u01/app/oracle/oradata
mkdir -p /u01/app/oraInventory
mkdir -p /u01/app/oracle/fast_recovery_area
chown -R oracle:oinstall /u01/app/oracle
chown -R oracle:oinstall /u01/app/oraInventory
chmod -R 755 /u01/app/oracle
chmod -R 755 /u01/app/oraInventory


#关闭防火墙和SeLinux
echo ">>> 关闭防火墙和SeLinux ......"
systemctl disable firewalld
systemctl stop firewalld
setenforce 0
sed -i 's/=enforcing/=disabled/g' /etc/selinux/config

#执行安装脚本
su - oracle -s /bin/bash /home/install-software.sh

}
install_sid(){
su - oracle -s /bin/bash /home/create-database.sh
}
main()
{
 menu1
 case $num1 in
  1)
   install_oracle
   ;;
  2)
   install_sid
  ;;
  3)
   exit
   ;;   
  *)
   echo '请输入数字1或2'
   ;;
  esac
}
main $*
