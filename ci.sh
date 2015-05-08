#!/bin/bash

cd ./dl/
# sudo apt-get install discount
markdown origin.md > index.html.part
body=`cat index.html.part | tr '\n' '\f'`
echo $body
sed -e "s|{body}|$body|g" ../tpl.html | tr '\f' '\n' > index.html
