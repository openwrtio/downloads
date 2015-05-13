#!/bin/bash
set -ev
top_path=$(cd `dirname $0`; pwd)
echo $top_path

cd ./dl/
thead_line_num=`grep -n "\-|\-" origin.md | awk -F: '{print $1}'`
head -n $thead_line_num origin.md > index.md
sed -i "s|uri|offical site|g" index.md

# 加入上级目录链接
sed -i '/-|-/a[../](../)| | ' index.md
# 把文件名都改成链接
offset=$(($thead_line_num+1))
tail -n +$offset origin.md | while read line
do
    i=0
    new_line=""
    http_code=200
    for part in `echo $line | sed 's/ | / /g'`
    do
        echo $i
        echo $part
        if [ $i -eq 0 ]; then
            filename=$part
            http_code=`curl -sI "http://downloads.openwrt.io/dl/$part" | head -n 1 | awk '{print $2}'`
            new_line=$new_line'['$part']('$part')'
        elif [ $i -eq 1 ]; then
            expected_md5=$part
            new_line=$new_line' | '$part
        elif [ $i -eq 2 ]; then
            if [ $http_code -ne 200 ]; then
                wget -O $filename $part
                md5=`md5sum $filename | awk '{print $1}'`
                if [ $expected_md5 != $md5 ]; then
                    echo "error: md5 not match"
                    exit 1
                fi
            fi
            new_line=$new_line' | ['`echo $part | awk -F/ '{print $3}'`']('$part')'
            echo $new_line >> index.md
        fi
        i=$(($i+1))
    done
done
