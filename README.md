# microk8s-charmed-kubeflow


# OUR_ENV

|ENV           |VERSION  |
|--------------|---------|
|Ubuntu        |22.04    |
|GPU           |A100 80G |
|Graphic Driver|515.86.01|
|CUDA          |11.7     |
|cuDNN         |V11.8.89 |
|Docker        |23.0.3   |

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
# Connect to Kubeflow (Remote)

```nginx
# /etc/nginx/conf.d/kubeflow.conf
server {
        listen YOUR_PORT;
        server_name localhost;
        location / {
                proxy_pass http://10.64.140.43.nip.io;
                proxy_http_version 1.1;
                proxy_set_header Upgrade $http_upgrade;
                proxy_set_header Connection "Upgrade";
                proxy_set_header Host $host;
                proxy_pass_header Authorization;
                proxy_set_header Accept-Encoding "";
        }
}
```

# Connect to microk8s dashboard (Remote)

```
microk8s enable dashboard

microk8s kubectl create token default

microk8s kubectl port-forward -n kube-system service/kubernetes-dashboard 10443:443
```

Print Token
```
token=$(microk8s kubectl -n kube-system get secret | grep default-token | cut -d " " -f1)
microk8s kubectl -n kube-system describe secret $token
```

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: dashboard
  namespace: kube-system
  annotations:
    # use the shared ingress-nginx
    kubernetes.io/ingress.class: public
    nginx.ingress.kubernetes.io/backend-protocol: "HTTPS"
    nginx.ingress.kubernetes.io/rewrite-target: /$2
    nginx.ingress.kubernetes.io/configuration-snippet: |
      rewrite ^(/dashboard)$ $1/ redirect;
spec:
  # https://kubernetes.io/docs/concepts/services-networking/ingress/
  # https://kubernetes.github.io/ingress-nginx/user-guide/tls/
  rules:
  - http:
      paths:
      - path: /dashboard(/|$)(.*)
        pathType: ImplementationSpecific
        backend:
          service:
            name: kubernetes-dashboard
            port:
              number: 443
```

```
microk8s kubectl apply -f ingress-dashboard.yaml
```

# Build Kubeflow Jupyter Docker(with NVC)

[kubeflow_jupyter](https://github.com/z1z0nhist/microk8s-charmed-kubeflow/tree/main/kubeflow_jupyter)

# For GPU Resource

```
microk8s enable gpu
```

# Reference

[charmed-kubeflow](https://charmed-kubeflow.io/docs/get-started-with-charmed-kubeflow)

[NGC-pytorch](https://catalog.ngc.nvidia.com/orgs/nvidia/containers/pytorch/tags)
