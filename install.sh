#!/bin/bsh
# 以下操作需要已连接到互联网
# 均在命令行终端环境下操作
# 如果当前不是 root 用户，以下所有命令前需要加 sudo，然后可能需要输入 root 用户密码

### 更换源 mirrors.aliyun.com(阿里云)

# 进入目录
pushd /etc/yum.repos.d
# 备份原文件
mv CentOS-Base.repo CentOS-Base.repo.bak
# 下载阿里源
curl -o CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo
# epel.repo
curl -o epel-7.repo http://mirrors.aliyun.com/repo/epel-7.repo
# 退出目录
popd

# 系统软件清理和更新
yum clean all
yum makecache
yum update -y

# 安装软件
yum install -y net-tools wget vim iptables iptables-services openssh-server openssl java-11-openjdk

# openssh-server 安装后即可进行远程登录操作


### 防火墙配置

# 禁用 firewalld 服务
systemctl disable firewalld

# 清空所有规则
iptables -F
iptables -X
iptables -Z

# 开启 iptables
service iptables start

# 关闭 iptables
#service iptables stop

# 启用 iptables 服务
systemctl enable iptables

# 查看 iptables 状态 显示绿色 active 表示已开启
service iptables status

# 查看当前规则
iptables -L -n --line-numbers

# 重新加载 iptables 规则
service iptables reload

# 插入规则 只允许 192.168.2.133 访问 80 端口，默认情况下，其他IP访问一律拒绝
# iptables -I INPUT 5 这个数字5代表规则的序号
# 必须在 -A INPUT -j REJECT --reject-with icmp-host-prohibited 这行之上
iptables -I INPUT 5 -s 192.168.2.133 -p tcp --dport 80 -j ACCEPT

# 保存规则
service iptables save


### 安装 Nginx 稳定版本
# 其他版本在这里 http://nginx.org/packages/centos/7/x86_64/RPMS/
# 下载
wget http://nginx.org/packages/centos/7/x86_64/RPMS/nginx-1.16.0-1.el7.ngx.x86_64.rpm

# 安装
rpm -ivh nginx-1.16.0-1.el7.ngx.x86_64.rpm

# 查看 nginx 配置选项
nginx -V
# 配置文件 nginx.conf 正常都是在 /etc/nginx/ 目录
# 自定义配置文件位置在 /etc/nginx/conf.d/ 目录

# 运行
nginx

# 测试访问
curl -I localhost

# 查看当前监听的端口
#netstat -ant
# 如果端口太多可以加上 “|grep LISTEN” 只搜索开启监听的端口
netstat -ant|grep LISTEN

pushd /etc/nginx/conf.d/

# 反向代理配置
cat > default.conf << EOF
server {
    listen       80;
    server_name  localhost;

    location / {
        proxy_set_header HOST \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_pass http://localhost:8080;
    }

    error_page   500 502 503 504  /50x.html;
    location = /50x.html {
        root   /usr/share/nginx/html;
    }
}
EOF

# 重新加载配置
nginx -sreload

echo "安装配置完成";

