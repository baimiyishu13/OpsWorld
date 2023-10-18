安装前必读:

==文档中的IP地址请统一替换，不要一个一个替换!!!==

安装参考；K8S官网:https://kubernetes.io/docs/setup/

 

```
ansible-playbook test.yaml --tags nfs-server
ansible-playbook test.yaml --tags nfs-client

```









全局替换信息，包括 k8s-mano文件夹

| 描述      | 配置信息                    | 备注 |
| --------- | --------------------------- | ---- |
| master1   | 10.243.89.241               |      |
| master2   | 10.243.89.242               |      |
| master3   | 10.243.89.243               |      |
| vip-4     | 10.243.89.244               |      |
| vip-6     | 2409:8027:5a06:500e::227:1d |      |
| harbor    | 10.243.89.243:8080          |      |
| yum挂载点 | 10.243.89.241:8001          |      |
| 网卡      | ens4                        |      |
|           |                             |      |



### 基础环境

高可用Kubernetes集群规划：

| 主机名  | IPv4地址      | IPv6地址                    | vip-4         | vip-6                       |
| ------- | ------------- | --------------------------- | ------------- | --------------------------- |
| master1 | 10.243.89.241 | 2409:8027:5a06:500e::227:18 | 10.243.89.244 | 2409:8027:5a06:500e::227:1d |
| master2 | 10.243.89.242 | 2409:8027:5a06:500e::227:19 | 10.243.89.244 | 2409:8027:5a06:500e::227:1d |
| master3 | 10.243.89.243 | 2409:8027:5a06:500e::227:1a | 10.243.89.244 | 2409:8027:5a06:500e::227:1d |

注意事项: 因需要搭建keepalived和haproxy，确认好 vip

> NG#2022@tst

配置信息：

| 配置信息   | 备注                                      | 描述           |
| ---------- | ----------------------------------------- | -------------- |
| 系统       | openEuler release 22.03 LTS               | lsb_release -a |
| Docker版本 | Docker version 19.03.13, build 4484c46d9d | docker -v      |

#### 1. 配置hosts (所有节点)

修改主机名

```sh
hostnamectl set-hostname master1
```



> 所有节点配置hosts，修改/etc/hosts如下:

```sh
10.243.89.241 master1
10.243.89.242 master2
10.243.89.243 master3
```

#### 2. 配置yaml (master1)

> 对应安装包已上传至master01 /home/migu/ 下，

挂载 ISO

```
# ls /home/migu/ | grep iso
openEuler-22.03-LTS-everything-x86_64-dvd.iso
```

挂载其他

```
# ls /home/migu/ | grep .tar.gz
EPOL.tar.gz
kube.tar.gz
OS.tar.gz
```

==操作：==

```sh
mkdir -p /data/yum/
sudo mount -o loop /home/migu/openEuler-22.03-LTS-everything-x86_64-dvd.iso /data/yum/
tar -zxvf /home/migu/EPOL.tar.gz -C /data/yum
tar -zxvf /home/migu/kube.tar.gz -C /data/yum
cat << EOF > /etc/yum.repos.d/openEuler.repo
[iso]
name=ISO Repository
baseurl=file:///data/yum/iso
enabled=1
gpgcheck=0

[EPOL]
name=EPOL
baseurl=file:///data/yum/EPOL/
enabled=1
gpgcheck=0

[kube118]
name=kube118
baseurl=file:///data/yum/kube118/
enabled=1
gpgcheck=0
EOF

dnf clear all
```

其他节点：

```sh
[iso]
name=ISO Repository
baseurl=http://10.243.89.241:8001/iso/
enabled=1
gpgcheck=0
[EPOL]
name=EPOL
baseurl=http://10.243.89.241:8001/EPOL/
enabled=1
gpgcheck=0
[kube118]
name=kube118
baseurl=http://10.243.89.241:8001/kube118/
enabled=1
gpgcheck=0
```

安装nginx：

```
dnf install -y nginx
cd /data/yum/
python3 -m http.server 8001
```

#### 3.安装ansible

安装

```sh
dnf install ansible  -y
```

修改配置文件：检查主机密钥

```sh
vi  /etc/ansible/ansible.cfg
host_key_checking = False
```

修改hosts文件

