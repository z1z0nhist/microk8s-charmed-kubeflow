# microk8s-charmed-kubeflow

kubeflow 구축시 문제인지 k8s의 문제인지 각 스텝의 명령어를 실행전에 pod가 모두 run상태인지 확인하고 진행하는 것을 추천합니다.

run 상태가 아닐때 시도하면 bug가 발생합니다.

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

## troubleshooting
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
microk8s kubectl -n kube-system describe secret $(microk8s kubectl -n kube-system get secret | grep admin-user | awk '{print $1}')
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

# default pvc dir

```
/var/snap/microk8s/common/default-storage
```

# Make kubeflow jupyter 

```
microk8s kubectl apply -f - <<EOF
apiVersion: kubeflow.org/v1beta1
kind: Notebook
metadata:
  generation: 1
  labels:
    access-ml-pipeline: "true"
    app: kj-nvidia-torch
  name: kj-nvidia-torch
  namespace: admin
spec:
  template:
    spec:
      containers:
        - image: YOUR_IMG
          imagePullPolicy: Always
          name: YOUR_NAME
          resources:
            limits:
              cpu: 19200m
              memory: 41231686041600m
            requests:
              cpu: "16"
              memory: 32Gi
          volumeMounts:
            - mountPath: /dev/shm
              name: dshm
            - mountPath: /home/jovyan
              name: YOUR-volume
      serviceAccountName: default-editor
      volumes:
        - emptyDir:
            medium: Memory
          name: dshm
        - name: YOUR-volume
          hostPath:
            path: YOUR_MOUNT_PATH
            type: Directory
EOF
```
# Get jupyternotebook logs

```
microk8s kubectl logs -n {YOUR_DEX_NAME} {YOUR_NOTEBOOK_NAME}-0
```

# Troubleshooting

* Jupyter 학습중 죽는문제(확인중)

jupyter-controller에서 ENABLE_CULLING이 기본값 true로 설정되어 있어서

```
microk8s kubectl edit deployment -n kubeflow jupyter-controller
```

# Reference

[charmed-kubeflow](https://charmed-kubeflow.io/docs/get-started-with-charmed-kubeflow)

[NGC-pytorch](https://catalog.ngc.nvidia.com/orgs/nvidia/containers/pytorch/tags)

[Charmed Kubeflow Config](https://charmhub.io/kubeflow-lite/configure/admission-webhook)
