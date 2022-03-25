#!/bin/sh
set -e

echo "Checking for new peer instances every 5 seconds..." 

# Auth password for keydb-cli
export REDISCLI_AUTH=$(echo $KEYDB_PASSWORD)

# Extract local IPV6 address
ip=$(grep fly-local-6pn /etc/hosts | awk '{print $1}')

detect_peers()
{
  # Extract peer KeyDB server IPV6 addresses
  others=$( (dig aaaa global.$FLY_APP_NAME.internal @fdaa::3 +short | grep -v "$ip") || echo "")
  # Add new peers using the CLI to avoid restarting KeyDB
  if ( ps aux | grep -v grep | grep -q keydb-server ); then
    info=$(keydb-cli info replication)
    membercount=$(echo "$info" | grep "_host:" | wc -l)
    echo "Detected replicas: $membercount"
    for i in $others; do
      if ! (echo $info | grep -q "_host:$i"); then # check masters
        echo "Adding peer $i with keydb-cli"
        keydb-cli replicaof $i 6379
      fi
    done
  fi
}

remove_from_peers()
{
  # Extract peer KeyDB server IPV6 addresses
  others=$( (dig aaaa global.$FLY_APP_NAME.internal @fdaa::3 +short | grep -v "$ip") || echo "")
  # Remove from peers using the CLI to avoid restarting KeyDB
  if ( ps aux | grep -v grep | grep -q keydb-server ); then
    info=$(keydb-cli info replication)
    membercount=$(echo "$info" | grep "_host:" | wc -l)
    echo "Detected replicas: $membercount"
    for i in $others; do
      if (echo $info | grep -q "_host:$i"); then # check masters
        echo "Removing from peer $i with keydb-cli"
        keydb-cli -h $i replicaof remove $ip 6379
      fi
    done
  fi
}

shutdown() 
{ 
  echo "Shutdown signal!"
  remove_from_peers
}

trap shutdown SIGTERM SIGINT

# Check periodically
while true; do
  detect_peers
  sleep 5
done
