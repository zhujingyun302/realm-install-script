#!/bin/bash

CONFIG_FILE="/etc/realm/config.toml"

# 检查是否以 root 身份运行
if [ "$(id -u)" -ne 0 ]; then
  echo "请以 root 身份运行此脚本。"
  exit 1
fi

# 安装 realm 的函数
function install_realm() {
  echo "开始安装 realm..."

  # 安装必要的工具
  apt update
  apt install -y wget

  # 下载 realm 可执行文件
  wget -O /usr/local/bin/realm https://pan.bobqu.cyou/Code/realm
  chmod +x /usr/local/bin/realm

  # 确保配置目录存在
  if [ ! -d "/etc/realm" ]; then
    mkdir -p "/etc/realm"
  fi

  # 创建初始配置文件
  cat > "$CONFIG_FILE" <<EOF
[[endpoints]]
listen = "0.0.0.0:8000"
remote = "1.1.1.1:443"

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

  echo "realm 已成功安装并启动！"
}

# 查看当前配置
function view_config() {
  echo "当前配置如下："
  if [ -f "$CONFIG_FILE" ]; then
    cat "$CONFIG_FILE"
  else
    echo "配置文件不存在！"
  fi
}

# 添加新的转发配置
function add_config() {
  echo "请输入新的转发配置："
  read -p "监听地址 (本机 IP:端口，默认 0.0.0.0:8000): " NEW_LISTEN
  NEW_LISTEN=${NEW_LISTEN:-0.0.0.0:8000}
  read -p "远程地址 (对方 IP:端口): " NEW_REMOTE

  if [ -z "$NEW_REMOTE" ]; then
    echo "远程地址不能为空！"
    return
  fi

  # 添加配置到文件
  echo "" >> "$CONFIG_FILE"
  echo "[[endpoints]]" >> "$CONFIG_FILE"
  echo "listen = \"$NEW_LISTEN\"" >> "$CONFIG_FILE"
  echo "remote = \"$NEW_REMOTE\"" >> "$CONFIG_FILE"
  echo "新的配置已添加："
  echo "listen = \"$NEW_LISTEN\""
  echo "remote = \"$NEW_REMOTE\""
}

# 删除转发配置
function delete_config() {
  echo "当前配置如下："
  if [ ! -f "$CONFIG_FILE" ]; then
    echo "配置文件不存在！"
    return
  fi

  cat -n "$CONFIG_FILE" | grep -E "listen|remote"

  echo "请输入要删除的配置编号（例如第几行的 listen 或 remote）："
  read -p "开始行号: " START_LINE
  read -p "结束行号: " END_LINE

  if [ -z "$START_LINE" ] || [ -z "$END_LINE" ]; then
    echo "行号不能为空！"
    return
  fi

  sed -i "${START_LINE},${END_LINE}d" "$CONFIG_FILE"
  echo "指定配置已删除！"
}

# 主菜单
function show_menu() {
  echo "======================================="
  echo "1) 安装 realm"
  echo "2) 查看当前转发配置"
  echo "3) 添加新的转发配置"
  echo "4) 删除转发配置"
  echo "5) 重启 realm 服务"
  echo "6) 退出"
  echo "======================================="
}

# 重启 realm 服务
function restart_realm() {
  echo "正在重启 realm 服务..."
  systemctl restart realm
  echo "realm 服务已重启！"
}

# 主逻辑
while true; do
  show_menu
  read -p "请选择操作: " CHOICE

  case $CHOICE in
    1)
      install_realm
      ;;
    2)
      view_config
      ;;
    3)
      add_config
      ;;
    4)
      delete_config
      ;;
    5)
      restart_realm
      ;;
    6)
      echo "退出程序！"
      break
      ;;
    *)
      echo "无效选择，请重新输入！"
      ;;
  esac

  echo ""
done
