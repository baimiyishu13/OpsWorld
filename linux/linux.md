## 📒Doc

### 命令

bash：命令处理器（bash 解释器）



#### crontab

Crontab 命令

+ `crontab -e` : 创建或编辑定时任务表
+ `crontab -l` : 列出任务表

 Cron 计划或 Cron 表达式

```
* * * * * command_to_execute
# 分 时 日 月 周
```

有一些特殊字符，如 *、/、- 和 ,，用于定义更复杂的定时任务

1. `*`：通配符，表示匹配任何值。例如，`* * * * *` 表示每分钟都运行一次任务。
2. `/`：用于定义间隔。例如，`*/15 * * * *` 表示每隔 15 分钟运行一次任务。
3. `-`：用于定义范围。例如，`0 9-17 * * *` 表示在每天的 9 点到 17 点之间每小时运行一次任务。
4. `,`：用于列出多个值。例如，`30 8,12,16 * * *` 表示在每天的早上 8 点、12 点和下午 4 点 30 分运行任务。

 Cron 表达式示例 在 Linux 中创建作业示例



---

grep：文本过滤工具

sed：文本编辑工具

awk：报告生成工具 （格式化文本）

#### find

查找命令语法 

`find` 是一个强大的命令行工具，用于在文件系统中搜索文件和目录。以下是 `find` 命令的一般语法：

```
find 起始目录 选项 表达式

find /name -name <file_name>
```

- `起始目录`：指定搜索的起始目录。可以是相对路径或绝对路径。
- `选项`：可选，用于设置 `find` 命令的不同选项。
- `表达式`：用于定义搜索条件和操作的表达式。

以下是一些常用的 `find` 命令选项和表达式：

**选项：**

- `-name`：按文件或目录的名称进行匹配。例如，`-name "*.txt"` 会匹配所有以 `.txt` 扩展名结尾的文件。
- `-iname` ：忽略文件名大小写
- `-type`：按文件类型进行匹配。可以是 `f`（普通文件）、`d`（目录）、`l`（符号链接）等。
- `-mtime`：按文件的修改时间进行匹配。例如，`-mtime -7` 匹配最近7天内修改过的文件。
- `-size`：按文件的大小进行匹配。例如，`-size +1M` 匹配大于1MB的文件。
- `-user`: 给定用户的文件
- `-inum`根据inode号查找文件
- ` -newer`: 匹配那些创建时间（或修改时间）比 `last.txt` 文件新的文件
-  `-newerct` 比较文件的创建时间（ctime）而不是修改时间
-  `-mindepth` 和 `-maxdepth` : 查找的层级深度

**表达式：**

- `-exec`：执行指定的命令来处理匹配的文件。例如，`-exec rm {} \;` 删除匹配的文件。
- `-print`：默认动作，将匹配的文件名打印到标准输出。
- `-and`、`-or`、`-not`：用于组合多个搜索条件。例如，`-name "*.txt" -and -mtime -7` 匹配最近7天内修改过的以 `.txt` 结尾的文件。

案例1：如何根据文件大小搜索文件？

```sh
➜  kube-prometheus-release-0.8 find manifests -size +40k
manifests/grafana-dashboardDefinitions.yaml
```

+ M for MB
+ K for KB
+ G for GB

案例2：如何仅查找给定路径中的文件或目录？

type:

+ f : file
+ d: dir
+ l : 链接
+ b：块设备

```sh
➜  kube-prometheus-release-0.8 find ./manifests -type d
./manifests
./manifests/setup

➜  kube-prometheus-release-0.8 find ./manifests -type f
./manifests/prometheus-adapter-deployment.yaml
./manifests/prometheus-clusterRole.yaml
```

案例3：如何根据文件名搜索文件？

```sh
➜  kube-prometheus-release-0.8 find . -name grafana-deployment.yaml
./manifests/grafana-deployment.yaml
```

案例4：如何在搜索时忽略文件名的大小写？

```sh
➜  kube-prometheus-release-0.8 find . -iname kubernetes-servicemonitorapiserver.yaml
./manifests/kubernetes-serviceMonitorApiserver.yaml
```



案例5：如何仅搜索给定用户的文件？

```sh
➜  kube-prometheus-release-0.8 find . -user lelema
.
./experimental
```

