#!/bin/bash

# 指定原始内容和替换内容
original_image="calico/cni:v3.15.2"
replacement_image="10.243.89.243:8080/so/calico/cni:v3.15.2"

# 替换calico.yaml文件中的内容
sed -i "s|image: ${original_image}|image: ${replacement_image}|g" calico.yaml

original_image="calico/pod2daemon-flexvol:v3.15.2"
replacement_image="10.243.89.243:8080/so/calico/pod2daemon-flexvol:v3.15.2"

sed -i "s|image: ${original_image}|image: ${replacement_image}|g" calico.yaml

original_image="calico/node:v3.15.2"
replacement_image="10.243.89.243:8080/so/calico/node:v3.15.2"

sed -i "s|image: ${original_image}|image: ${replacement_image}|g" calico.yaml

original_image="calico/kube-controllers:v3.15.2"
replacement_image="10.243.89.243:8080/so/calico/kube-controllers:v3.15.2"

sed -i "s|image: ${original_image}|image: ${replacement_image}|g" calico.yaml

echo "替换完成"