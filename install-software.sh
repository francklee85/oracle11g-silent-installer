#!/bin/bash
# this script is created by Fuyao.
# e_mail:fuyao.lee@qq.com
# version:1.0
. /etc/init.d/functions

echo ">>>  配置Oracle用户环境变量 ......"
cat >> .bash_profile <<EOF
ORACLE_BASE=/u01/app/oracle #基础目录
ORACLE_HOME=\$ORACLE_BASE/product/11.2.0/db_1 #oracle安装目录
ORACLE_SID=orcl  #实例名
export NLS_LANG=AMERICAN_AMERICA.ZHS16GBK #这里根据实际情况修改字符集。比如有的是（ZHS16GBK或UTF8）
PATH=\$PATH:\$ORACLE_HOME/bin
export ORACLE_BASE ORACLE_HOME ORACLE_SID PATH
umask 022
EOF
sleep 3
source .bash_profile
sleep 5
#修改以下文件名为实际的安装包名
echo ">>>  正在解压安装包 ......"
unzip -q /home/oracle/linux.x64_11gR2_database_1of2.zip 
unzip -q /home/oracle/linux.x64_11gR2_database_2of2.zip
chown -R oracle:oinstall database
cd /home/oracle/database/response
cp db_install.rsp  db_install.rsp.bak
#修改静默安装的配置文件，这里也可以根据实际情况进行修改
echo ">>> 开始安装数据库 ......"
sed -i "s/^oracle.install.option=/oracle.install.option=INSTALL_DB_SWONLY/g" db_install.rsp
sed -i "s/^ORACLE_HOSTNAME=/ORACLE_HOSTNAME= orcl/g" db_install.rsp
sed -i "s/^UNIX_GROUP_NAME=/UNIX_GROUP_NAME=oinstall/g" db_install.rsp
sed -i "s/^INVENTORY_LOCATION=/INVENTORY_LOCATION=\/u01\/app\/oraInventory/g" db_install.rsp
sed -i "s/^SELECTED_LANGUAGES=en/SELECTED_LANGUAGES=en,zh_CN/g" db_install.rsp
sed -i "s/^ORACLE_HOME=/ORACLE_HOME=\/u01\/app\/oracle\/product\/11.2.0\/db_1/g" db_install.rsp
sed -i "s/^ORACLE_BASE=/ORACLE_BASE=\/u01\/app\/oracle/g" db_install.rsp
sed -i "s/^oracle.install.db.InstallEdition=/oracle.install.db.InstallEdition=EE/g" db_install.rsp
sed -i "s/^oracle.install.db.isCustomInstall=false/oracle.install.db.isCustomInstall=true/g" db_install.rsp
sed -i "s/^oracle.install.db.DBA_GROUP=/oracle.install.db.DBA_GROUP=dba/g" db_install.rsp
sed -i "s/^oracle.install.db.OPER_GROUP=/oracle.install.db.OPER_GROUP=dba/g" db_install.rsp
sed -i "s/^oracle.install.db.config.starterdb.type=/oracle.install.db.config.starterdb.type=GENERAL_PURPOSE/g" db_install.rsp
#全局数据库名。根据情况修改
sed -i "s/^oracle.install.db.config.starterdb.globalDBName=/oracle.install.db.config.starterdb.globalDBName=orcl/g" db_install.rsp
sed -i "s/^oracle.install.db.config.starterdb.SID=/oracle.install.db.config.starterdb.SID=orcl/g" db_install.rsp
sed -i "s/^oracle.install.db.config.starterdb.memoryLimit=/oracle.install.db.config.starterdb.memoryLimit=512/g" db_install.rsp
sed -i "s/^oracle.install.db.config.starterdb.password.ALL=/oracle.install.db.config.starterdb.password.ALL=oracle/g" db_install.rsp
sed -i "s/^DECLINE_SECURITY_UPDATES=/DECLINE_SECURITY_UPDATES=true/g" db_install.rsp
cd ..
./runInstaller -silent -ignorePrereq -responseFile /home/oracle/database/response/db_install.rsp
#安装期间可以使用tail命令监看oracle的安装日志tail -f /oracle/oraInventory/logs/installActions
#跑完之后检测以下oracle用户环境变量是否设置正确，测试方法输入netc然后tab补全，如果不能自动补全为netca，则需要在oracle家目录下再次执行source .bash_profile,直到可以自动补全netca和dbca等命令为止

#sh /u01/app/oraInventory/orainstRoot.sh
#sh /u01/app/oracle/product/11.2.0/db_1/root.sh
