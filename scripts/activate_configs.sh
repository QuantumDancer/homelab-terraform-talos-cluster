#!/bin/bash

terraform output -raw talos_config >|talosconfig
export TALOSCONFIG=$PWD/talosconfig

terraform output -raw kube_config >|kubeconfig
export KUBECONFIG=$PWD/kubeconfig
