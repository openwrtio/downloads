#!/bin/bash
set -ev
top_dir=$(cd `dirname $0`; pwd)
echo $top_dir

function download()
{
    set -x
    files=`find $1 -name 'origin.md'`
    for file in $files; do
        absolute_dir=`dirname $file`
        echo $absolute_dir
        relative_dir=`echo $file | sed -e "s|$top_dir||" | xargs dirname`
        echo $relative_dir
        
        #如果需要检查md5
        is_check_md5=0
        tmp=`head -n 1 $file | grep md5sum 2>&1`
        if [ "x"$tmp != "x" ]; then
            is_check_md5=1
        fi

        thead_line_num=`grep -n "\-|\-" $file | awk -F: '{print $1}'`
        head -n $thead_line_num $file > $absolute_dir/index.md
        # 加入上级目录链接
        sed -i '/-|-/a[../](../)| | ' $absolute_dir/index.md
        offset=$(($thead_line_num+1))
        tail -n +$offset $file | while read line
        do
            i=0
            new_line=""
            http_code=200
            for part in `echo $line | sed 's/|/ /g'`
            do
                echo $i
                echo $part
                #第一列必须是下载地址
                if [ $i -eq 0 ]; then
                    uri=$part
                    origin_filename=`basename $uri`
                elif [ $i -eq 1 ]; then
                    #第2列必须是文件名，如果为空的话，将使用下载地址里相同的文件名
                    if [ $part = '' ]; then
                        filename=$origin_filename
                    else
                        filename=$part
                    fi
                    http_code=`curl -sI "http://downloads.openwrt.io$relative_dir/$filename" | head -n 1 | awk '{print $2}'`
                    # 把文件名都改成链接
                    new_line='['$filename']('$filename')'
                elif [ $i -eq 2 ]; then
                    #第3列可能是md5sum或者size
                    if [ $http_code -ne 200 ]; then
                        if [ ! -f $top_dir$relative_dir/$filename ]; then
                            wget -O $top_dir$relative_dir/$filename $uri
                        fi
                        if [ $is_check_md5 -eq 1 ]; then
                            expected_md5=$part
                            md5=`md5sum $top_dir$relative_dir/$filename | awk '{print $1}'`
                            if [ $expected_md5 != $md5 ]; then
                                echo "error: md5 not match"
                                exit 1
                            fi
                        fi
                    fi
                    new_line=$new_line'|'$part
                    echo $new_line >> $top_dir$relative_dir/index.md
                fi
                i=$(($i+1))
            done
        done
        #空格是为了可读性，机器不需要，所以把空格删除
        sed -i 's/ | /|/g' $top_dir$relative_dir/index.md > $top_dir$relative_dir/index.md-nospace
    done
    return 0
    exit
}
tmp=$(download $top_dir)
echo "$tmp"
exit
