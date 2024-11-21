#!/bin/bash

# 检查是否以 root 身份运行
if [ "$(id -u)" -ne 0 ]; then
  echo "请以 root 身份运行此脚本。"
  exit 1
fi

# 安装必要的工具
apt update
apt install -y wget

# 下载 realm 可执行文件
wget -O /usr/local/bin/realm https://pan.bobqu.cyou/Code/realm
chmod +x /usr/local/bin/realm

# 获取用户输入
echo "请输入对方 IP："
read -p "对方 IP: " REMOTE_IP

echo "请输入对方端口："
read -p "对方端口: " REMOTE_PORT

echo "请输入本机 IP："
read -p "本机 IP (默认 0.0.0.0): " LOCAL_IP
LOCAL_IP=${LOCAL_IP:-0.0.0.0}

echo "请输入本机端口："
read -p "本机端口 (默认 8000): " LOCAL_PORT
LOCAL_PORT=${LOCAL_PORT:-8000}

# 创建 realm 配置文件
cat > /etc/realm/config.toml <<EOF
[[endpoints]]
listen = "${LOCAL_IP}:${LOCAL_PORT}"
remote = "${REMOTE_IP}:${REMOTE_PORT}"

[network]
no_tcp = false
use_udp = true
EOF

# 创建 systemd 服务文件
cat > /etc/systemd/system/realm.service <<EOF
[Unit]
Description=realm
After=network-online.target
Wants=network-online.target systemd-networkd-wait-online.service

[Service]
Type=simple
User=root
Restart=on-failure
RestartSec=5s
WorkingDirectory=/etc/realm
ExecStart=/usr/local/bin/realm -c /etc/realm/config.toml

[Install]
WantedBy=multi-user.target
EOF

# 重新加载 systemd 并启动 realm 服务
systemctl daemon-reload
systemctl enable realm
systemctl start realm

# 提示信息
echo "realm 已成功安装并启动。"
echo "=========================="
echo "对方 IP: ${REMOTE_IP}"
echo "对方端口: ${REMOTE_PORT}"
echo "本机 IP: ${LOCAL_IP}"
echo "本机端口: ${LOCAL_PORT}"
echo "=========================="
echo "如需重启 realm，请运行以下命令："
echo "systemctl restart realm"
