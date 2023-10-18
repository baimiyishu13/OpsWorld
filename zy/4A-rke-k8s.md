



#### 环境

```
172.22.120.11
172.22.120.12
172.22.120.13
172.22.120.14
172.22.120.15
```

磁盘划分 lsblk 

```
fdisk /dev/sda
pvcreate /dev/sda3
sudo vgcreate docker_vg /dev/sda3
sudo lvcreate -n docker_data_lv -l 100%FREE docker_vg
sudo mkfs.xfs /dev/docker_vg/docker_data_lv
sudo mkdir -p /data/docker/data-root
sudo mount /dev/docker_vg/docker_data_lv /data/docker/data-root
echo "/dev/docker_vg/docker_data_lv  /data/docker/data-root  xfs  defaults  0  0" >> /etc/fstab
sudo mount -a
```

#### 准备

创建sudo用户，便于ansible

```
#!/bin/bash

# 设置要创建的用户名和密码
username="wlznhpt"
password="Wgzyc#@2017"

# 创建用户并设置密码
useradd -m "${username}"
echo "$username:${password}" | chpasswd

# 添加用户到wheel组
usermod -aG wheel "${username}"

# 配置sudoers
echo "${username} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# 重新加载sudoers文件以使更改生效
visudo -c -f /etc/sudoers && echo "sudoers file is valid" || echo "sudoers file is NOT valid"
```

#### 初始化

```
sed -i 's/mirrors.cmecloud.cn/172.22.20.25/g'  /etc/yum.repos.d/BCLinux.repo 
yum makecache
yum install -y ansible
```

初始化ansible

```
cat <<EOF > init_ansible.sh
#!/bin/bash
yum install -y ansible &>/dev/null
sed -i 's/^#host_key_checking = False/host_key_checking = False/' /etc/ansible/ansible.cfg
sed -i '/^\[defaults\]$/a interpreter_python = auto_legacy_silent' /etc/ansible/ansible.cfg
EOF
bash init_ansible.sh
```

生成 Ansible 的主机清单文件

```
cat <<EOF > /etc/ansible/hosts
[master]
master1 ansible_host=172.22.120.11
master2 ansible_host=172.22.120.12
master3 ansible_host=172.22.120.13

[master:vars]
ansible_become=true
ansible_become_method=sudo
ansible_become_pass=Wgzyc#@2017
ansible_ssh_user=swdys
ansible_ssh_pass=Wgzyc#@2017

[node]
node1 ansible_host=172.22.120.14
node2 ansible_host=172.22.120.15

[node:vars]
ansible_become=true
ansible_become_method=sudo
ansible_become_pass=Wgzyc#@2017
ansible_ssh_user=swdys
ansible_ssh_pass=Wgzyc#@2017
EOF
```

#### hosts

```
cat <<EOF >/etc/hosts
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
172.21.190.103 mirrors.com
172.22.120.11 master1
172.22.120.12 master2
172.22.120.13 master3
172.22.120.14 node1 
172.22.120.15 node2
EOF
```

设置主机的主机名

```
cat <<EOF > hostname.yaml
- name: Hostname
  hosts: all
  become: true
  gather_facts: false

  tasks:
    - name: Set hostname
      shell: hostnamectl set-hostname "{{ inventory_hostname }}"
EOF
```

hosts文件

```
ansible all -m copy -a "src=/etc/hosts dest=/etc/hosts backup=yes"
```

关闭swap、防火墙、selinux、修改limit

```
cat <<EOF > system.yml   
---
- name: System Settings
  hosts: all
  become: yes
  gather_facts: false
  tasks:
    - name: "Disable SELinux enforcing"
      command: /usr/sbin/setenforce 0  
      ignore_errors: true
  
    - name: Modify SELinux configuration file
      lineinfile:
        dest: /etc/selinux/config
        regexp: '^SELINUX='
        line: 'SELINUX=disabled'

    - name: Disable Swap
      shell: swapoff -a

    - name: Permanently Disable Swap
      lineinfile:
        dest: /etc/fstab
        state: absent
        regexp: '^.*\sswap\s.*$'

    - name: Stop and Disable Firewall
      service:
        name: firewalld
        state: stopped
        enabled: no
        
    - name: Modify limits
      lineinfile:
        path: /etc/security/limits.conf
        line: "{{ item }}"
      loop:
        - "*   hard   nofile  65535"
        - "*   soft   nofile  65535"
        - "*   soft   nproc   65535"
        - "*   hard   nproc   65535"
EOF
```

安装软件