```sh
[all]
localhost ansible_connection=local
10.243.89.242
10.243.89.243

[all:vars]
ansible_ssh_user=
ansible_ssh_pass=""
ansible_become=true
ansible_become_method=sudo

[master3]
10.243.89.243

[master3:vars]
ansible_ssh_user=
ansible_ssh_pass=""
ansible_become=true
ansible_become_method=sudo
```



#### 4.系统初始化（所有节点）

docker：

```yaml
ansible-palybook k8s-mano/ansible/playbooks/install_software/docker.yaml
```

:warning: 查看docker版本,如果版本过低需要升级版本，上传文件到/tmp

+ docker-ce-19.03.13-3.el7.x86_64.rpm 
+ docker-ce-cli-19.03.13-3.el7.x86_64.rpm
+ containerd.io-1.3.7-3.1.el7.x86_64.rpm

```sh
# 卸载旧版本docker
dnf remove docker docker-common docker-selinux docker-engine
ansible-playbook k8s-mano/ansible/playbooks/harbor/docker_19.30.yaml
```

docker_19.30.yaml

用户wlznhpt （略）

```sh
ansible-palybook  k8s-mano/ansible/playbooks/user/wlznhpt.yaml
```

关闭selinux、关闭防火墙、禁用swap

```sh
ansible-playbook k8s-mano/ansible/playbooks/init/system-configuration.yaml
```

安装软件

```sh
ansible-playbook k8s-mano/ansible/playbooks/install_software/tool.yaml
```

修改内核参数

```sh
k8s-mano/ansible/playbooks/configure_settings/kernel_conf.yaml
```



#### 5.部署nfs

==master3为server端==

:warning:需要修改ansible配置文件中的IP和IP段

```sh
ansible k8s-mano/ansible/playbooks/install_software/nfs.yaml 
```



NFS 可用性验证

```sh
#查看nfs状态
systemctl status rpcbind
systemctl status nfs-server

systemctl restart rpcbind 
systemctl restart nfs-server 

systemctl stop rpcbind 
systemctl stop nfs-server 

#在服务端验证
[root@master1 ~]#  echo "This is NFS server." > /dockerdata-nfs/nfs.txt
[root@master1 ~]# cat /dockerdata-nfs/nfs.txt
This is NFS server.
#在客户端验证
cat /dockerdata-nfs/nfs.txt
```





```sh
systemctl stop haproxy keepalived
```



#### 7.部署Harbor（master3）

==master3上部署==

> harbor-offline-installer-v2.1.2.tgz

https://github.com/goharbor/harbor/releases/tag/v2.1.2

https://github.com/goharbor/harbor/tree/release-2.1.0

安装文档：官方：https://goharbor.io/docs/2.1.0/install-config/configure-yml-file/

上传harbor包，与 docker-compose-Linux-x86_64

编辑配置文件

```sh
tar -zxvf /tmp/harbor-offline-installer-v2.1.2.tgz -C /root
vim /root/harbor/harbor.yml
# 注释掉https的配置
hostname: #主机ip
data_volume: /data/harbor
```

cd /root/harbor/

```
tar -zxvf /tmp/harbor-offline-installer-v2.1.2.tgz -C /root
mv /tmp/docker-compose-Linux-x86_64 /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose

mkdir /data/harbor
chmod 777 /data/harbor
mkdir /var/log/harbor
chmod 777 /var/log/harbor

bash /root/harbor/install.sh
```

chmod 777 /root/harbor/common

when: inventory_hostname == 'master01'

配置docker文件(所有节点)

```yaml
- name: 创建 Docker daemon.json 文件
  hosts: all
  become: true
  tasks:
    - name: 创建 daemon.json 文件
      copy:
        dest: /etc/docker/daemon.json
        content: |
          {
            "data-root": "/data/docker",
            "exec-opts": ["native.cgroupdriver=systemd"],
            "log-driver": "json-file",
            "insecure-registries": ["10.243.89.243:8080"],
            "log-opts": {
              "max-size": "10m"
            },
            "storage-driver": "overlay2",
            "storage-opts": [
              "overlay2.override_kernel_check=true"
            ]
          }
```



如果通过外网无法访问： 



登陆：admin Harbor12345

docker login 10.243.89.243:8080 -uadmin -pHarbor12345

#### 8.推送镜像

推送镜像的脚本

创建对应的库：so、

