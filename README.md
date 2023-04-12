# microk8s-charmed-kubeflow


# OUR_ENV

|ENV           |VERSION  |
|--------------|---------|
|Ubuntu        |22.04    |
|A100 80G      |         
|Graphic Driber|515.86.01|
|CUDA          |11.7     |
|cuDNN         |V11.8.89 |

# 1. Install and prepare MicroK8s

```
sudo snap install microk8s --classic --channel=1.24/stable
```

```
sudo usermod -a -G microk8s $USER
newgrp microk8s
```

```
sudo chown -f -R $USER ~/.kube
```

```
microk8s enable dns storage ingress metallb:10.64.140.43-10.64.140.49
```

# 2. Install Juju

```
sudo snap install juju --classic
```

```
juju bootstrap microk8s
```

```
juju add-model kubeflow
```

# 3. Deploy Charmed Kubeflow

```
juju deploy kubeflow --trust  --channel=1.7/stable
```

```
watch -c juju status --color
```

## troubleshoot
```
microk8s kubectl get po -n kubeflow
```

If you get : 

```
“error”:“too many open files”
```

then,

```
sudo sysctl fs.inotify.max_user_instances=1280
sudo sysctl fs.inotify.max_user_watches=655360
```

# 4. Configure the Charmed Kubeflow components

```
juju config dex-auth public-url=http://10.64.140.43.nip.io
juju config oidc-gatekeeper public-url=http://10.64.140.43.nip.io
```

```
juju config dex-auth static-username=admin
juju config dex-auth static-password=admin
```

# Reference

[charmed-kubeflow](https://charmed-kubeflow.io/docs/get-started-with-charmed-kubeflow)

[NGC-pytorch](https://catalog.ngc.nvidia.com/orgs/nvidia/containers/pytorch/tags)
