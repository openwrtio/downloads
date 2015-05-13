#!/bin/bash
set -e

help="用法：$0 [-u qiniu_user] [-p qiniu_passwd]

参数：
  -h              : 帮助
  -u qiniu_user   : 七牛用户名
  -p qiniu_passwd : 七牛密码

例子：
  $0 -u jim -p 123456
"
u=""
p=""
while getopts u:p:h opt
do
    case $opt in
    'u'|'p' )
        eval $opt=$OPTARG
        ;;
    *)
        echo "$help"
        exit 1
        ;;
    esac
done

if [ -z $u ]; then
    echo "$help"
    exit 1
fi

if [ -z $p ]; then
    echo "请输入密码："
    read -s p
    if [ -z $p ]; then
        echo '错误：未输入'
        exit 1
    fi
fi

# 生成index.html
top_path=$(cd `dirname $0`; pwd)

$top_path/qiniu/qrsctl login $u $p

echo $top_path
dirs=`ls -R $top_path | grep ':'`
for dir in $dirs; do
    cd ${dir%?}
    if [ ! -f index.md ]; then
        continue
    fi
    # sudo apt-get install discount
    markdown index.md > index.html.part.tmp

    # sed不支持多行文本，所以要先把换行符去掉
    tmp=`cat index.html.part.tmp | tr '\n' '\f'`
    body=`echo $tmp | sed -e "s|<table>|<table class=\"pure-table pure-table-striped pure-table-horizontal\">|g"`
    rm *.tmp
    path=`pwd | sed -e "s|$top_path||"`
    sed -e "s|{title}|Index of $path/|g" -e "s|{body}|$body|g" $top_path/tpl.html | tr '\f' '\n' > index.html
    # 首页有标题，不需要这个标题
    sed -i '/<h1>Index of \/<\/h1>/d' index.html
    qiniu_prefix=${path:1}"/"
    if [ $qiniu_prefix = "/" ]; then
        qiniu_prefix=""
    fi
    echo $qiniu_prefix
    # 把index.html上传到 七牛的xxx/，用于列表服务
    $top_path/qiniu/qrsctl put downloads-openwrt-io "$qiniu_prefix" index.html
    $top_path/qiniu/qrsctl cdn/refresh downloads-openwrt-io http://downloads.openwrt.io/$qiniu_prefix
done
