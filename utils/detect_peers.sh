#!/bin/sh

refresh=5
echo "Checking for new peer instances every $refresh seconds..."
export REDISCLI_AUTH=$(echo $KEYDB_PASSWORD)
ip=$(grep fly-local-6pn /etc/hosts | awk '{print $1}')

detect_peers()
{
  peers=$( (dig aaaa global.$FLY_APP_NAME.internal @fdaa::3 +short | grep -v "$ip") || echo "")
  peercount=$(echo "$peers" | grep -v ^$ | wc -l)
  if ( ps aux | grep -v grep | grep -q keydb-server ); then
    replicas=$(keydb-cli info replication | grep "_host:")
    replicacount=$(echo "$replicas" | grep -v ^$ | wc -l)
    echo "-- peer count: $peercount, replica count: $replicacount"
    for p in $peers; do
      peer=$(echo "$p" | tr -d '\n')
      #echo "-- checking peer: $peer"
      if !(echo $replicas | grep -q "$peer"); then
        echo "-- adding replica $peer"
        keydb-cli replicaof $peer 6379
      fi
    done
    for r in $replicas; do
      replica=$(echo $r | awk '{ sub("\r$", ""); split($0,a,"_host:"); print a[2] }')
      #echo "-- checking replica: $replica"
      if !(echo $peers | grep -q "$replica"); then
        echo "-- removing replica $replica"
        keydb-cli replicaof remove $replica 6379
      fi
    done
  fi
}

while true; do
  detect_peers
  sleep $refresh
done