案例6；如何根据inode号查找文件？

```sh
➜  kube-prometheus-release-0.8 ll -i | tail -1
21013135 drwxr-xr-x   3 lelema  staff    96B  3 21  2022 tests
➜  kube-prometheus-release-0.8 find . -inum 21071059
./1.txt
```

案例7：如何根据编号搜索文件。链接？ 

```sh
➜  kube-prometheus-release-0.8 find . -links 3
./experimental
./tests
```

案例8: 如何根据权限搜索文件？ 

```sh
➜  kube-prometheus-release-0.8 find . -perm 0777
./test.sh
```

案例9：有执行权限的文件

```sh
➜  kube-prometheus-release-0.8 find . -type f -perm +100
./build.sh
./scripts/monitor
```

+ `+100` 有执行权限
+ `-100`: 无执行权限

案例10：如何查找所有以字母sh结尾的的文件？

```sh
➜  kube-prometheus-release-0.8 find . -type f -name "*.sh"
./build.sh
./scripts/monitoring-deploy.sh
./scripts/minikube-start.sh
./scripts/minikube-start-kvm.sh
./scripts/generate-schemas.sh
./scripts/generate-versions.sh
./test.sh
```



案例11: 如何搜索last.txt文件之后创建的所有文件？ 

```sh
➜  kube-prometheus-release-0.8 find . -type f -newer test.sh
./1.txt
```



案例12: 如何查找给定目录下的所有空文件？ 

```sh
➜  kube-prometheus-release-0.8 find . -type f -size 0
./hack/jsonnet-docker-image
./examples/etcd-client.crt
./examples/etcd-client.key
./examples/etcd-client-ca.crt
./null.txt

# 深度为1
➜  kube-prometheus-release-0.8 find . -maxdepth 1 -size 0
./null.txt
```



案例13：仅查找深度2的空文件

```sh
➜  kube-prometheus-release-0.8 find . -mindepth 2 -maxdepth 2 -type f -size 0

./hack/jsonnet-docker-image
./examples/etcd-client.crt
./examples/etcd-client.key
./examples/etcd-client-ca.crt
```



案例14: 查找深度为2，最近5天修改的文件

```sh
➜  kube-prometheus-release-0.8 find . -type f -maxdepth 2 -mindepth 2 -mtime -5
./manifests/test.sh
```



案例15：如何查找所有空文件并将其删除？

```sh
➜  kube-prometheus-release-0.8 find . -maxdepth 1 -size 0 -exec rm {} \;
```



案例16: 如何搜索所有大小在1-50MB之间的文件？

```sh
➜  kube-prometheus-release-0.8 find . -type f -size +1M -size -50M
./manifests/grafana-dashboardDefinitions.yaml
```



案例17: 如何在 Linux 中搜索 15 天前的文件？

```sh
➜  kube-prometheus-release-0.8 find . -type f -mtime +15
```





#### grep

参数：

+ `-i`：忽略大小写
+ `-r` : 递归
+ `-R` 递归搜索目录下的文件，并跟随符号链接
+ `-h`: 不显示文件名
+ `-E`: 扩展正则表达式
+ `-v`:取反
+ `-w` : 精确匹配搜索，只匹配整个单词而不是匹配部分单词
+ `-c` : 统计次数
+ `-n` : 显示行号
+ `-e` : 指定多个关键字
+ `-l`：用于仅输出包含匹配关键字的文件名
+ `-F` 选项：它表示 `grep` 应该以固定字符串
+ `-f 1.txt` 选项：它指定了一个文件
+ `-A -B -C `: 后、前、前后几行
+ `-q` ：不显示输出，返回状态码
+ `-s`: 忽略错误

常用正则：

+ `\s` : 空格
+ `+` 一个或多个
+ `^\s*`:  0到多个空格开始
+ `($|#)` ：空行或#

案例 1：在 Linux 中使用 grep 命令搜索时忽略大小写 

```sh
➜  kube-prometheus-release-0.8 grep -rihE "image:\s+" manifests/

        image: directxman12/k8s-prometheus-adapter:v0.8.4
        image: grafana/grafana:7.5.4
        image: k8s.gcr.io/kube-state-metrics/kube-state-metrics:v2.0.0
```

