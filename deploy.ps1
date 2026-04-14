# deploy.ps1 - Deploy Flutter Web to GitHub Pages
Write-Host "Building..." -ForegroundColor Cyan
flutter build web --release --base-href "/"

Write-Host "Preparing..." -ForegroundColor Cyan
Set-Content -Path "build\web\CNAME" -Value "yourperformancelab.ru" -NoNewline
Copy-Item "build\web\index.html" "build\web\404.html"
Remove-Item -Recurse -Force "build\web\.git" -ErrorAction SilentlyContinue

Write-Host "Deploying..." -ForegroundColor Cyan
Set-Location "build\web"
git init
git checkout -b gh-pages
git add -A
git commit -m "Deploy: $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
git remote add origin https://github.com/makverskymsk-blip/makverskymsk-newproject-mewidea.git
git push origin gh-pages --force
Set-Location "../.."

Write-Host "Done! https://yourperformancelab.ru" -ForegroundColor Green
