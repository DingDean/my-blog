#!/bin/sh

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
NOTEBOOKS=$DIR/JupyterNotebooks
DEST=$DIR/content/post/tech
TOML=$DIR/toml_master

echo "---转换Jupyter为Markdown"
for notebook in `find $NOTEBOOKS -not -path "*/\.*" -name "*.ipynb"`
do
  jupyter nbconvert --to markdown $notebook
done

echo "---复制生成的Markdown文件至content/post/tech文件夹"
for md in `find $NOTEBOOKS -not -path "*/\.*" -name "*.md"`
do
  filename=`basename $md`
  cat $TOML $md >> $DEST/$filename
done

echo "---退出"