+ `-i`：忽略大小写
+ `-r` : 递归
+ `-h`: 不显示文件名
+ `-E`: 扩展正则表达式
+ `\s` : 空格
+ `+` 一个或多个

去除前面的空格

```sh
➜  kube-prometheus-release-0.8 grep -rihE "image:\s+" manifests/ | awk -F ' '  '{print$1,$2}'

image: directxman12/k8s-prometheus-adapter:v0.8.4
image: grafana/grafana:7.5.4
image: k8s.gcr.io/kube-state-metrics/kube-state-metrics:v2.0.0
image: quay.io/brancz/kube-rbac-proxy:v0.8.0
image: quay.io/brancz/kube-rbac-proxy:v0.8.0
```



案例 2：在 Linux 中使用 grep 命令搜索除给定模式/关键字之外的所有内容

```sh
➜  kube-prometheus-release-0.8 grep -vE '^\s*($|#)' build.sh

set -e
set -x
set -o pipefail
PATH="$(pwd)/tmp/bin:${PATH}"
rm -rf manifests
mkdir -p manifests/setup
jsonnet -J vendor -m manifests "${1-example.jsonnet}" | xargs -I{} sh -c 'cat {} | gojsontoyaml > {}.yaml' -- {}
find manifests -type f ! -name '*.yaml' -delete
rm -f kustomization
```

+ `-v`:取反
+ `^\s*`:  0到多个空格开始
+ `($|#)` ：空行或#



案例 3：打印多少个在 Linux 中使用 grep 命令在文件中出现给定关键字的次数（计数） 

```sh
➜  kube-prometheus-release-0.8 grep -cw 'echo' test.sh
12
```

+ `-w` : 精确匹配搜索，只匹配整个单词而不是匹配部分单词
+ `-c` : 统计次数

案例 4：在 Linux 中使用 grep 命令搜索文件中给定关键字的精确匹配 

```
-w
```

案例 5：打印行号。在 Linux 中使用 grep 命令在文件中给定关键字的匹配项 

```sh
➜  kube-prometheus-release-0.8 grep -rhEn '^\s*image:\s+' manifests/
38:        image: directxman12/k8s-prometheus-adapter:v0.8.4
30:        image: grafana/grafana:7.5.4
```

+ `-n` : 显示行号

案例 6：在 Linux 中使用 grep 命令在多个文件中搜索给定关键字 

```sh
 ➜  kube-prometheus-release-0.8 grep  "rm" build.sh test.sh
build.sh:rm -rf manifests
build.sh:rm -f kustomization
test.sh:    rm -rf "test.jsonnet"
```

案例 7：在 Linux 中使用 grep 命令在多个文件中搜索给定关键字时抑制文件名 

```sh
➜  kube-prometheus-release-0.8 grep -h "rm" build.sh test.sh
rm -rf manifests
rm -f kustomization
    rm -rf "test.jsonnet"
```

案例 8：在 Linux 中使用 grep 命令在一个文件中搜索多个 关键字

```sh
➜  kube-prometheus-release-0.8 grep -e "echo" -e "rm" build.sh test.sh
build.sh:rm -rf manifests
build.sh:rm -f kustomization
test.sh:    echo "Testing: ${i}"
test.sh:    echo ""
```

+ `-e` : 指定多个关键字

案例 8：在多个文件中使用 grep 搜索多个关键字Linux 中的命令

```sh
➜  kube-prometheus-release-0.8 grep -e "echo" -e "rm" build.sh test.sh
```

案例 9：在 Linux 中使用 grep 命令仅打印与给定关键字匹配的文件名 

```sh
➜  kube-prometheus-release-0.8 grep -rl 'replicas' manifests/*
manifests/alertmanager-alertmanager.yaml
manifests/blackbox-exporter-deployment.yaml
manifests/grafana-dashboardDefinitions.yaml
manifests/grafana-deployment.yaml
```

+ `-l`：用于仅输出包含匹配关键字的文件名

案例 10：在 Linux 中使用 grep 命令从文件中获取关键字/模式并与另一个文件匹配

```sh
➜  kube-prometheus-release-0.8 cat 1.txt
rm
if
for
else
➜  kube-prometheus-release-0.8 grep -Ff 1.txt test.sh
# only exit with zero if all commands of the pipeline exit successfully
for i in examples/jsonnet-snippets/*.jsonnet; do
    rm -rf "test.jsonnet"
for i in examples/*.jsonnet; do
```

