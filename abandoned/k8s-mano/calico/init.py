import fileinput
import sys

# 定义要替换的映像和相应的替换值
image_mappings = {
    'calico/cni:v3.15.2': '10.243.89.243:8080/so/calico/cni:v3.15.2',
    'calico/pod2daemon-flexvol:v3.15.2': '10.243.89.243:8080/so/calico/pod2daemon-flexvol:v3.15.2',
    'calico/node:v3.15.2': '10.243.89.243:8080/so/calico/node:v3.15.2',
    'calico/kube-controllers:v3.15.2': '10.243.89.243:8080/so/calico/kube-controllers:v3.15.2'
}

# 指定要替换的文件路径
file_path = 'calico.yaml'

# 遍历文件，并逐行替换指定的映像
for line in fileinput.input(file_path, inplace=True):
    for key, value in image_mappings.items():
        if key in line:
            line = line.replace(key, value)
    sys.stdout.write(line)
