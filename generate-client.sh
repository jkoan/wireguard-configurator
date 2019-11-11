#!/bin/bash

# WireGuard Certificate and Config generator

# Parameters (Change here pls)

interface=${WG_INTERFACE:-wg0}	# wireguard interface to configure, default: wg0
workingdir=${WG_PWD:-auto}	# working directory default: auto=scriptdir
network=${WG_NETWORK:-10.255.255.}		# first three network octets (currently only /24 supported), default: 10.255.255.
dns=				# dns server that the clients will use, default is empty (will be asked on execution)
hostname=			# hostname the clients will connect to, usually external, default is empty (will be asked on execution)
serverport=51820		# server port for external clients
copydest=/home/pi/		# destination for config files to be copied to (for scp access)
user=pi				# user to own the copied config afterwards

ask_question_with_default(){
  # 1. arg out val
  # 2. arg is Text
  # 3. arg is default value
  # 4. arg (optional) validator function
  # return is the result
  set -x
  local valid_input=0
  read $1 <<< "$3"
  if [ $# -eq 4 ]; then
    local validator=$4
    local has_validator=1
  else
    local has_validator=0
  fi
  while true; do 
    echo -n "$2 [$3]: "
    read tmp
    if [ -z $tmp ]; then
      read $1 <<< "$3"
    else
      read $1 <<< "$tmp"
    fi
    if [ $has_validator -eq 1 ]; then
      $validator $tmp
      local RC=$?
      if [ $RC -eq 0 ]; then
        return 0
      fi
    else
      return 0
    fi
  done
}

fail(){
return 0
}



# Script, pls don't change much here:
if [ ! X${workingdir} = Xauto ]; then
  cd $(dirname $(readlink -f $0))
fi

if ! [ $(id -u) -eq 0 ]
then
  echo "You are not running this script as root! Please use sudo (or equivalent)!"
  #exit 1
fi

cd $workingdir

echo -n "Enter client name: "
read client
wg genkey | tee certs/$client-private.key | wg pubkey > certs/$client-public.key

# Check for a free IP address for the client

echo "Checking for first free IP in network ${network}0/24."

for host in {1..200}
do
  address=$network$host
#  echo $address
  if ! grep -q $address $interface.conf
  then
    echo "Found IP: "$address
    break
  fi
done


ask_question_with_default	interface	"Enter interface to be configured" 	${interface}
ask_question_with_default	dns		"Enter DNS address" 			"${dns}" fail
ask_question_with_default	hostname	"Enter public server address" 		${hostname}
ask_question_with_default	serverport	"Enter external server port" 		${serverport}

cat << ENDCLIENT > client-configs/$client.conf
[Interface]
Privatekey = $(cat certs/$client-private.key)
Address = $address
DNS = $dns

[Peer]
PublicKey = $(cat certs/server-public.key)
Endpoint = $hostname:$serverport
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
ENDCLIENT

cat << ENDSERVER >> $interface.conf
# Client config $client
[Peer]
PublicKey = $(cat certs/$client-public.key)
AllowedIPs = $address/32
ENDSERVER

echo "Copying config to $copydest$client.conf and giving user $user ownership"
cp /etc/wireguard/client-configs/$client.conf $copydest$client.conf
chown $user $copydest$client.conf


echo "Do you wish to restart Wireguard interface $interface now?"
select yn in "Yes" "No"; do
    case $yn in
        Yes ) wg-quick down $interface;wg-quick up $interface;echo "$interface was restarted!";break;;
        No ) echo "Please restart $interface manually to reload the config";break;;
    esac
done