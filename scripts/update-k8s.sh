# run with ./scripts/upgrade-k8s.sh <control-plane-node-ip>
talosctl --nodes "$1" upgrade-k8s --to 1.34.2 # renovate: github-releases=kubernetes/kubernetes