```
前提：过滤掉注释的行
[root@master1 migu]# grep -v '^#' image.list  > image2.list
```

```sh
#!/bin/bash

# 读取image.list文件，逐行执行相应的命令
while IFS= read -r image
do
    # 提取镜像名称和标签
    image_name=$(echo "$image" | awk -F '/' '{print $NF}' | awk -F ':' '{print $1}')
    image_tag=$(echo "$image" | awk -F '/' '{print $NF}' | awk -F ':' '{print $2}')
    # 替换镜像地址中的 registry.cmri.cn
    modified_image=$(echo "$image" | sed 's/registry.cmri.cn/10.243.89.243:8080/')

    # 执行docker load命令
    docker load -i "${image_name}_${image_tag}.tar"
    if [ $? -ne 0 ]; then
        echo "执行docker load命令失败，镜像：${image_name}:${image_tag}" >> load_err.list
        continue
    fi
    
    # 执行docker tag命令
    docker tag "$image" "${modified_image}"
    if [ $? -ne 0 ]; then
        echo "执行docker tag命令失败，镜像：${modified_image}" >> docker_tar_err.list
        continue
    fi
    
    # 执行docker push命令
    docker push "${modified_image}"
    if [ $? -ne 0 ]; then
        echo "执行docker push命令失败，镜像：${modified_image}" >> push_err.list
        continue
    fi
    
    echo "处理镜像成功：${modified_image}"
done < image2.list
```

> emsdriver那个不用管， 这个组件不需要了后续再部署，NFVO core/emsdriver这个组件可以删掉了

执行docker push命令失败，镜像：10.243.89.243:8080/so/calico/cni:v3.15.2
执行docker push命令失败，镜像：10.243.89.243:8080/so/calico/kube-controllers:v3.15.2
执行docker push命令失败，镜像：10.243.89.243:8080/so/calico/node:v3.15.2
执行docker push命令失败，镜像：10.243.89.243:8080/so/calico/pod2daemon-flexvol:v3.15.2

```sh
写一个脚本，将calico.yaml中文件的内容
image: calico/cni:v3.15.2 替换成 10.243.89.243:8080/so/calico/cni:v3.15.2
image: calico/pod2daemon-flexvol:v3.15.2 替换成 10.243.89.243:8080/so/calico/pod2daemon-flexvol:v3.15.2
image: calico/node:v3.15.2 替换成 10.243.89.243:8080/so/calico/node:v3.15.2
image: calico/kube-controllers:v3.15.2 替换成 10.243.89.243:8080/so/calico/kube-controllers:v3.15.2


```



image: calico/





需要上传到calico的库

执行docker push命令失败，镜像：10.243.89.243:8080/so/coredns:1.6.7
执行docker push命令失败，镜像：10.243.89.243:8080/so/etcd:3.4.3-0
执行docker push命令失败，镜像：10.243.89.243:8080/so/kube-apiserver:v1.18.0
执行docker push命令失败，镜像：10.243.89.243:8080/so/kube-controller-manager:v1.18.0
执行docker push命令失败，镜像：10.243.89.243:8080/so/kube-proxy:v1.18.0
执行docker push命令失败，镜像：10.243.89.243:8080/so/kube-scheduler:v1.18.0
执行docker push命令失败，镜像：10.243.89.243:8080/so/pause:3.2



将上述镜上传harbor，再拉去到各个master

