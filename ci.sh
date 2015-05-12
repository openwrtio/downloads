#!/bin/bash
top_path=$(cd `dirname $0`; pwd)
echo $top_path

cd ./dl/
thead_line_num=`grep -n "\-|\-" origin.md | awk -F: '{print $1}'`
head -n $thead_line_num origin.md > index.md
sed -i "s|uri|offical site|g" index.md

# 把文件名都改成链接
offset=$(($thead_line_num+1))
tail -n +$offset origin.md | while read line
do
    i=0
    new_line=""
    for part in `echo $line | sed 's/ | / /g'`
    do
        echo $i
        echo $part
        if [ $i -eq 0 ]; then
            new_line=$new_line'['$part']('$part')'
        elif [ $i -eq 1 ]; then
            new_line=$new_line' | '$part
        elif [ $i -eq 2 ]; then
            new_line=$new_line' | ['`echo $part | awk -F/ '{print $3}'`']('$part')'
            echo $new_line >> index.md
        fi
        i=$(($i+1))
    done
done

# 加入上级目录链接
sed -i '/-|-/a[../](../) |  | ' index.md
# sudo apt-get install discount
markdown index.md > index.html.part

# sed不支持多行文本，所以要先把换行符去掉
tmp=`cat index.html.part | tr '\n' '\f'`
body=`echo $tmp | sed -e "s|<table>|<table class=\"pure-table pure-table-striped pure-table-horizontal\">|g"`

path=`pwd | sed -e "s|$top_path||"`
sed -e "s|{title}|Index of $path|g" -e "s|{body}|$body|g" ../tpl.html | tr '\f' '\n' > index.html
