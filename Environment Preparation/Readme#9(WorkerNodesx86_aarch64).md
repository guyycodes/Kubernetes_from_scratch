# Setup Worker Nodes for amd64 or x86 architecture Configure containerd and runc and kata.v2 shims 
### NOTE: Raspberry pis are arm64 and not amd64 architecture, go to second Heading for arm64
- this gets done on all worker nodes:
- Kublet: controls each worker node, provides apis that are used by the control plane to manage nodes and pods, interacts with the ontainer runtime

- Kube-proxy: manages the ip tables rules on the node to provide virtual network acess to pods

- Container runtime: Downloads images and runs containers (Docker and Containerd)

- We need to install 3 packages socat, conntrack, ipset

```
sudo apt-get install socat conntrack ipset
sudo apt-get install -y containerd

```
- you need to install all these on the worker node
- use wget to install binaries:
```
wget -q --show-progress --https-only --timestamping \
https://github.com/kubernetes-sigs/cri-tools/releases/download/v1.30.0/crictl-v1.30.0-linux-amd64.tar.gz \
https://github.com/opencontainers/runc/releases/download/v1.1.4/runc.amd64 \
https://github.com/containernetworking/plugins/releases/download/v1.1.1/cni-plugins-linux-amd64-v1.1.1.tgz \
https://storage.googleapis.com/kubernetes-release/release/v1.30.0/bin/linux/amd64/kubectl \
https://storage.googleapis.com/kubernetes-release/release/v1.30.0/bin/linux/amd64/kube-proxy \
https://storage.googleapis.com/kubernetes-release/release/v1.30.0/bin/linux/amd64/kubelet
// use kata containers instead of runsc - follow the installation guide
https://github.com/kata-containers/kata-containers/blob/main/docs/install/kata-containers-3.0-rust-runtime-installation-guide.md#build-from-source-installation
```
- now make directories
```
sudo mkdir -p /etc/cni/net.d /opt/cni/bin /var/lib/kubelet /var/lib/kube-proxy /var/lib/kubernetes /var/run/kubernetes
```
- Make some of the file executable
```
chmod +x kubectl kube-proxy kubelet runc.amd64

// rename runcand64 to runc
sudo mv runc.amd64 runc

// move files into place
sudo mv kubectl kube-proxy kubelet runc /usr/local/bin

// extract the archive files
sudo tar -xvf crictl-v1.30.0-linux-amd64.tar.gz -C /usr/local/bin

sudo tar -xvf cni-plugins-linux-amd64-v1.1.1.tgz -C /opt/cni/bin/
```

# Managing runc updates and dependencies
#### To remove/update go and not remove but update runc on amd64 or x86
- go is used to compile runc
- First delete go from your machine - /usr/local/go
- then remove go from your ./bashrc path
- then download the version you need and install it by extracting it
```
wget https://go.dev/dl/go1.20.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.20.linux-amd64.tar.gz

// update your path variable
echo "export PATH=$PATH:/usr/local/go/bin" >> ~/.bashrc
source ~/.bashrc
go version

// check the version
go version
```
- Approach updating runc with care - dont remove it just update it it will get over written
```
// stop any servces used by runc
sudo systemctl stop containerd.service

// Backup the Current runc
sudo cp /usr/bin/runc /usr/bin/runc.backup

// Download and Install the New Version

wget -q --show-progress --https-only --timestamping \
https://github.com/opencontainers/runc/releases/download/v1.2.0/runc.amd64

// rename & move to its directory and check version
sudo mv runc.amd64 runc
chmod +x runc.amd64
sudo mv runc.amd64 /usr/local/bin/runc
runc --version
```

# Configure containerd with kata containers
- on all worker nodes
```
sudo mkdir -p /etc/containerd

cat << EOF | sudo tee /etc/containerd/config.toml
version = 2

[plugins]
  [plugins."io.containerd.grpc.v1.cri"]
    sandbox_image = "k8s.gcr.io/pause:3.5"
    [plugins."io.containerd.grpc.v1.cri".containerd]
      default_runtime_name = "runc"
      [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc]
          runtime_type = "io.containerd.runc.v2"
          # runtime_engine and runtime_root are not required for runc with io.containerd.runc.v2

      [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.kata]
          runtime_type = "io.containerd.kata.v2"
EOF
```
- Now make the systemd unit file
```
cat << EOF | sudo tee /etc/systemd/system/containerd.service
[Unit]
Description=containerd container runtime
Documentation=https://containerd.io
After=network.target local-fs.target

[Service]
ExecStartPre=/sbin/modprobe overlay
ExecStart=/usr/bin/containerd
Type=notify
Delegate=yes
KillMode=process
Restart=always
RestartSec=5
LimitNOFILE=1048576
LimitNPROC=infinity
LimitCORE=infinity
TasksMax=infinity
OOMScoreAdjust=-999

[Install]
WantedBy=multi-user.target
EOF
```

