#!/usr/bin/env sh
set -m

EJABBERDCTL=$HOME/bin/ejabberdctl
HOSTNAME_S=$(hostname -s) # ejabberd-0
HOSTNAME_F=$(hostname -f) # ejabberd-0.ejabberd.default.svc.cluster.local
HEADLESS_SERVICE="${HOSTNAME_F/$HOSTNAME_S./}" # ejabberd.default.svc.cluster.local
ERLANG_NODE_ARG="ejabberd@$HOSTNAME_F" # ejabberd@ejabberd-0.ejabberd.default.svc.cluster.local
ERLANG_NODE=$ERLANG_NODE_ARG

echo $HOME
echo $EJABBERDCTL
echo $HEADLESS_SERVICE
echo $ERLANG_NODE_ARG

IPS=$(nslookup $HEADLESS_SERVICE | tail -n +3 | grep "Address:" | sed -E 's/^Address: (.*)$/\1/')
for IP in ${IPS}
do
    echo "looking up hostname for: $IP"
    HOSTNAME=$(nslookup $IP | tail -n +3 | grep -E '[^=]*= (.*).'"$HEADLESS_SERVICE"'$'  | sed -E 's/[^=]*= (.*).'"$HEADLESS_SERVICE"'$/\1/')
    if [[ "$HOSTNAME_S" == "$HOSTNAME" ]] ; then
        echo "found own hostname, skipping"
        continue
    fi
    $EJABBERDCTL -n $ERLANG_NODE_ARG start
    $EJABBERDCTL -n $ERLANG_NODE_ARG started
    echo "trying to connect to node with hostname $HOSTNAME.$HEADLESS_SERVICE"
    $EJABBERDCTL -n $ERLANG_NODE_ARG join_cluster "ejabberd@$HOSTNAME.$HEADLESS_SERVICE"
    CLUSTERING_RESULT=$?
    $EJABBERDCTL -n $ERLANG_NODE_ARG list_cluster
    $EJABBERDCTL -n $ERLANG_NODE_ARG stop
    $EJABBERDCTL -n $ERLANG_NODE_ARG stopped
    if [[ $? -eq 0 ]] ; then
        echo "successfully joined";
        break
    else
        echo "failed to join, trying next";
    fi
done

#Define cleanup procedure
cleanup() {
    echo "Container stopped, performing cleanup..."
    $EJABBERDCTL -n $ERLANG_NODE_ARG leave_cluster "$ERLANG_NODE_ARG"
    $EJABBERDCTL -n $ERLANG_NODE_ARG stop
}

#Trap SIGTERM
trap 'cleanup' SIGTERM

echo "launching in foreground"
$EJABBERDCTL -n $ERLANG_NODE_ARG foreground &

#Wait
wait $!
