# Oracle 11g 静默安装脚本

这是一套面向 **CentOS 7 x86_64** 的 Oracle Database 11g R2 静默安装脚本，保留原有的三阶段执行方式：系统准备、Oracle 软件安装、数据库实例创建。

脚本中的目录、主机名、字符集和内存等参数均为固定值，使用前请先阅读本说明并根据实际服务器情况调整。

## 文件说明

| 文件 | 用途 | 执行用户 |
| --- | --- | --- |
| `install-oracle.sh` | 主入口，创建用户、安装依赖并配置操作系统 | `root` |
| `install-software.sh` | 解压介质并静默安装 Oracle 软件 | 由主脚本切换为 `oracle` 执行 |
| `create-database.sh` | 配置监听并创建数据库实例 | 由主脚本切换为 `oracle` 执行 |

三个脚本之间使用了固定的 `/home` 路径，因此部署时请保持上述文件名，并全部放在 `/home` 目录。

## 默认配置

- Oracle 用户：`oracle`
- 安装组：`oinstall`
- DBA 组：`dba`
- 主机名：`orcl`
- Oracle Base：`/u01/app/oracle`
- Oracle Home：`/u01/app/oracle/product/11.2.0/db_1`
- Inventory：`/u01/app/oraInventory`
- 数据目录：`/u01/app/oracle/oradata`
- 恢复区：`/u01/app/oracle/fast_recovery_area`
- 全局数据库名：`orcl`
- 字符集：`ZHS16GBK`
- 数据库内存：`3276 MB`

如需修改这些值，请同时检查三个脚本中的相关路径和响应文件参数，避免 Oracle Home、SID 或数据目录不一致。

## 安装前准备

建议在全新的 CentOS 7 x86_64 服务器或虚拟机快照上执行，并使用 `root` 用户操作。

将三个脚本上传到 `/home`：

```text
/home/install-oracle.sh
/home/install-software.sh
/home/create-database.sh
```

将两个 Oracle 安装包上传到 `/home`，并保持以下文件名：

```text
/home/linux.x64_11gR2_database_1of2.zip
/home/linux.x64_11gR2_database_2of2.zip
```

添加执行权限：

```bash
chmod +x /home/install-oracle.sh
chmod +x /home/install-software.sh
chmod +x /home/create-database.sh
```

执行前还应确认：

- yum 软件源可用；
- 两个 ZIP 安装包完整；
- `/u01` 和 `/home` 有足够空间；
- 当前服务器允许修改主机名、内核参数、SELinux 和防火墙；
- 安装介质版本与 CentOS 7 兼容。

## 使用方法

使用 `root` 用户运行主脚本：

```bash
cd /home
./install-oracle.sh
```

脚本显示以下菜单：

```text
1. 安装 Oracle 11g 软件
2. 创建数据库实例
3. 任意键退出
```

### 第一步：安装 Oracle 软件

选择 `1` 后，主脚本会：

1. 创建 `oinstall`、`dba` 组和 `oracle` 用户；
2. 检查并安装 Oracle 依赖包；
3. 将两个 ZIP 安装包移动到 `/home/oracle`；
4. 提示输入本机 IP，并写入主机配置；
5. 写入内核参数、资源限制、PAM 和系统环境配置；
6. 创建 `/u01` 下的 Oracle 目录；
7. 停止并禁用 firewalld，关闭 SELinux；
8. 切换为 `oracle` 用户执行 `install-software.sh`；
9. 解压安装介质、修改 `db_install.rsp` 并启动静默安装。

安装过程中可另开终端查看日志：

```bash
tail -f /u01/app/oraInventory/logs/installActions*.log
```

Oracle 安装器完成后，必须根据安装输出使用 `root` 用户执行：

```bash
sh /u01/app/oraInventory/orainstRoot.sh
sh /u01/app/oracle/product/11.2.0/db_1/root.sh
```

这两个命令在软件安装脚本中仅作为注释保留，不会自动执行。确认安装器已经完成后再运行它们。

### 第二步：创建数据库实例

完成 Oracle 软件安装和两个 root 脚本后，再次运行：

```bash
cd /home
./install-oracle.sh
```

选择 `2`。脚本会切换为 `oracle` 用户，并依次执行：

1. 使用 NETCA 静默配置监听；
2. 提示输入数据库 SID 和 SYSTEM 密码；
3. 修改 `dbca.rsp`；
4. 使用 DBCA 静默创建数据库；
5. 启动监听并显示监听状态；
6. 显示 Oracle 相关进程。

安装完成后可以检查：

```bash
su - oracle
lsnrctl status
ps -ef | grep ora_ | grep -v grep
```

## 重要注意事项

### 只建议在新服务器上执行一次

脚本会直接追加内容到以下系统文件：

```text
/etc/hosts
/etc/sysconfig/network
/etc/sysctl.conf
/etc/security/limits.conf
/etc/pam.d/login
/etc/profile
/home/oracle/.bash_profile
```

重复执行可能产生重复配置；`groupadd` 和 `useradd` 在用户或组已存在时也会报错。因此不建议在已经配置过 Oracle 的服务器上直接运行。

### SELinux 和防火墙

主脚本会执行：

```bash
systemctl disable firewalld
systemctl stop firewalld
setenforce 0
```

并将 `/etc/selinux/config` 中的 enforcing 修改为 disabled。永久关闭 SELinux 通常需要重启服务器后完全生效。关闭系统安全组件前，请确保服务器所在网络已有其他访问控制措施。

### 数据库密码

创建实例时输入的密码会被写入 `/home/oracle/database/response/dbca.rsp`。脚本会保留 `dbca.rsp.bak`，数据库创建完成并确认无误后，建议恢复原响应文件或删除其中的密码：

```bash
cd /home/oracle/database/response
cp -f dbca.rsp.bak dbca.rsp
chmod 600 dbca.rsp
```

