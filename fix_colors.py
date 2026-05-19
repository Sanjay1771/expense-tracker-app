import os

replacements = {
    "AppTheme.bgCardLight": "Theme.of(context).cardTheme.color?.withValues(alpha: 0.5)",
    "AppTheme.bgCard": "Theme.of(context).cardTheme.color",
    "AppTheme.bg": "Theme.of(context).colorScheme.surface",
    "AppTheme.textPrimary": "Theme.of(context).colorScheme.onSurface",
    "AppTheme.textSecondary": "Theme.of(context).colorScheme.onSurfaceVariant",
    "AppTheme.textMuted": "Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6)",
    "AppTheme.neonBlue": "Theme.of(context).colorScheme.primary",
    "AppTheme.neonGreen": "Theme.of(context).colorScheme.tertiary",
    "AppTheme.neonRed": "Theme.of(context).colorScheme.error",
    "AppTheme.neonOrange": "Theme.of(context).colorScheme.secondary",
    "AppTheme.neonPink": "Theme.of(context).colorScheme.secondary",
    "AppTheme.neonPurple": "Theme.of(context).colorScheme.primary",
    "AppTheme.success": "Theme.of(context).colorScheme.tertiary",
    "AppTheme.error": "Theme.of(context).colorScheme.error",
    "AppTheme.seedColor": "Theme.of(context).colorScheme.primary",
}

for root, _, files in os.walk('lib'):
    for file in files:
        if file.endswith('.dart'):
            filepath = os.path.join(root, file)
            with open(filepath, 'r', encoding='utf-8') as f:
                content = f.read()
            
            new_content = content
            for old, new in replacements.items():
                new_content = new_content.replace(old, new)
            
            if new_content != content:
                with open(filepath, 'w', encoding='utf-8') as f:
                    f.write(new_content)
                print(f"Updated {filepath}")
