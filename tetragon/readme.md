# Runtime Security with Tetragon & eBPF
 
> Detect runtime security threats in containers using Tetragon eBPF on the Sock Shop deployed on Amazon EKS.
 
📖 **Full article:** [Runtime Security on Kubernetes with Tetragon & eBPF](https://medium.com/@yasmineelhakem8/runtime-security-on-kubernetes-with-tetragon-ebpf-aad6dde34a43)
 
 
## What is this?
 
This directory contains a set of **Tetragon TracingPolicies** that detect real-world runtime threats inside Kubernetes containers without modifying any application code and without any agent inside the containers.
 
Tetragon runs as a **DaemonSet** (one pod per node) and uses **eBPF** to hook directly into the Linux kernel. Every suspicious action, a shell being spawned, a credential file being read, an unexpected outbound connection, is caught at the kernel level before it can complete undetected.
 
 
## Prerequisites
 
- EKS cluster running 
- `kubectl` configured and pointing at your cluster
- Helm installed
- Tetragon installed in the cluster 
 
## Apply the Policies
 
```bash
kubectl apply -f tetragon/policies/
```
 
Check all policies loaded correctly:
 
```bash
kubectl get tracingpolicies
```
 
## Watch Live Events
 
- Install the `tetra` CLI:
 
- Stream events scoped to the Sock Shop namespace:
 
```bash
kubectl logs -n kube-system -l app.kubernetes.io/name=tetragon \
  -c export-stdout -f --max-log-requests=10 \
  | tetra getevents -o compact --namespace sock-shop \
  | grep -v -E 'linkerd|json-exporter'
```
 

## Policies
 
| File | Hook | Detects |
|---|---|---|
| `detect-shell.yaml` | `sys_execve` | Shell spawned inside a container (`bash`, `sh`, `dash`, `zsh`) |
| `detect-tools.yaml` | `sys_execve` | Attacker tools executed: `curl`, `wget`, `nc`, `nmap`, package managers |
| `detect-cred-access.yaml` | `fd_install` | Reads of `/etc/shadow`, SSH keys, AWS credentials, K8s secrets |
| `detect-k8s-token.yaml` | `fd_install` | Access to the Kubernetes service account token |
| `detect-external-connections.yaml` | `tcp_connect` | Outbound TCP to public IPs — exfiltration, C2 beaconing |
| `detect-dns-exfiltration.yaml` | `udp_sendmsg` | UDP to port 53 — DNS tunneling |
| `detect-port-bind.yaml` | `sys_bind` | New port binding — reverse shells, backdoor listeners |
| `detect-deleted-binary-exec.yaml` | `security_bprm_check` | Execution of binaries deleted from disk after loading |
| `detect-privilege-escalation.yaml` | `__sys_setresuid` | Process attempting to become root (UID 0) |
| `detect-namespace-escape.yaml` | `sys_unshare` | User namespace creation — container escape attempt |
 
