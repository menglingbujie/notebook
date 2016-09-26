
#解析fsck文件
#!/bin/bash
git fsck > fsck.out
mkdir reback

files=`awk '{print $3}' ./fsck.out | xargs`;
for file in $files
do
  git show $file > ./reback/file_$file
done
