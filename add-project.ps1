# Add Project to WebApp - Automated Script
# Usage: .\add-project.ps1 "C:\path\to\project"

param(
    [Parameter(Mandatory=$true)]
    [string]$ProjectPath
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

$projectName = Split-Path -Leaf $ProjectPath
Write-Host "Project name: $projectName"

$targetPath = Join-Path "projects" $projectName
if (Test-Path $targetPath) {
    Write-Error-Custom "Error: Project '$projectName' already exists in projects/"
    Read-Host "Press any key to exit"
    exit 1
}

Write-Success "Project name validated"

# 3. Copy project files
Write-Info ""
Write-Info "Step 3: Copying project files..."

Copy-Item -Path $ProjectPath -Destination $targetPath -Recurse -Force
Write-Success "Project copied to projects/$projectName"

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
    $newPath = Join-Path $targetPath "index.html"
    Rename-Item -Path $oldPath -NewName "index.html" -Force
    Write-Success "Renamed $entryFile -> index.html"
} else {
    Write-Success "Entry file is already named index.html"
}

# 5. Update project list
Write-Info ""
Write-Info "Step 5: Updating project list..."

$folders = @()
if (Test-Path "projects") {
    $folders = (Get-ChildItem "projects" -Directory).Name | Sort-Object
}

$json = ConvertTo-Json $folders
Write-Host "projects.json: $json"
$json | Out-File -Encoding UTF8 -FilePath "projects.json"

# Sync to index.html
$htmlFile = "index.html"
if (Test-Path $htmlFile) {
    $content = Get-Content $htmlFile -Raw -Encoding UTF8
    $content = $content -replace 'const BUILTIN_PROJECTS = \[.*?\];', "const BUILTIN_PROJECTS = $json;"
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
    $date = Get-Date -Format "yyyy-MM-dd_HH:mm"
    git commit -m "add: New project $projectName"

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
Write-Host "Project: $projectName"
Write-Host "Location: projects/$projectName/"
Write-Host "Entry file: index.html"
Write-Host ""
Write-Host "The project is now live on Cloudflare Pages!"

Read-Host "Press any key to exit"
