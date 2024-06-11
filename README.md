# Home Lab

This repository contains configurations for setting up my home lab with a single-node [k0s](https://k0sproject.io/) cluster on an [Ubuntu](https://ubuntu.com/download) system.

# Getting started

1. Clone the repository:
```shell
git clone https://github.com/anurag-rajawat/home-lab.git
```

2. Execute [bootstrap/setup.sh](bootstrap/setup.sh) script. This script automates the setup process.

    It will:
    - Deploy a single-node k0s cluster, and
    - Install Argo CD, for declarative management of other services.

```shell
./bootstrap/setup.sh
```

Rest will be managed by Argo.