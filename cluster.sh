#!/usr/bin/env sh
set -m

EJABBERDCTL=$HOME/bin/ejabberdctl
HOSTNAME_S=$(hostname -s) # ejabberd-0
HOSTNAME_F=$(hostname -f) # ejabberd-0.ejabberd.default.svc.cluster.local
HEADLESS_SERVICE="${HOSTNAME_F/$HOSTNAME_S./}" # ejabberd.default.svc.cluster.local
EJABBERD_NODE="ejabberd@$HOSTNAME_F" # ejabberd@ejabberd-0.ejabberd.default.svc.cluster.local

echo $HOME
echo $EJABBERDCTL
echo $HEADLESS_SERVICE
echo $EJABBERD_NODE

$EJABBERDCTL foreground &

echo "launched ejabberd in foreground, sleeping"

sleep 5

IPS=$(nslookup $HEADLESS_SERVICE | tail -n +3 | grep "Address:" | sed -E 's/^Address: (.*)$/\1/')
for IP in ${IPS}
do
    echo "looking up hostname for: $IP"
    HOSTNAME=$(nslookup $IP | tail -n +3 | grep -E '[^=]*= (.*).'"$HEADLESS_SERVICE"'$'  | sed -E 's/[^=]*= (.*).'"$HEADLESS_SERVICE"'$/\1/')
    if [[ "$HOSTNAME_S" == "$HOSTNAME" ]] ; then
        echo "found own hostname, skipping"
        continue
    fi
    echo "trying to connect to node with hostname $HOSTNAME.$HEADLESS_SERVICE"
    chmod 600 $HOME/.erlang.cookie
    $EJABBERDCTL join_cluster "ejabberd@$HOSTNAME.$HEADLESS_SERVICE"
    if [[ $? -eq 0 ]] ; then
        echo "successfully joined";
        break
    else
        echo "failed to join, trying next";
    fi
done

chmod 600 $HOME/.erlang.cookie
$EJABBERDCTL list_cluster

#Define cleanup procedure
cleanup() {
    echo "Container stopped, performing cleanup..."
    chmod 600 $HOME/.erlang.cookie
    $EJABBERDCTL leave_cluster "$EJABBERD_NODE"
    chmod 600 $HOME/.erlang.cookie
    $EJABBERDCTL stop
}

#Trap SIGTERM
trap 'cleanup' SIGTERM

#Wait
wait $!