```
ansible all -m shell -a 'sed -i 's/mirrors.cmecloud.cn/172.22.20.25/g'  /etc/yum.repos.d/BCLinux.repo'
ansible all -m shell -a 'yum makecache'
cat <<EOF > install_soft.yaml
- name: install
  hosts: all
  become: yes
  tasks:
    - name: Install required packages
      yum:
        name: "{{ item }}"
        state: present
      loop:
        - socat
        - conntrack
        - ebtables
        - ipset
        - ipvsadm
        - bash-completion
        - openssl
        - openssl-devel
        - vim
        - telnet
EOF
```

内核加载

```
cat <<EOF > load_kernel.yaml
- name: load_kernel
  hosts: all
  become: yes
  gather_facts: false
  tasks:  
    - name: "modprobe"
      modprobe:
       name: "{{ item }}"
       state: present
      with_items:
       - ip_vs
       - ip_vs_rr
       - ip_vs_wrr
       - ip_vs_sh
       - nf_conntrack 
    - name: "lsmod"  
      shell: /sbin/lsmod | grep {{ item }}
      with_items:
       - ip_vs
       - ip_vs_rr
       - ip_vs_wrr
       - ip_vs_sh
       - nf_conntrack
EOF
```

安装Docker

> 已有

```
cat <<EOF > /etc/docker/daemon.json
{ 
  "data-root": "/data/docker/data-root",
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "insecure-registries":["mirrors.com:80"],
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2",
  "storage-opts": [
    "overlay2.override_kernel_check=true"
  ]
}
EOF
ansible all -m copy -a "src=/etc/docker/daemon.json dest=/etc/docker/daemon.json"
ansible all -m shell -a 'systemctl restart docker'

```

内核

```
cat <<EOF > modify_kernel.yaml
- name: Modify Kernel Parameters
  hosts: all
  become: yes
  gather_facts: false
  tasks:
    - name: Set sysctl parameters
      lineinfile:
        path: /etc/sysctl.conf
        line: "{{ item }}"
        state: present
      loop:
        - "net.bridge.bridge-nf-call-ip6tables = 1"
        - "net.bridge.bridge-nf-call-iptables = 1"
        - "vm.swappiness=0"
        - "net.core.somaxconn=32768"
        - "net.ipv4.ip_forward=1"
        - "fs.inotify.max_user_watches = 2097152"
      become: true

    - name: Reload sysctl
      command: sysctl -p
      become: true
EOF
```

apps加入docker组 

```
sudo usermod -aG docker apps
```

修改sshd文件，打开

```
ansible all -m lineinfile -a "dest=/etc/ssh/sshd_config regexp='#PubkeyAuthentication yes' line='PubkeyAuthentication yes' state=present"
ansible all -m systemd -a "name=sshd state=restarted"
```

密钥

```
ansible all -m shell -a 'mkdir -m 700 -p /home/apps/.ssh'
ansible all -m shell -a 'chown apps:apps /home/apps/.ssh'
vim /home/apps/.ssh/authorized_keys
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDcuWtuL6lh1/WM5iyajg6Jrgh41nsAw1IANHZnP77OJ0A428uNnlGjBKAZ6cWDhM4V6DiHWVt7s5eL4jVGIhNHcBekRjm44l6Ybicsn5j28vTE4scIb7vGEJGs5fKnj9xr4j5mJQeiiRcGauKomxzUJxheRHWp7USHJfzxnwP8fmz3lsMICNVmUIc0nPyGNJ9TPWDrQGOxc2WmKx6oxVPC92Q5rU/EHxIg0euygB/E7u2Nqb3T71DLlprTT5xvdqpeXrCJGuWGK1FVyFCy2zVMwQbDp6nXBnpVRlIo9wodIq/RZwB1Y8OjCQvXNmJ5ht12Uh0ddQoQz0KPumQGdShn6NS91R+yDwguAF8BE7FLeCNakh628TAdhkGAdTm/5SW6aDGd31Ts87nNDEzfZKuQ2y+sdH8YmuGsbfq7ZkNG1PgRyDIzHMSicTvtOQa4kiq3+s5Ldi7ietvy6DaeXiSRMLMG1GpIkg54/0xXpKZbIQPyue4v8iOObqLzeLfSWg0= root@localhost.localdomain
ansible all -m copy -a "src=/home/apps/.ssh/authorized_keys dest=/home/apps/.ssh/authorized_keys owner=apps group=apps mode=0600"
```



```
  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config
```



#### RKE

修改配置

+ 注意版本

执行

```
 ./rke_linux-amd64  up --config cluster.yml  &
```





#### kubectl

```
mv kubectl-1-19-16 /usr/local/bin/kubectl

```

