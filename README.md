# kubernetes-ejabberd
A really dumb way to run an ejabberd cluster on kubernetes.

This will allow you to run an ejabberd cluster in kubernetes using a statefulset, a headless service, some shell script magic and the official docker image.
Its lazy mode, no custom docker image, the script is mounted into the container using a config map volume mount.

1. Create a ConfigMap with a field cluster.sh and the value being the cluster.sh script in this repository.
2. Create a StatefulSet with the official docker image (ie. ejabberd/ecs:21.01), set the command to "/home/ejabberd/cluster/cluster.sh" and mount the config map to /home/ejabberd/cluster. You also need to set the environment variable HEADLESS_SERVICE to the full dns name of the headless service associated to the statefulset (ie. ejabberd.default.svc.cluster.local).
3. Profit!

The script is using ejabberdctl foreground, ejabberdctl join_cluster, ejabberdctl list_cluster and ejabberdctl leave_cluster. So this script should be pretty stable in terms of future proofing. The service has to be headless (ie. clusterIP: None) so there are dns entries for the pods of the statefulset.

