This repository contains a Dockerfile that builds a custom Docker image for debugging Kubernetes clusters. The image is based on the `nicolaka/netshoot` image and includes additional tools such as `crictl` and `jq`.

## Tools Included

- `crictl`: A command-line interface for CRI-compatible container runtimes, which allows you to inspect and debug container runtimes and containers.
- `jq`: A lightweight and flexible command-line JSON processor, useful for parsing and manipulating JSON data.

## Building the Image

To build the Docker image, run the following command in the directory containing the Dockerfile:

```
docker build -t <yourDockerHubUsername>/kubernetes-cluster:version2.0 .
```

Replace `<yourDockerHubUsername>` with your actual Docker Hub username.

## Saving and Transferring the Image

To save the built Docker image to your local machine, use the following command:

```
docker save -o kubernetes-cluster-version2.0.tar <yourDockerHubUsername>/kubernetes-cluster:version2.0
```

To transfer the saved image to a Kubernetes node, use the `scp` command:

```
scp kubernetes-cluster-version2.0.tar <username>@<node-ip>:~/
```

Replace `<username>` with the username for the Kubernetes node and `<node-ip>` with the IP address of the node.

## Importing the Image on the Kubernetes Node

On the Kubernetes node, import the transferred image using the `ctr` command:

```
sudo ctr -n k8s.io images import /home/<username>/kubernetes-cluster-version2.0.tar
```

Replace `<username>` with the username for the Kubernetes node.

To confirm the image import, run:

```
sudo ctr -n k8s.io images list | grep kubernetes-cluster
```

## Deploying the Debugger Pod

To deploy the debugger pod as a DaemonSet, use the following command:

```
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: node-debugger2
spec:
  selector:
    matchLabels:
      app: debugger
  template:
    metadata:
      labels:
        app: debugger
    spec:
      hostNetwork: false
      containers:
      - name: debugger
        image: <yourDockerHubUsername>/kubernetes-cluster:version2.0
        command: ["sleep", "10000d"]
        imagePullPolicy: IfNotPresent
        volumeMounts:
        - name: containerd-socket
          mountPath: /run/containerd/containerd.sock
      volumes:
      - name: containerd-socket
        hostPath:
          path: /run/containerd/containerd.sock
          type: Socket
      tolerations:
      - operator: "Exists"
      nodeSelector:
        kubernetes.io/os: linux
EOF
```

Replace `<yourDockerHubUsername>` with your actual Docker Hub username.

## Accessing the Debugger Pod

To check the status of the debugger pods, run:

```
kubectl get pods -l app=debugger
```

To open a shell inside the debugger pod, run:

```
kubectl exec -it $(kubectl get pods -l app=debugger -o jsonpath='{.items[0].metadata.name}') -- /bin/sh
```

Once inside the pod, you can use various debugging tools like `curl`, `ping`, `crictl`, and `jq` to inspect and debug your Kubernetes cluster and its networking.