# Setup Worker Nodes for arm64/aarch64 architecture:
- Make all your directories
```
sudo mkdir -p /etc/cni/net.d /opt/cni/bin /var/lib/kubelet /var/lib/kube-proxy /var/lib/kubernetes /var/run/kubernetes
```
```
curl -LO https://github.com/kubernetes-sigs/cri-tools/releases/download/v1.30.0/crictl-v1.30.0-linux-arm64.tar.gz
sudo tar -xvf crictl-v1.30.0-linux-arm64.tar.gz -C /usr/local/bin

wget -q --show-progress --https-only --timestamping \
https://github.com/containernetworking/plugins/releases/download/v1.4.1/cni-plugins-linux-arm64-v1.4.1.tgz
sudo tar -xvf cni-plugins-linux-arm64-v1.4.1.tgz -C /opt/cni/bin/

curl -LO https://dl.k8s.io/release/v1.30.0/bin/linux/arm64/kubectl
chmod +x kubectl
sudo mv kubectl /usr/local/bin

wget -q --show-progress --https-only --timestamping \
https://storage.googleapis.com/kubernetes-release/release/v1.30.0/bin/linux/arm64/kube-proxy
chmod +x kube-proxy
sudo mv kube-proxy /usr/local/bin

wget -q --show-progress --https-only --timestamping \
https://storage.googleapis.com/kubernetes-release/release/v1.30.0/bin/linux/arm64/kubelet
chmod +x kubelet
sudo mv kubelet /usr/local/bin
```
## To install runc (Instal before kata you need the compiler)
### first make sure to install go first (we have to build from source)
```
wget https://go.dev/dl/go1.20.linux-arm64.tar.gz
sudo tar -C /usr/local -xzf go1.20.linux-arm64.tar.gz
echo "export PATH=$PATH:/usr/local/go/bin" >> ~/.bashrc
source ~/.bashrc
go version
```
#### next ensure you install libsecomp and setup the go workspace to install runc from source
- instructions can be found here: https://github.com/opencontainers/runc?tab=readme-ov-file

```
sudo apt update && sudo apt install libseccomp-dev

nano ~/.bashrc

// add these to your ~/.bashrc
export GOPATH=$HOME/go
export PATH=$PATH:$GOPATH/bin

// reload ~/.bashrc 
source ~/.bashrc 

// make the directory to clone the runc repo
mkdir -p $GOPATH/src/github.com/opencontainers
cd $GOPATH/src/github.com/opencontainers

// ensure gcc compiler is installed or install it
sudo apt update
sudo apt install build-essential

// clone the repository
cd $GOPATH/src/github.com/opencontainers
git clone https://github.com/opencontainers/runc
cd runc

// install pkg-config
sudo apt-get update
sudo apt-get install pkg-config

// Inside the runc directory, compile the source code:
make

// install
sudo make install

// verify install
sudo mv /usr/local/sbin/runc /usr/local/bin/
runc --version

// use shell hashing if your ./bashrc get cached
hash -r
```

## Install kata containers shim for aarch64/arm64: 
```
// download Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

source $HOME/.cargo/env

// get its version in a variable
export RUST_VERSION=$(rustc --version | awk '{print $2}')
echo $RUST_VERSION

// install rust with the version specified and aarch64/arm64
rustup install ${RUST_VERSION}
rustup default ${RUST_VERSION}-aarch64-unknown-linux-gnu

// Add Musl Target for Static Binary Support
rustup target add aarch64-unknown-linux-musl

// Musl libc Installation
curl -O https://musl.libc.org/releases/musl-1.2.3.tar.gz
tar xf musl-1.2.3.tar.gz
cd musl-1.2.3/
./configure --prefix=/usr/local/
make && sudo make install

// cd back home
cd ~

// install the cross compiler
sudo apt-get update
sudo apt-get install musl musl-dev musl-tools 
sudo apt-get install gcc-aarch64-linux-gnu g++-aarch64-linux-gnu

// Install Kata 3.0 Rust Runtime Shim for aarch64
git clone https://github.com/kata-containers/kata-containers.git
cd kata-containers/src/runtime-rs

// Build and Install:
export CC=aarch64-linux-musl-gcc 
make && sudo make install

// if you get dead code errors try this: See the example of the error below:
#[allow(dead_code)]
const REMOTE_FORWARDER: &str = "remote";

// then make clean old compile that failed & remompile like this:
make clean
export CC=aarch64-linux-musl-gcc
make && sudo make install

// make sure containerd-shim-kata-v2 is in /usr/local/bin
sudo find / -type f -name "containerd-shim-kata-v2" 2>/dev/null

// verify
which containerd-shim-kata-v2
containerd-shim-kata-v2 --version
```

- example error during compilation (open up this file and apply the '#[allow(dead_code)]' annotation)
```
error: constant `REMOTE_FORWARDER` is never used
  --> crates/service/src/event.rs:21:7
   |
21 | const REMOTE_FORWARDER: &str = "remote";
   |       ^^^^^^^^^^^^^^^^
   |
   = note: `-D dead-code` implied by `-D warnings`
   = help: to override `-D warnings` add `#[allow(dead_code)]`

error: constant `LOG_FORWARDER` is never used
  --> crates/service/src/event.rs:22:7
   |
22 | const LOG_FORWARDER: &str = "log";
   |       ^^^^^^^^^^^^^

error: method `type` is never used
  --> crates/service/src/event.rs:34:14
   |
30 | pub(crate) trait Forwarder {
   |                  --------- method in this trait
...
34 |     async fn r#type(&self) -> String;
```