#!/bin/bash

terraform output -raw management_talos_config >|management_talosconfig
export TALOSCONFIG=$PWD/management_talosconfig

terraform output -raw management_kube_config >|management_kubeconfig
export KUBECONFIG=$PWD/management_kubeconfig
