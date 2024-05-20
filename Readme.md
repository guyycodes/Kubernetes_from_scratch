Kubernetes Setup Guide
======================
![Kubernetes Logo](https://upload.wikimedia.org/wikipedia/commons/thumb/3/39/Kubernetes_logo_without_workmark.svg/100px-Kubernetes_logo_without_workmark.svg.png)
Welcome to the Kubernetes Setup Guide! This guide aims to help you get started with Kubernetes, a powerful open-source platform for automating deployment, scaling, and management of containerized applications. This guide will provide step-by-step instructions to set up your Kubernetes cluster from scratch. There are many tools that automater this process, but if your interested in learning Kubernetes a little more deeply this guide can help.

Prerequisites
-------------

Before you begin, make sure you have the following:

-   Hardware Requirements:

    -   Multiple computers, servers, or Raspberry Pi devices (Raspberry Pi 4/5 recommended)
    -   Minimum 2 GB RAM per node
    -   At least 16 GB of storage per node
-   Operating System:

    -   A Linux-based operating system (Ubuntu 20.04 or later recommended)
-   Network Requirements:

    -   Stable internet connection for downloading required components
    -   Private network connectivity between all nodes in the cluster
    -   A free account with Docker & Dockerhub
-   Other Tools and Dependencies:

    -   `kubectl` (Kubernetes command-line tool)
    -   `calicoctl ` (calico command-line tool)
    -   [kubernetes](https://github.com/kubernetes/kubernetes) 
    -   [containerd](https://github.com/containerd/containerd) 
    -   [calico](https://github.com/projectcalico) 
    -   [cni](https://github.com/containernetworking/cni) 
    -   [etcd](https://github.com/etcd-io/etcd) 
    -   [kata](https://github.com/kata-containers)

Guide Overview
--------------

This guide is structured to walk you through the following steps:

1.  Environment Preparation: Setting up the required tools and network configuration.
2.  Cluster Initialization: Initializing the Kubernetes control plane.
3.  Node Setup: Adding worker node to the cluster.
4.  Deploying Applications: Installing and managing applications on the Kubernetes cluster.
5.  Monitoring and Maintenance: Setting up tools to monitor and maintain the cluster.

Let's Get Started
-----------------

Proceed to the `Environment Preparation` directory/section to start setting up your Kubernetes environment!