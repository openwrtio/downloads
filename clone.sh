#!/bin/bash
set -e

top_path=$(cd `dirname $0`; pwd)

echo $top_path
function clone()
{
    set -x
    dirs=`ls -R $1 | grep ':' | awk -F: '{print $1}'`
    for dir in $dirs; do
        cd $dir
        echo $dir
        if [ ! -f origin.clone ]; then
            continue
        fi

        uri=`cat origin.clone`
        if [ ! -f index.html-origin ]; then
            wget -O index.html-origin $uri
        else
            # 如果上次下载失败，则需要重新下载
            tmp=`grep '</html>' index.html-origin 2>&1`
            if [ "x"$tmp = "x" ]; then
                wget -O index.html-origin $uri
            fi
        fi
        sed -i 's/\r//g' index.html-origin
        dirs_and_files=`grep '<a href="' index.html-origin | awk -F\" '{print $2}'`
        echo "$dirs_and_files"
        echo 'uri | filename | size' > origin.md
        echo '----|----------|-----' >> origin.md
        for target in $dirs_and_files; do
            if [ $target = "../" ]; then
                continue
            fi
            if [ ${target: -1} = '/' ]; then
                mkdir -p $target
                echo $uri$target > $target/origin.clone
                $(clone $dir/$target)
            else
                echo $target
                file_uri_md=`echo $uri$target | sed -e 's|_|\\\_|g'`
                echo $file_uri_md
                size=`grep '<a href="'$target index.html-origin | awk '{print $5}'`
                echo $file_uri_md' | '`basename $file_uri_md`' | '$size >> origin.md
            fi
        done
    done
    return 0;
}
tmp=$(clone $top_path)
echo "$tmp"
exit
    # sudo apt-get install discount
    markdown index.md > index.html.part.tmp

    # sed不支持多行文本，所以要先把换行符去掉
    tmp=`cat index.html.part.tmp | tr '\n' '\f'`
    body=`echo $tmp | sed -e "s|<table>|<table class=\"pure-table pure-table-striped pure-table-horizontal\">|g"`
    rm *.tmp
    path=`pwd | sed -e "s|$top_path||"`
    sed -e "s|{title}|Index of $path/|g" -e "s|{body}|$body|g" $top_path/tpl.html | tr '\f' '\n' > index.html
    if [ $dir = $top_path':' ]; then
        # 首页有标题，不需要这个标题
        sed -i '/<h1>Index of \/<\/h1>/d' index.html
        title=`grep '<h1>' index.html | sed -e 's|h1|title|g'`
        sed -i "s|<title>Index of /</title>|$title|g" index.html
    fi
    qiniu_prefix=${path:1}"/"
    if [ $qiniu_prefix = "/" ]; then
        qiniu_prefix=""
    fi
    echo $qiniu_prefix
    # 把index.html上传到 七牛的xxx/，用于列表服务
    $top_path/qiniu/qrsctl put downloads-openwrt-io "$qiniu_prefix" index.html
    $top_path/qiniu/qrsctl cdn/refresh downloads-openwrt-io http://downloads.openwrt.io/$qiniu_prefix