```sh
[root@master1 ~]# kubeadm config images list --kubernetes-version=v1.18.0
W0523 17:53:03.107680 1153281 configset.go:202] WARNING: kubeadm cannot validate component configs for API groups [kubelet.config.k8s.io kubeproxy.config.k8s.io]
k8s.gcr.io/kube-apiserver:v1.18.0
k8s.gcr.io/kube-controller-manager:v1.18.0
k8s.gcr.io/kube-scheduler:v1.18.0
k8s.gcr.io/kube-proxy:v1.18.0
k8s.gcr.io/pause:3.2
k8s.gcr.io/etcd:3.4.3-0
k8s.gcr.io/coredns:1.6.7

docker pull 10.243.89.243:8080/so/coredns:1.6.7
docker pull 10.243.89.243:8080/so/etcd:3.4.3-0
docker pull 10.243.89.243:8080/so/kube-apiserver:v1.18.0
docker pull 10.243.89.243:8080/so/kube-controller-manager:v1.18.0
docker pull 10.243.89.243:8080/so/kube-proxy:v1.18.0
docker pull 10.243.89.243:8080/so/kube-scheduler:v1.18.0
docker pull 10.243.89.243:8080/so/pause:3.2

docker tag 10.243.89.243:8080/so/coredns:1.6.7 k8s.gcr.io/coredns:1.6.7
docker tag 10.243.89.243:8080/so/etcd:3.4.3-0  k8s.gcr.io/etcd:3.4.3-0
docker tag 10.243.89.243:8080/so/kube-apiserver:v1.18.0 k8s.gcr.io/kube-apiserver:v1.18.0
docker tag 10.243.89.243:8080/so/kube-controller-manager:v1.18.0 k8s.gcr.io/kube-controller-manager:v1.18.0
docker tag 10.243.89.243:8080/so/kube-proxy:v1.18.0 k8s.gcr.io/kube-proxy:v1.18.0
docker tag 10.243.89.243:8080/so/kube-scheduler:v1.18.0 k8s.gcr.io/kube-scheduler:v1.18.0
docker tag 10.243.89.243:8080/so/pause:3.2 k8s.gcr.io/pause:3.2
```

#### 9.集群初始化

dnf search kube 先确定包名

1.18.6 版本

```sh
k8s-mano/ansible/playbooks/install_software/kube_tool.yaml
```

```sh
kubeadm init --kubernetes-version=v1.24.0  \
  --apiserver-advertise-address=192.168.31.201 \
  --pod-network-cidr=10.244.0.0/16 \
  --service-cidr=10.96.0.0/16  \
  --upload-certs \
  --v=5  \
  --image-repository=registry.aliyuncs.com/google_containers \
  --control-plane-endpoint=192.168.31.244:16443
```

k8s 双栈

```yaml
apiVersion: kubeadm.k8s.io/v1beta2
bootstrapTokens:
- groups:
  - system:bootstrappers:kubeadm:default-node-token
  token: abcdef.0123456789abcdef
  ttl: 24h0m0s
  usages:
  - signing
  - authentication
kind: InitConfiguration
localAPIEndpoint:
  advertiseAddress: 10.243.89.241
  bindPort: 6443
nodeRegistration:
  criSocket: /var/run/dockershim.sock
  #name: vm-newimage0825.novalocal
  name: master01
  taints:
  - effect: NoSchedule
    key: node-role.kubernetes.io/master
---
apiServer:
  timeoutForControlPlane: 4m0s
apiVersion: kubeadm.k8s.io/v1beta2
certificatesDir: /etc/kubernetes/pki
clusterName: kubernetes
controllerManager: {}
dns:
  type: CoreDNS
etcd:
  local:
    dataDir: /var/lib/etcd
imageRepository: k8s.gcr.io
controlPlaneEndpoint: "10.243.89.244:16443" 
kind: ClusterConfiguration
featureGates:
  IPv6DualStack: true
kubernetesVersion: v1.18.0
networking:
  dnsDomain: cluster.local
  serviceSubnet: 10.96.0.0/16,2001:db8:42:1::/112
  podSubnet: 10.244.0.0/16,2001:db8:42:0::/56
scheduler: {}
```

  

kubeadm join 10.243.89.244:16443 --token abcdef.0123456789abcdef \
    --discovery-token-ca-cert-hash sha256:7dc7d2b770dc5dd89ff8c5803c550e2756cdceef9658f3fc0194169c136e92f7 \
    --control-plane 

:warning:如果初始化失败，需要重新初始化:

```sh
kubeadm reset -f ; ipvsadm --clear  ; rm -rf ~/.kube
```

初始化成功以后，会产生Token值，用于其他节点加入时使用，因此要记录下初始化成功生成的token值(令牌值)

kubectl连接

```sh
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# 或者：节点配置环境变量，用于访问Kubernetes集群:
cat <<EOF >> /root/.bashrc
export KUBECONFIG=/etc/kubernetes/admin.conf
EOF
source /root/.bashrc
```

 kubeadm reset

kubectl 自动补全：

```sh
source <(kubectl completion zsh)
echo '[[ $commands[kubectl] ]] && source <(kubectl completion zsh)' >> ~/.zshrc
```

采用初始化安装方式，所有的系统组件均以容器的方式运行并且在kube-system命名空间内，此时可以查看Pod状态

