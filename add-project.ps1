# Add Project to WebApp - Automated Script
# Usage: .\add-project.ps1 "C:\path\to\project"

param(
    [Parameter(Mandatory=$true)]
    [string]$ProjectPath,
    [Parameter(Mandatory=$false)]
    [string]$ProjectName = ""   # 中文项目名，用于 admin 面板显示；留空则用文件夹名
)

Set-Location $PSScriptRoot
$ErrorActionPreference = "Continue"

# Color output
function Write-Success { Write-Host $args[0] -ForegroundColor Green }
function Write-Error-Custom { Write-Host $args[0] -ForegroundColor Red }
function Write-Info { Write-Host $args[0] -ForegroundColor Cyan }
function Write-Warn { Write-Host $args[0] -ForegroundColor Yellow }

Write-Info "===== Adding New Project ====="

# 1. Validate project path
Write-Info ""
Write-Info "Step 1: Validating project path..."

if (-not (Test-Path $ProjectPath)) {
    Write-Error-Custom "Error: Project path does not exist"
    Write-Error-Custom "Path: $ProjectPath"
    Read-Host "Press any key to exit"
    exit 1
}

if (-not (Test-Path (Join-Path $ProjectPath "*.html"))) {
    Write-Error-Custom "Error: No HTML files found in project"
    Read-Host "Press any key to exit"
    exit 1
}

Write-Success "Project path validated"

# 2. Extract project name
Write-Info ""
Write-Info "Step 2: Extracting project name..."

$projectId = Split-Path -Leaf $ProjectPath
Write-Host "Project ID (folder name): $projectId"

# 中文显示名：优先用参数，否则用文件夹名
if ([string]::IsNullOrWhiteSpace($ProjectName)) {
    $ProjectName = $projectId
}
Write-Host "Project display name: $ProjectName"

$targetPath = Join-Path "projects" $projectId
if (Test-Path $targetPath) {
    Write-Error-Custom "Error: Project '$projectId' already exists in projects/"
    Read-Host "Press any key to exit"
    exit 1
}

Write-Success "Project name validated"

# 3. Copy project files
Write-Info ""
Write-Info "Step 3: Copying project files..."

Copy-Item -Path $ProjectPath -Destination $targetPath -Recurse -Force
Write-Success "Project copied to projects/$projectId"

# 4. Detect and rename entry file
Write-Info ""
Write-Info "Step 4: Checking for entry file..."

$possibleEntries = @("index.html", "app.html", "main.html", "home.html", "index.htm")
$entryFile = $null

foreach ($entry in $possibleEntries) {
    $testPath = Join-Path $targetPath $entry
    if (Test-Path $testPath) {
        $entryFile = $entry
        break
    }
}

if (-not $entryFile) {
    Write-Error-Custom "Error: No suitable entry file found"
    Write-Error-Custom "Expected one of: $($possibleEntries -join ', ')"
    # Cleanup on failure
    Remove-Item $targetPath -Recurse -Force
    Read-Host "Press any key to exit"
    exit 1
}

if ($entryFile -ne "index.html") {
    Write-Host "Found entry file: $entryFile"
    $oldPath = Join-Path $targetPath $entryFile
    Rename-Item -Path $oldPath -NewName "index.html" -Force
    Write-Success "Renamed $entryFile -> index.html"
} else {
    Write-Success "Entry file is already named index.html"
}

# 5. Update project list
Write-Info ""
Write-Info "Step 5: Updating project list..."

# 读取现有 projects.json（对象数组格式），追加新项目
$existingProjects = @()
if (Test-Path "projects.json") {
    $raw = Get-Content "projects.json" -Raw -Encoding UTF8
    $parsed = $raw | ConvertFrom-Json
    # 兼容旧格式（字符串数组）
    foreach ($item in $parsed) {
        if ($item -is [string]) {
            $existingProjects += @{ id = $item; name = $item }
        } else {
            $existingProjects += @{ id = $item.id; name = $item.name }
        }
    }
}

# 追加新项目（如已存在则跳过）
if (-not ($existingProjects | Where-Object { $_.id -eq $projectId })) {
    $existingProjects += @{ id = $projectId; name = $ProjectName }
}

# 按 id 排序后写回
$sorted = $existingProjects | Sort-Object { $_.id }
$json = $sorted | ConvertTo-Json
$json | Out-File -Encoding UTF8 -FilePath "projects.json"
Write-Success "projects.json updated ($projectId / $ProjectName)"

# 同步更新 index.html 中的 BUILTIN_PROJECTS（对象数组格式）
$htmlFile = "index.html"
if (Test-Path $htmlFile) {
    $builtinJson = $sorted | ConvertTo-Json -Compress
    $content = Get-Content $htmlFile -Raw -Encoding UTF8
    $content = $content -replace '(?s)const BUILTIN_PROJECTS = \[.*?\];', "const BUILTIN_PROJECTS = $builtinJson;"
    $content | Out-File -Encoding UTF8 -FilePath $htmlFile
    Write-Success "index.html synced"
}

# 6. Push to GitHub
Write-Info ""
Write-Info "Step 6: Pushing to GitHub..."

git add -A

$status = git status --porcelain
if ([string]::IsNullOrWhiteSpace($status)) {
    Write-Warn "No changes to commit"
} else {
    git status --short
    git commit -m "add: New project $projectId ($ProjectName)"

    if ($LASTEXITCODE -eq 0) {
        git push
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Pushed to GitHub"
        } else {
            Write-Error-Custom "Git push failed. Check network and GitHub token"
            Read-Host "Press any key to exit"
            exit 1
        }
    } else {
        Write-Error-Custom "Git commit failed"
        Read-Host "Press any key to exit"
        exit 1
    }
}

# Success
Write-Info ""
Write-Success "===== Project Added Successfully ====="
Write-Host "Project ID: $projectId"
Write-Host "Display name: $ProjectName"
Write-Host "Location: projects/$projectName/"
Write-Host "Entry file: index.html"
Write-Host ""
Write-Host "The project is now live on Cloudflare Pages!"

Read-Host "Press any key to exit"
