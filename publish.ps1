# Публикация прототипа каталога на GitHub Pages
# Запуск: правый клик → «Выполнить с PowerShell»  или  в терминале: .\publish.ps1

$ErrorActionPreference = "Stop"
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

$RepoName = "beanabox-catalog-redesign"
$Git = "C:\Program Files\Git\bin\git.exe"
$Gh  = "C:\Program Files\GitHub CLI\gh.exe"

Set-Location -LiteralPath $PSScriptRoot

Write-Host "`n=== 1. Вход в GitHub ===" -ForegroundColor Cyan
& $Gh auth status 2>$null
if ($LASTEXITCODE -ne 0) {
  Write-Host "Откроется браузер / код устройства. Войди как lidee4ka." -ForegroundColor Yellow
  & $Gh auth login --hostname github.com --git-protocol https --web
  if ($LASTEXITCODE -ne 0) { throw "Не удалось войти в GitHub" }
}

Write-Host "`n=== 2. Создание репозитория (если ещё нет) ===" -ForegroundColor Cyan
$exists = & $Gh repo view "lidee4ka/$RepoName" 2>$null
if ($LASTEXITCODE -ne 0) {
  & $Gh repo create $RepoName --public --source=. --remote=origin --description "BEANABOX catalog redesign prototype" --push
} else {
  Write-Host "Репозиторий уже есть — пушим main..."
  $remotes = & $Git remote
  if ($remotes -notcontains "origin") {
    & $Git remote add origin "https://github.com/lidee4ka/$RepoName.git"
  }
  & $Git push -u origin main
}

Write-Host "`n=== 3. Включение GitHub Pages ===" -ForegroundColor Cyan
& $Gh api -X POST "repos/lidee4ka/$RepoName/pages" -f build_type=legacy -f source[branch]=main -f source[path]=/ 2>$null
if ($LASTEXITCODE -ne 0) {
  & $Gh api -X PUT "repos/lidee4ka/$RepoName/pages" -f build_type=legacy -f source[branch]=main -f source[path]=/ 2>$null
}

Start-Sleep -Seconds 3
$pages = & $Gh api "repos/lidee4ka/$RepoName/pages" | ConvertFrom-Json
$url = if ($pages.html_url) { $pages.html_url } else { "https://lidee4ka.github.io/$RepoName/" }

Write-Host "`nГотово!" -ForegroundColor Green
Write-Host "Страница: $url"
Write-Host "(первый раз Pages может подняться за 1–2 минуты)"
Write-Host ""