> **token**过期处理

```sh
# node
kubeadm token create --print-join-command
# master
kubeadm init phase upload-certs --upload-certs
```

```
kubeadm join 10.243.89.244:16443 --token abcdef.0123456789abcdef     --discovery-token-ca-cert-hash sha256:77c6c878482c8bc1849f50b1935751579d2fba5ea7b097b2ef5291420be35928     --control-plane
```



:warning:**k8s**集群安装失败故障排查

tail -f /var/log/messages

```sh
"Container runtime network not ready" networkReady="NetworkReady=false reason:NetworkPluginNotReady message:Network plugin returns error: cni plugin not initialized"
```

因为cni网络插件Calico未安装

所有节点初始化完成后，查看集群状态

+ NotReady不影响



#### 10.Clico 组件安装

> 支持网络策略 

以下步骤只在master1执行

yaml 文件：https://docs.projectcalico.org/v3.14/manifests/calico.yaml

新：执行init脚本

> 旧：
>
> 需修改yaml中 calico涉及到镜像的版本 v3.15.2
>
> ```sh
> sed -i 's/v3.14.2/v3.15.2/g' calico.yaml
> sed -i 's/172.32.165.33/10.243.89.243/g' calico1.yaml
> ```
>



增加配置：

```sh
-name: IP_AUTODETECTION_METHOD
 value: "interface=ens4"
```

kubectl apply -f calico1.yaml

查看Pod:

```sh
# kubectl get pod -A
```

==到此 k8s 已经安装完成==

---

#### 11.Helm安装mano

> /home/migu/helm.zip

```sh
unzip helm.zip
mv helm /usr/local/sbin/helm
```

准备：

```sh
docker login 10.243.89.243:8080 -uadmin -pHarbor12345
kubectl create namespace nfvo
kubectl create namespace vnfm
```

安装目录

```sh
[root@master1 ~]# ls /home/migu/helm/zhejiangmg
nfvo  vnfm
```



/home/migu/helm/zhejiangmg/nfvo/base 目录下

10.240.152.108:10001 换成 10.243.89.243:8080

```sh
# 过滤出 nfvo和vnfm 目录下 修改仓库地址 10.240.152.108:10001 换成 10.243.89.243:8080
sed -i 's/10.240.152.108:10001/10.243.89.243:8080/g' $(grep "10.240.152.108:10001" -rl /home/migu/helm/zhejiangmg/)

# 过滤出 nodeips 替换成3个master的IP
sed -i 's/10.240.152.106 10.240.152.108 10.240.152.109/10.243.89.241 10.243.89.242 10.243.89.243/g' $(grep "10.240.152.106 10.240.152.108 10.240.152.109" /home/migu/helm/zhejiangmg/vnfm/ -lr)

# 替换vip  10.240.152.106 -> 10.243.89.244
sed -i 's/10.240.152.106/10.243.89.244/g' $(grep "10.243.89.236" /home/migu/helm/zhejiangmg/vnfm/ -lr)

# 修改在harbor账户admin Harbor12345
#查看
grep -A 2 "repositoryCred" $( grep "repositoryCred" /home/migu/helm/zhejiangmg/vnfm/ -lr)
sed -i 's/\(^\s*user:\).*/\1 admin/; s/\(^\s*password:\).*/\1 Harbor12345/' $(grep "repositoryCred" /home/migu/helm/zhejiangmg/vnfm/ -lr)
```



:warning: 重新部署需要：清理掉NFS中的文件

==安装部署nfvo==

```sh
#----------------- 1.安装base模块  -------------------
helm install base nfvo/base -n nfvo
// 发生报错：超出端口
解决方法：
vim /etc/kubernetes/manifests/kube-apiserver.yaml
- --service-node-port-range=1-65535
systemctl daemon-reload
systemctl restart kubelet

// 	重新执行
helm upgrade --install base nfvo/base -n nfvo

#----------------- 2.安装sdc模块    ------------------
helm install cassandra cassandra -n nfvo
helm install dmaap dmaap -n nfvo
helm install sdc sdc -n nfvo

#----------------- 3.安装mariadb ---------------------
helm install mariadb nfvo/mariadb-galera -n nfvo

#----------------- 4.初始化数据库  -------------------
helm install initdb nfvo/vnfm-initdb -n nfvo
手动导入nfvomiddleware.sql文件

#----------------- 5.安装redis  ----------------------
helm install redis nfvo/redis-cluster -n nfvo

#----------------- 6.安装msb     ---------------------
helm install msb nfvo/msb -n nfvo

#----------------- 7.安装业务模块    -----------------
helm install core nfvo/core -n nfvo

#----------------- 8.安装日志模块    -----------------
helm install log nfvo/log_5 -n nfvo

#----------------- 9.安装pod监控模块 -----------------
helm install monitor nfvo/nfvo-monitor -n nfvo

```

