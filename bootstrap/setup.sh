#!/usr/bin/env bash

############################################################################################################################################
###  Script     : setup.sh                                                                                                               ###
###  Author     : Anurag Singh Rajawat                                                                                                   ###
###  Date       : 2024/06/08                                                                                                             ###
###  Last Edited: 2024/06/08, Anurag Singh Rajawat                                                                                       ###
###  Description: Script to setup k0s single node cluster and ArgoCD                                                                     ###
############################################################################################################################################

installKubectl() {
  sudo apt-get update
  sudo apt-get install -y apt-transport-https ca-certificates curl gnupg

  sudo mkdir -p -m 755 /etc/apt/keyrings
  [[ -f /etc/apt/keyrings/kubernetes-apt-keyring.gpg ]] && sudo rm -f /etc/apt/keyrings/kubernetes-apt-keyring.gpg
  curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
  sudo chmod 644 /etc/apt/keyrings/kubernetes-apt-keyring.gpg

  echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
  sudo chmod 644 /etc/apt/sources.list.d/kubernetes.list

  sudo apt-get update
  sudo apt-get install -y kubectl
}

setupAutoCompletion() {
  echo -n "Setting auto-completion"

  if [[ ${SHELL##*/} == "bash" ]]; then
    echo " for ${SHELL##*/} shell"
    kubectl completion bash | sudo tee /etc/bash_completion.d/kubectl > /dev/null
    sudo chmod a+r /etc/bash_completion.d/kubectl
    echo 'alias k=kubectl' >>~/.bashrc
    echo 'complete -o default -F __start_kubectl k' >>~/.bashrc
  elif [[ ${SHELL##*/} == "zsh" ]]; then
    echo " for ${SHELL##*/} shell"
    echo "alias k=kubectl" >>~/.zshrc
    echo ". <(kubectl completion zsh)" >>~/.zshrc
  fi
}

installK0s() {
  curl -sSLf https://get.k0s.sh | sudo sh

  echo "⚙️ Installing k0s as a service"
  sudo k0s install controller --single

  echo "🏁 Starting k0s"
  sudo k0s start

  echo "🔄 Waiting for node to become ready"
  sleep 120
  if [[ ! $(sudo k0s kubectl wait --for=condition=ready --timeout=10m "$(sudo k0s kubectl get no -o name)")  ]]; then
      echo "Timeout while waiting for node to become ready"
      exit 1
  fi
}

installArgo() {
  kubectl apply -k "$(dirname $0)"/argocd/
  kubectl apply -f "$(dirname $0)"/bootstrap.yaml
}

main() {
  if [[ ! $(command -v kubectl) ]]; then
    echo "🚓 Installing Kubectl"
    installKubectl
    setupAutoCompletion
    echo "🎉 Successfully installed Kubectl"
  else
    echo "Skipping Kubectl installation as it is already installed."
  fi

  if [[ ! $(command -v k0s) ]]; then
    echo "🚓 Installing k0s"
    installK0s
    echo "🎉 Successfully installed K0s"
  else
    if [[ ! $(sudo k0s kubectl wait --for=condition=ready --timeout=10m "$(sudo k0s kubectl get no -o name)")  ]]; then
      installK0s
    else
      echo "Skipping k0s installation as it is already installed."
    fi
  fi

  [[ ! -f "$HOME/.kube/config" ]] && mkdir "$HOME/.kube"
  sudo k0s kubeconfig admin > "$HOME/.kube/config"
  chmod 600 "$HOME/.kube/config"

  echo "🚀 $(kubectl get no -o name) is ready"
  kubectl get no -o wide

  echo "🚓 Installing ArgoCD"
  installArgo
  echo "🚀 Successfully installed ArgoCD"
}

main
