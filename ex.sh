#!/usr/bin/env bash

if [ -f .env ]; then
  export $(cat .env | xargs)
fi

sync() {
  local EC2_IP=$(terraform output -raw ec2_ip)
  local CIDR_BLOCKS=$(terraform output -raw cidr_blocks)
  local MY_IP=$(curl -s ifconfig.me)
  echo -e "\033[42m(sync)\033[0m EC2 IP is $EC2_IP. Your IP is $MY_IP"
  if [[ -z "$(echo $CIDR_BLOCKS | grep $MY_IP)" ]]; then
    echo -e "\033[42m(sync)\033[0m \033[41mYour $MY_IP IP wasn't within whitelisted IPs!\033[0m"
    exit 1
  fi
  SSH_PATH="$HOME/.ssh/$TF_VAR_ssh_key_name"
  if [ ! -f $SSH_PATH ]; then
    echo -e "\033[41mSSH key not found at: $SSH_PATH\033[0m"
    exit 1
  fi
  echo -e "\033[42m(sync)\033[0m Attempting to SSH and download publickey"
  ssh -o "IdentitiesOnly=yes" -i $SSH_PATH ubuntu@$EC2_IP "sudo cat /etc/wireguard/publickey" > ./publickey
  echo -e "\033[42m(sync)\033[0m Copied /etc/wireguard/publickey from $EC2_IP to ./publickey"
  PUBLIC_KEY=$(cat ./publickey)
  WG_CONF="/opt/homebrew/etc/wireguard/wg0.conf"
  if [ ! -f $WG_CONF ]; then
    echo -e "\033[42m(sync)\033[0m \033[41mWireGuard config not found at: $WG_CONF\033[0m"
    exit 1
  elif [[ -z "$PUBLIC_KEY" ]]; then
    echo -e "\033[42m(sync)\033[0m \033[41mCopied wireguard publickey was empty, try again in a while or copy manually\033[0m"
    exit 1
  fi
  sed -i '' "s|PublicKey = .*|PublicKey = $PUBLIC_KEY|" $WG_CONF
  sed -i '' "s|Endpoint = .*|Endpoint = $EC2_IP:51820|" $WG_CONF
  echo -e "\033[42m(sync)\033[0m Update $WG_CONF"
  echo -e "\033[42m(sync)\033[0m -> PublicKey = $PUBLIC_KEY"
  echo -e "\033[42m(sync)\033[0m -> Endpoint = $EC2_IP"
}

case "$1" in
ssh)
  shift
  SSH_PATH="$HOME/.ssh/$TF_VAR_ssh_key_name"
  if [[ -z $1 ]]; then
    echo -e "Usage: ./ex.sh ssh <ipv4>"
    exit 1
  fi
  if [ ! -f $SSH_PATH ]; then
    echo -e "\033[41mSSH key not found at: $SSH_PATH\033[0m"
    exit 1
  fi
  ssh -o "IdentitiesOnly=yes" -i $SSH_PATH ubuntu@$1
  ;;
sync)
  shift
  sync
  ;;
tf)
  shift
  terraform $@
  ;;
wup)
  sudo wg-quick up wg0
  ;;
wdown)
  sudo wg-quick down wg0
  ;;
*)
  echo $"Usage: $0 ssh <ip>|sync|wup|wdown|tf <commands>|conf <public_key> <allowed_ips>"
  exit 1
  ;;
esac
