#!/bin/bash
set -e
top_dir=$(cd `dirname $0`; pwd)
echo $top_dir

function download()
{
    files=`find $1 -name 'origin.md'`
    for file in $files; do
        absolute_dir=`dirname $file`
        echo $absolute_dir
        relative_dir=`echo $file | sed -e "s|$top_dir||" | xargs dirname`
        echo $relative_dir
        
        #如果需要检查md5
        is_check_md5=0
        tmp=`head -n 1 $file | grep md5sum 2>&1`
        if [ "x""$tmp" != "x" ]; then
            is_check_md5=1
        fi

        thead_line_num=`grep -n "\-|\-" $file | awk -F: '{print $1}'`
        echo 'filename|md5sum' > $absolute_dir/files.md
        echo '--------|------' >> $absolute_dir/files.md
        offset=$(($thead_line_num+1))
        tail -n +$offset $file | while read line; do
            i=0
            new_line=""
            http_code=200
            md5_or_size=""
            for part in `echo $line | sed 's/|/ /g'`; do
                echo $part
                #第一列必须是下载地址
                if [ $i -eq 0 ]; then
                    uri=$part
                    origin_filename=`basename $uri`
                    filename=$origin_filename
                elif [ $i -eq 1 ]; then
                    #第2列必须是文件名，如果为空的话，将使用下载地址里相同的文件名
                    filename=$part
                elif [ $i -eq 2 ]; then
                    #第3列可能是md5sum或者size
                    #如果第2列为空，则第3列必须为空，否则第3变成了第2，会错乱
                    md5_or_size=$part
                fi
                i=$(($i+1))
            done
            http_code=`curl -sI "http://downloads.openwrt.io$relative_dir/$filename" | head -n 1 | awk '{print $2}'`
            if [ $http_code -ne 200 ]; then
                if [ ! -f $top_dir$relative_dir/$filename ]; then
                    wget -O $top_dir$relative_dir/$filename $uri
                fi
                if [ $is_check_md5 -eq 1 ] && [ $md5_or_size != "" ]; then
                    md5=`md5sum $top_dir$relative_dir/$filename | awk '{print $1}'`
                    if [ $md5_or_size != $md5 ]; then
                        echo "error: md5 not match"
                        exit 1
                    fi
                fi
            fi
            echo $filename'|'$md5_or_size >> $top_dir$relative_dir/files.md
        done
    done
    return 0
}
tmp=$(download $top_dir)
echo "$tmp"
exit
