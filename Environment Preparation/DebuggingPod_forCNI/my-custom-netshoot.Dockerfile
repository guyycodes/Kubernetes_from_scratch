# This Dockerfile does the following:

#     Installs crictl by downloading the binary and extracting it to /usr/local/bin.
#     Installs jq using apk, the package manager for Alpine Linux, with the --no-cache option to keep the image size down by not caching the index locally.

FROM nicolaka/netshoot

# Install crictl
RUN wget https://github.com/kubernetes-sigs/cri-tools/releases/download/v1.21.0/crictl-v1.21.0-linux-amd64.tar.gz \
    && tar zxvf crictl-v1.21.0-linux-amd64.tar.gz -C /usr/local/bin \
    && rm -f crictl-v1.21.0-linux-amd64.tar.gz

# Install jq
RUN apk --no-cache add jq

# saves a docker image to your computer
# docker save -o kubernetes-cluster-version2.0.tar gbeals1/kubernetes-cluster:version2.0

# copies the image from your computer to the node
# scp kubernetes-cluster-version2.0.tar levelup@192.168.30.11:~/
# sudo ctr -n k8s.io images import /home/levelup/kubernetes-cluster-version2.0.tar

# confirms the copy
# sudo ctr -n k8s.io images list | grep kubernetes-cluster

# use this command to deploy the debugger pod
# cat <<EOF | kubectl apply -f -
# apiVersion: apps/v1
# kind: DaemonSet
# metadata:
#   name: node-debugger2
# spec:
#   selector:
#     matchLabels:
#       app: debugger
#   template:
#     metadata:
#       labels:
#         app: debugger
#     spec:
#       hostNetwork: false
#       containers:
#       - name: debugger
#         image: <yourDockkerHubUsername>/kubernetes-cluster:version2.0
#         command: ["sleep", "10000d"]
#         imagePullPolicy: IfNotPresent
#         volumeMounts:
#         - name: containerd-socket
#           mountPath: /run/containerd/containerd.sock
#       volumes:
#       - name: containerd-socket
#         hostPath:
#           path: /run/containerd/containerd.sock
#           type: Socket
#       tolerations:
#       - operator: "Exists"
#       nodeSelector:
#         kubernetes.io/os: linux
# EOF
  
  
    
    # check the pods status
    # kubectl get pods -l app=debugger

    # Open up the pod to get inside
    # kubectl exec -it $(kubectl get pods -l app=debugger -o jsonpath='{.items[0].metadata.name}') -- /bin/sh

    #  now your inside the pod, you can debug from in here
    #  use curl commands and ping command etc. to test your CNI from the inside
    #  crictl version
    #  jq --version