+ `-F` 选项：它表示 `grep` 应该以固定字符串
+ `-f 1.txt` 选项：它指定了一个文件

案例 11：在 Linux 中使用 grep 命令打印以给定关键字开头的匹配行

```sh
➜  kube-prometheus-release-0.8 grep "^rm" build.sh
rm -rf manifests
rm -f kustomization
```

+ `^`：以什么开始

案例 12：在 Linux 中使用 grep 命令打印以给定关键字结尾的匹配行

```sh
➜  kube-prometheus-release-0.8 grep "dir$" build.sh
# Make sure to start with a clean 'manifests' dir
```

+ `$`：以什么结尾

Case13: 假设一个目录（dirA）中有 100 个文件，我们需要在 Linux 中使用 grep 命令在所有文件中搜索某个关键字 

```sh
➜  kube-prometheus-release-0.8 grep -h 'image:' ./manifests/* | awk -F " " '{print $1,$2}'
grep: ./manifests/setup: Is a directory
image: quay.io/prometheus/alertmanager:v0.21.0
image: quay.io/prometheus/blackbox-exporter:v0.18.0
image: jimmidyson/configmap-reload:v0.5.0
```

Case14: 使用egrep 命令使用 grep 命令进行多个关键字搜索在 Linux 中

```sh
➜  kube-prometheus-release-0.8 egrep 'rm|echo|if' test.sh
# only exit with zero if all commands of the pipeline exit successfully
    echo "Testing: ${i}"
    echo ""
    echo "${snippet}" > "test.jsonnet"
    rm -rf "test.jsonnet"
```





#### sed

Linux SED（流编辑器）

语法：

```sh
sed [选项] '脚本' 输入文件
```

`选项` 是一些用于修改 `sed` 行为的可选参数。一些常见的选项包括：

- `-e`：允许在命令行中指定 `sed` 脚本。
- `-f`：从文件中读取 `sed` 脚本。
- `-i`：直接修改输入文件，而不是将结果输出到标准输出。
- `-n`：禁用默认的输出，只显示经过脚本处理的内容。

`编辑命令` 是要执行的操作，例如替换、删除、插入等。编辑命令通常以字母表示，例如：

- `s`：替换。
- `d`：删除。
- `p`：打印。
- `i`：插入。

案例一：如何仅显示给定的行或行范围？

+ -n: 只显示经过脚本处理的内容
+ -p : 打印

```sh
➜  kube-prometheus-release-0.8 sed -n '1,5p' test.sh
#!/usr/bin/env bash
set -e
# only exit with zero if all commands of the pipeline exit successfully
set -o pipefail

➜  kube-prometheus-release-0.8 sed -n '$p' test.sh
done
```

案例2：查看脚本中的 ‘rm’

```sh
➜  kube-prometheus-release-0.8 sed -n '/rm/p' test.sh
    rm -rf "test.jsonnet"
```

案例3: 如何在 sed 命令中使用多个表达式？

-e : 多个选项

```sh
➜  kube-prometheus-release-0.8 sed -n -e '2p' -e '5p' test.sh
set -e
➜  kube-prometheus-release-0.8 sed -n -e '/done/p' -e '/for/p' test.sh
for i in examples/jsonnet-snippets/*.jsonnet; do
done
for i in examples/*.jsonnet; do
done
```

案例5： 如何查看第 2 行接下来的 4 行？

```sh
sed -n ‘2,+4p’ file_name
```

案例6: 如何替换文件中的单词并显示？

```sh
sed -i '' 's/7.5.4/7.5.5/g' grafana-deployment.yaml
```

案例7: 修改是备份文件

```sh
sed -i '.bak' 's/7.5.5/7.5.9/g' grafana-deployment.yaml
```

案例8: 修改指定的行 和 不在指定的行

```sh
sed '5 s/<string_to_change>/<new_string>/g' file_name
sed '5! s/<string_to_change>/<new_string>/g' file_name
```

案例9：删除

```sh
sed -i '' '/image/d' grafana-deployment.yaml
```

==案例10==: 删除空行和注释行 ( 加 -i 实际删除)

```sh
sed '/^$/d' test.sh
```

