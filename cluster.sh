#!/usr/bin/env sh
set -m

EJABBERDCTL=$HOME/bin/ejabberdctl
EJABBERD_NODE=ejabberd@$(hostname).$HEADLESS_SERVICE

echo $HOME
echo $EJABBERDCTL
echo $HEADLESS_SERVICE
echo $EJABBERD_NODE

$EJABBERDCTL foreground &

echo "launched ejabberd in foreground, sleeping"

sleep 5

OWN_IP=$(nslookup $(hostname).$HEADLESS_SERVICE | tail -n +3 | grep "Address:" | sed -E 's/^Address: (.*)$/\1/')
HOSTNAMES=$(nslookup $OWN_IP | tail -n +3 | grep -E '[^=]*= (.*).'"$HEADLESS_SERVICE"'$'  | sed -E 's/[^=]*= (.*).'"$HEADLESS_SERVICE"'$/\1/')
for HOSTNAME in ${HOSTNAMES}
do
    OWN_HOSTNAME=$HOSTNAME
done


IPS=$(nslookup $HEADLESS_SERVICE | tail -n +3 | grep "Address:" | sed -E 's/^Address: (.*)$/\1/')

for IP in ${IPS}
do
    echo $IP
    if [[ "$OWN_IP" == "$IP" ]] ; then
        echo "found own ip, skipping"
        continue
    else
        echo "found different ip, looking up hostname for: $IP"
        HOSTNAMES=$(nslookup $IP | tail -n +3 | grep -E '[^=]*= (.*).'"$HEADLESS_SERVICE"'$'  | sed -E 's/[^=]*= (.*).'"$HEADLESS_SERVICE"'$/\1/')
        for HOSTNAME in ${HOSTNAMES}
        do
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
    fi
done

chmod 600 $HOME/.erlang.cookie
$EJABBERDCTL list_cluster


#Define cleanup procedure
cleanup() {
    echo "Container stopped, performing cleanup..."
    chmod 600 $HOME/.erlang.cookie
    $EJABBERDCTL leave_cluster "ejabberd@$OWN_HOSTNAME.$HEADLESS_SERVICE"
}

#Trap SIGTERM
trap 'cleanup' SIGTERM

#Wait
wait $!
