# kubernetes-ejabberd
A really dumb way to run an ejabberd cluster on kubernetes.
WARNING: Currently only works with ejabberdctl from master (not 21.01).

This will allow you to run an ejabberd cluster in kubernetes using a statefulset, a headless service, some shell script magic and the official docker image.
Its lazy mode, no custom docker image, the script is mounted into the container using a config map volume mount.

1. Create a ConfigMap with a field cluster.sh and the value being the cluster.sh script in this repository.
3. Create a StatefulSet with a headless service and use the official docker image (ie. ejabberd/ecs:21.01), set the command to "/home/ejabberd/cluster/cluster.sh" and mount the config map to /home/ejabberd/cluster.
4. Profit!

The script is using ejabberdctl foreground, ejabberdctl join_cluster, ejabberdctl list_cluster, ejabberdctl leave_cluster and ejabberdctl stop. So this script should be pretty stable in terms of future proofing. The service has to be headless (ie. clusterIP: None) so there are dns entries for the pods of the statefulset.

If you want to check out the really lazy way (statefulset ordinal 0 is always master), see the mongooseim launch script:
https://github.com/esl/mongooseim-docker/blob/master/member/start.sh
