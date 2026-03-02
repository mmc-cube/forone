# 一键更新：扫描项目 -> 更新配置 -> 推送到 GitHub

Set-Location $PSScriptRoot
$ErrorActionPreference = "Continue"

Write-Host "===== Scanning projects folder =====" -ForegroundColor Cyan

# 1. 扫描 projects/ 生成 projects.json
$folders = @()
if (Test-Path "projects") {
    $folders = (Get-ChildItem "projects" -Directory).Name | Sort-Object
}

if ($folders.Count -eq 0) {
    Write-Host "projects folder is empty" -ForegroundColor Yellow
    Read-Host "Press any key to exit"
    exit
}

# Convert to JSON format
$json = ConvertTo-Json $folders
Write-Host "projects.json updated: $json"

# 保存为 UTF-8 文件
$json | Out-File -Encoding UTF8 -FilePath "projects.json"

# 2. Sync BUILTIN_PROJECTS in index.html
$htmlFile = "index.html"
if (Test-Path $htmlFile) {
    $content = Get-Content $htmlFile -Raw -Encoding UTF8
    $content = $content -replace 'const BUILTIN_PROJECTS = \[.*?\];', "const BUILTIN_PROJECTS = $json;"
    $content | Out-File -Encoding UTF8 -FilePath $htmlFile
    Write-Host "index.html synced"
}

# 3. Push to GitHub
Write-Host ""
Write-Host "===== Pushing to GitHub =====" -ForegroundColor Cyan

git add -A

$status = git status --porcelain
if ([string]::IsNullOrWhiteSpace($status)) {
    Write-Host "No changes to commit" -ForegroundColor Yellow
} else {
    git status --short
    $date = Get-Date -Format "yyyy-MM-dd_HH:mm"
    git commit -m "update: projects list $date"

    if ($LASTEXITCODE -eq 0) {
        git push
        if ($LASTEXITCODE -eq 0) {
            Write-Host ""
            Write-Host "===== Push completed =====" -ForegroundColor Green
        } else {
            Write-Host "Push failed. Check network and GitHub token" -ForegroundColor Red
        }
    } else {
        Write-Host "Commit failed" -ForegroundColor Red
    }
}

Read-Host "Press any key to exit"
