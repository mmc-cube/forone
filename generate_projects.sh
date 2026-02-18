#!/bin/bash
# 自动扫描 projects/ 下的文件夹，生成 projects.json
# 每次新增/删除项目后运行一次即可

cd "$(dirname "$0")"

folders=()
for dir in projects/*/; do
    if [ -d "$dir" ]; then
        name=$(basename "$dir")
        folders+=("\"$name\"")
    fi
done

# 拼接 JSON 数组
json="["
first=true
for f in "${folders[@]}"; do
    if [ "$first" = true ]; then
        first=false
    else
        json+=", "
    fi
    json+="$f"
done
json+="]"

echo "$json" > projects.json
echo "已更新 projects.json: $json"
