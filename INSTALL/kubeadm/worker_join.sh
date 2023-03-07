#!/bin/bash
kubeadm join 10.163.1.106:6443 --token abcdef.0123456789abcdef --discovery-token-ca-cert-hash sha256:6c5f2e22a408ffda3937d435474377d2a8fec0e3b99b1aa6f2bfa473394d80f9 --ignore-preflight-errors=SystemVerification
