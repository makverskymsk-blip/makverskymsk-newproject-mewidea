# Light Theme Color Fix Script
# Run this from: e:\src\projects\new_idea_works

$files = Get-ChildItem -Path "lib\screens\community" -Filter "*.dart" -Recurse

foreach ($file in $files) {
    $content = Get-Content $file.FullName -Raw -Encoding UTF8

    # Remove dart:ui import (no longer need BackdropFilter)
    $content = $content -replace "import 'dart:ui';\r?\n", ""

    # Replace dark backgrounds with white
    $content = $content -replace 'Container\(color: Colors\.black\.withValues\(alpha: 0\.\d+\)\)', 'Container(color: Colors.white)'

    # Replace BackdropFilter dialogs with plain dialogs
    $content = $content -replace 'builder: \(ctx\) => BackdropFilter\(\r?\n\s+filter: ImageFilter\.blur\(sigmaX: \d+, sigmaY: \d+\),\r?\n\s+child: AlertDialog\(', 'builder: (ctx) => AlertDialog('
    $content = $content -replace 'builder: \(ctx\) => BackdropFilter\(\r?\n\s+filter: ImageFilter\.blur\(sigmaX: \d+, sigmaY: \d+\),\r?\n\s+child: StatefulBuilder\(', 'builder: (ctx) => StatefulBuilder('

    # Fix dialog backgrounds
    $content = $content -replace "backgroundColor: Colors\.white\.withValues\(alpha: 0\.9\d*\)", "backgroundColor: Colors.white"

    # Fix remaining Colors.white.withValues patterns
    $content = $content -replace 'Colors\.white\.withValues\(alpha: 0\.0[1-5]\)', 'Colors.black.withValues(alpha: 0.02)'
    $content = $content -replace 'Colors\.white\.withValues\(alpha: 0\.0[6-9]\)', 'AppColors.borderLight.withValues(alpha: 0.5)'
    $content = $content -replace 'Colors\.white\.withValues\(alpha: 0\.1\)', 'AppColors.borderLight'
    $content = $content -replace 'Colors\.white\.withValues\(alpha: 0\.15\)', 'Colors.black.withValues(alpha: 0.06)'
    $content = $content -replace 'Colors\.white\.withValues\(alpha: 0\.2\)', 'Colors.black.withValues(alpha: 0.08)'
    $content = $content -replace 'Colors\.white\.withValues\(alpha: 0\.3\)', 'AppColors.textHint'
    $content = $content -replace 'Colors\.white\.withValues\(alpha: 0\.4\)', 'AppColors.textHint'
    $content = $content -replace 'Colors\.white\.withValues\(alpha: 0\.5\)', 'AppColors.textHint'
    $content = $content -replace 'Colors\.white\.withValues\(alpha: 0\.6\)', 'AppColors.textSecondary'
    $content = $content -replace 'Colors\.white\.withValues\(alpha: 0\.7\)', 'AppColors.textSecondary'
    $content = $content -replace 'Colors\.white\.withValues\(alpha: 0\.8\d*\)', 'AppColors.textPrimary'
    $content = $content -replace 'Colors\.white70', 'AppColors.textSecondary'
    $content = $content -replace 'Colors\.white10', 'AppColors.borderLight'
    $content = $content -replace 'Colors\.white12', 'AppColors.borderLight'

    # Fix text input styles
    $content = $content -replace "style: const TextStyle\(color: Colors\.white\)", "style: const TextStyle(color: AppColors.textPrimary)"

    # Fix surface colors
    $content = $content -replace "backgroundColor: AppColors\.surface", "backgroundColor: Colors.white"
    $content = $content -replace "color: AppColors\.surface", "color: AppColors.backgroundCard"

    Set-Content $file.FullName -Value $content -Encoding UTF8 -NoNewline
    Write-Host "Updated: $($file.Name)"
}

Write-Host "`nDone! All community screens updated."
