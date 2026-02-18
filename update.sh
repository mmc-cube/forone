#!/bin/bash
# 一键更新：扫描项目 → 更新配置 → 推送到 GitHub
# 用法：双击运行 或 bash update.sh

cd "$(dirname "$0")"

echo "===== 扫描 projects 文件夹 ====="

# 1. 扫描 projects/ 生成 projects.json
folders=()
for dir in projects/*/; do
    if [ -d "$dir" ]; then
        name=$(basename "$dir")
        folders+=("\"$name\"")
    fi
done

json="["
first=true
for f in "${folders[@]}"; do
    if [ "$first" = true ]; then first=false; else json+=", "; fi
    json+="$f"
done
json+="]"

echo "$json" > projects.json
echo "projects.json 已更新: $json"

# 2. 同步更新 index.html 中的 BUILTIN_PROJECTS
sed -i "s/const BUILTIN_PROJECTS = .*/const BUILTIN_PROJECTS = $json;/" index.html
echo "index.html 内置列表已同步"

# 3. 推送到 GitHub
echo ""
echo "===== 推送到 GitHub ====="
git add -A
git status --short

# 检查是否有变更
if git diff --cached --quiet; then
    echo "没有变更，无需推送"
else
    git commit -m "update: 更新项目列表 $(date +%Y-%m-%d_%H:%M)"
    git push
    echo ""
    echo "===== 推送完成 ====="
fi

echo ""
echo "按任意键退出..."
read -n 1
