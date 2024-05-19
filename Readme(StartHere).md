Kubernetes Setup Guide
======================

Welcome to the Kubernetes Setup Guide! This guide aims to help you get started with Kubernetes, a powerful open-source platform for automating deployment, scaling, and management of containerized applications. Whether you are a beginner or an experienced professional, this guide will provide step-by-step instructions to set up your Kubernetes cluster from scratch.

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
-   Other Tools and Dependencies:

    -   `kubectl` (Kubernetes command-line tool)
    -   [kubernetes](https://github.com/kubernetes/kubernetes) v1.21.0
    -   [containerd](https://github.com/containerd/containerd) v1.4.4
    -   [coredns](https://github.com/coredns/coredns) v1.8.3
    -   [cni](https://github.com/containernetworking/cni) v0.9.1
    -   [etcd](https://github.com/etcd-io/etcd) v3.4.15
    -   Docker or any other container runtime supported by Kubernetes

Guide Overview
--------------

This guide is structured to walk you through the following steps:

1.  Environment Preparation: Setting up the required tools and network configuration.
2.  Cluster Initialization: Initializing the Kubernetes control plane.
3.  Node Setup: Adding worker nodes to the cluster.
4.  Deploying Applications: Installing and managing applications on the Kubernetes cluster.
5.  Monitoring and Maintenance: Setting up tools to monitor and maintain the cluster.

Let's Get Started
-----------------

Proceed to the `Environment Preparation` directory/section to start setting up your Kubernetes environment!