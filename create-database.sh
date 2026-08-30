#!/bin/bash
# this script is created by Fuyao.
# e_mail:fuyao.lee@qq.com
# version:1.0
. /etc/init.d/functions

cd /home/oracle
source .bash_profile
netca /silent /responseFile /home/oracle/database/response/netca.rsp #静默方式配置监听
ls $ORACLE_HOME/network/admin/    #正常情况下会自动生成listener.ora sqlnet.ora
cd /home/oracle/database/response
cp dbca.rsp dbca.rsp.bak
#下面的参数要根据自己的实际情况需要来修改
read -ep "输入实例名:" sid
read -ep "请输入system密码:" password
#服务名
sed -i '78s/.*/GDBNAME= "orcl"/' dbca.rsp
#数据库实例名
sed -i "170s/.*/SID = \""$sid"\"/" dbca.rsp
sed -i "211s/.*/SYSPASSWORD = \""$password"\"/" dbca.rsp
sed -i "221s/.*/SYSTEMPASSWORD = \""$password"\"/" dbca.rsp
sed -i "252s/.*/SYSMANPASSWORD = \""$password"\"/" dbca.rsp
sed -i "262s/.*/DBSNMPPASSWORD = \""$password"\"/" dbca.rsp
sed -i '360s/.*/DATAFILEDESTINATION=\/u01\/app\/oracle\/oradata/' dbca.rsp
sed -i '370s/.*/RECOVERYAREADESTINATION=\/u01\/app\/oracle\/fast_recovery_area/' dbca.rsp
sed -i '418s/.*/CHARACTERSET= "ZHS16GBK"/' dbca.rsp
sed -i '553s/.*/TOTALMEMORY= "3276"/' dbca.rsp   #值设置为物理内存的60%
echo ">>> 10. 安装实例 ......"
dbca -silent -responseFile /home/oracle/database/response/dbca.rsp  #开始静默安装
#开启监听并显示状态
lsnrctl start
lsnrctl status
#检测oracle进程
ps -ef | grep ora_ | grep -v grep  