案例11：如何将制表符替换为空格？

```
sed 's/\t/ /g' test.sh
```

==案例12==:  如何将 sed 命令的输出复制到单独的文件中？

```sh
kube-prometheus-release-0.8 sed -n '/echo/ w a.txt' test.sh
```

案例13: 在给定行号后添加

```sh
➜  kube-prometheus-release-0.8 sed '2s/^/#test\n/' test.sh
```

案例14：在给定行号后添加 追加一个文件的内容 w





#### awk

**`awk` 命令的基本结构：**

```
bashCopy code
awk 'pattern { action }' input-file
```

- `pattern`：一个条件或模式，用于匹配输入行。
- `action`：在满足 `pattern` 条件的情况下执行的操作。
- `input-file`：要处理的输入文件。

1. **字段分隔符 `-F`：**

   通过 `-F` 选项可以指定字段分隔符，默认是空格。例如：

   ```
   bashCopy code
   awk -F: '{ print $1, $3 }' /etc/passwd
   ```

2. **`$0` 和 `$n`：**

   - `$0` 代表整个当前行。
   - `$n` 代表当前行的第 n 个字段，字段以字段分隔符分隔。
   - `$NF` 最后一个

3. **`NF` 和 `NR`：**

   - `NF` 代表当前行的字段数量。
   - `NR` 代表当前处理的行号。

**`BEGIN` 和 `END` 块：**

- `BEGIN` 块中的命令在处理前执行一次。
- `END` 块中的命令在处理结束时执行一次。

**条件语句：**

可以使用 `if`、`else` 和 `else if` 等条件语句来控制执行流程。

**循环：**

`awk` 不支持传统的 `for` 和 `while` 循环，但你可以使用 `while` 块来模拟循环。



案例1 ：NR用法（条件 第几行）

+ `==` 和 `!=` `>` 等

```sh
 awk -F. 'NR == 2 {print $2}' 1.txt
```

案例2 ： 条件语句用法

```sh
➜  kube-prometheus-release-0.8 awk '{ if ($2!=0) {print "oooo"} else {print $NF} }' 1.txt

oooo
ESTABLISHED
ESTABLISHED
```

案例3:  awk查找打印

```
➜  kube-prometheus-release-0.8 awk '/SYN_SENT/ {print $0}' 1.txt
tcp4       0      0  leledeair.lan.64313    tsa01s13-in-f10..https SYN_SENT
tcp4       0      0  leledeair.lan.64312    tsa01s13-in-f10..https SYN_SENT
tcp4       0      0  leledeair.lan.64231    tsa03s08-in-f10..https SYN_SENT
tcp4       0      0  leledeair.lan.64230    tsa03s08-in-f10..https SYN_SENT
```

案例4：查找打印存在SYN_SENT 的行

```
➜  kube-prometheus-release-0.8 awk '/SYN_SENT/ {print $0}' 1.txt
tcp4       0      0  leledeair.lan.64313    tsa01s13-in-f10..https SYN_SENT
tcp4       0      0  leledeair.lan.64312    tsa01s13-in-f10..https SYN_SENT
tcp4       0      0  leledeair.lan.64231    tsa03s08-in-f10..https SYN_SENT
tcp4       0      0  leledeair.lan.64230    tsa03s08-in-f10..https SYN_SENT
```



---

### linux 排障

### 正则表达式

1. **基本正则表达式（BRE）**：基本正则表达式是最常见的正则表达式语法，用于工具如`grep`、`sed`等。它包括以下常见的元字符：
   - `.`：匹配任意单个字符。
   - `*`：匹配前一个字符的零个或多个副本。
   - `^`：匹配行的开头。
   - `$`：匹配行的结尾。
   - `[]`：字符类，匹配方括号内的任何字符。
   - `[^]`：否定字符类，匹配不在方括号内的任何字符。
   - `\`：转义字符。
2. **扩展正则表达式（ERE）**：扩展正则表达式是基本正则表达式的扩展，用于工具如`egrep`。它包括更多元字符，如：
   - `+`：匹配前一个字符的一个或多个副本。
   - `?`：匹配前一个字符的零个或一个副本。
   - `()`：分组，用于匹配和捕获子模式。
   - `|`：逻辑或，用于匹配多个模式中的一个。