==安装部署vnfm==

```yaml
#----------------- 1.安装base模块  -------------------
helm install base vnfm/base -n vnfm

#----------------- 2.安装mariadb ---------------------
#先执行 kubectl taint nodes --all node-role.kubernetes.io/master-
helm install mariadb vnfm/mariadb-galera -n vnfm

#----------------- 3.初始化数据库  -------------------
# 手动导入nfvomiddleware.sql文件 //	 忽略
helm install initdb vnfm/vnfm-initdb -n vnfm

#----------------- 4.安装redis  ----------------------
helm install redis vnfm/redis-cluster -n vnfm

#redis-cluster-job-vnfm-xkwww   0/1     Completed   0          8m35s
#vnfm-initdb-vnfm-job-kpdmc     0/1     Completed   0          9m21s
#任务pod，不用管

#----------------- 5.安装msb     ---------------------
helm install msb vnfm/msb -n vnfm

#----------------- 6.安装业务模块    -----------------
helm install core vnfm/core -n vnfm

#----------------- 7.安装日志模块    -----------------
# 先改 echo 'Asia/Shanghai' > /etc/timezone
helm install log vnfm/log_5 -n vnfm
#log-es-vnfm 报错：容器 "log-es" 的启动失败是由于尝试将主机路径 "/etc/timezone" 挂载到容器的根文件系统时出现了问题。错误指示指定的主机路径不是一个目录，并提到可能是尝试将一个目录挂载到文件上
kubectl edit deployments.apps -n vnfm log-es-vnfm
      initContainers:
      - command:
        - /bin/sh
        - -c
        - |
          sysctl -w vm.max_map_count=262144
          mkdir -p /logroot/elasticsearch/logs
          mkdir -p /logroot/elasticsearch/data
          chmod -R 777 /logroot/elasticsearch
          chmod -R 777 /usr/share/elasticsearch/data
          chown -R root:root /logroot
          echo 32768 > /proc/sys/net/core/somaxconn;
        image: 10.243.89.243:8080/onap/library/busybox:latest

/etc/timezone改成文件即可
#----------------- 8.安装pod监控模块 -----------------
helm install monitor vnfm/vnfm-monitor -n vnfm
```





修改镜像版本：手动改巴改巴

vim vnfm/core/values.yaml

```yaml
global:
  repository: 10.243.89.243:8080/onap
  #nfvoImageTag: v2-zhejiang-nfvo
  #vnfmImageTag: v2-zhejiang-vnfm
  nfvoImageTag: VNFVO1.1.3-20221102-ZHEJIANG
  vnfmImageTag: VVNFM1.1.3-20221102-ZHEJIANG
```





 kubectl edit deployments.apps -n vnfm

10.243.89.243:8080/onap/multicloud/framework:v2-zhejiang-nfvo

10.243.89.243:8080/onap/vnfm/catalog:v2-zhejiang-vnfm

10.243.89.243:8080/onap/nfvo/emanager-be:v2-zhejiang-nfvo

10.243.89.243:8080/onap/vnfm-emanager:v2-zhejiang-vnfm

10.243.89.243:8080/onap/nfvo/fcaps:v2-zhejiang-nfvo

10.243.89.243:8080/onap/multicloud/openstack-windriver:v2-zhejiang-nfvo

10.243.89.243:8080/onap/vnfm/lcm:v2-zhejiang-vnfm

10.243.89.243:8080/onap/vnfm/policy:v2-zhejiang-vnfm

10.243.89.243:8080/onap/nfvo/sysmgnt:v2-zhejiang-nfvo



VNFVO1.1.3-20221102-ZHEJIANG

VVNFM1.1.3-20221102-ZHEJIANG



问题：k8s双栈没开，Pod没有ipv6地址

```
fe80::/64

```

