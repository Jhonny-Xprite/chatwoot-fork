#!/usr/bin/env node

// ═══════════════════════════════════════════════════════════════════════════
// AUTOMATIC TOKEN MIGRATION TOOL
// ═══════════════════════════════════════════════════════════════════════════
//
// Automatically migrates components to use design system tokens.
// Handles:
// • Hex color → semantic token mapping
// • Inline styles → Tailwind classes
// • Hardcoded spacing → token variables
//
// Usage:
//   node bin/auto-migrate-tokens.js --dry-run
//   node bin/auto-migrate-tokens.js --fix
//   node bin/auto-migrate-tokens.js --fix --verbose
//
// ═══════════════════════════════════════════════════════════════════════════

const fs = require('fs');
const path = require('path');

class TokenMigrator {
  constructor(options = {}) {
    this.options = {
      dryRun: options.dryRun !== false,
      verbose: options.verbose || false,
      ...options,
    };

    // Color mapping: hex → semantic token
    this.colorMap = {
      '#ffffff': 'n-slate-0',
      '#f8fafc': 'n-slate-50',
      '#f1f5f9': 'n-slate-100',
      '#e2e8f0': 'n-slate-200',
      '#cbd5e1': 'n-slate-300',
      '#94a3b8': 'n-slate-400',
      '#64748b': 'n-slate-500',
      '#475569': 'n-slate-600',
      '#334155': 'n-slate-700',
      '#1e293b': 'n-slate-800',
      '#0f172a': 'n-slate-900',
      '#000000': 'n-slate-950',
      '#ef4444': 'n-red-500',
      '#10b981': 'n-green-500',
      '#f59e0b': 'n-amber-500',
      '#3b82f6': 'n-blue-500',
      '#8b5cf6': 'n-purple-500',
    };

    // Spacing mapping: px → class
    this.spacingMap = {
      '2px': 'px-0.5',
      '4px': 'px-1',
      '8px': 'px-2',
      '12px': 'px-3',
      '16px': 'px-4',
      '20px': 'px-5',
      '24px': 'px-6',
      '28px': 'px-7',
      '32px': 'px-8',
      '36px': 'px-9',
      '40px': 'px-10',
    };

    this.stats = {
      filesProcessed: 0,
      colorsFixed: 0,
      spacingFixed: 0,
      inlineStylesFixed: 0,
      errors: [],
    };
  }

  migrate(filePath) {
    try {
      const content = fs.readFileSync(filePath, 'utf8');
      let modified = content;
      let changed = false;

      // Fix hex colors
      Object.entries(this.colorMap).forEach(([hex, token]) => {
        const hexPattern = new RegExp(`['"]${hex}['"]`, 'gi');
        if (hexPattern.test(modified)) {
          modified = modified.replace(hexPattern, `var(--${token})`);
          this.stats.colorsFixed++;
          changed = true;
        }
      });

      // Fix hardcoded spacing
      Object.entries(this.spacingMap).forEach(([px, tailwind]) => {
        const pxPattern = new RegExp(`['"]${px}['"]`, 'g');
        if (pxPattern.test(modified)) {
          modified = modified.replace(pxPattern, tailwind);
          this.stats.spacingFixed++;
          changed = true;
        }
      });

      // Remove style attributes with single properties
      const stylePattern = /style\s*=\s*['"]\{?\s*([^}'"]*)\s*\}?['"]/g;
      if (stylePattern.test(modified)) {
        modified = modified.replace(stylePattern, (match, styles) => {
          // Only remove if it's a simple property
          if (styles.includes(':') && !styles.includes(';')) {
            this.stats.inlineStylesFixed++;
            changed = true;
            return '';
          }
          return match;
        });
      }

      if (changed && !this.options.dryRun) {
        fs.writeFileSync(filePath, modified, 'utf8');
        if (this.options.verbose) {
          console.log(`✓ ${path.basename(filePath)}`);
        }
      }

      return { changed, modified: changed ? modified : content };
    } catch (error) {
      this.stats.errors.push({
        file: filePath,
        error: error.message,
      });
      return { changed: false };
    }
  }

  migrateComponentList(components) {
    console.log(`📝 Processing ${components.length} components...\n`);

    components.forEach((component) => {
      this.migrate(component.file);
      this.stats.filesProcessed++;
    });

    this.reportStats();
  }

  reportStats() {
    console.log('\n📊 MIGRATION RESULTS');
    console.log('═'.repeat(60));
    console.log(`Files processed: ${this.stats.filesProcessed}`);
    console.log(`Colors fixed: ${this.stats.colorsFixed}`);
    console.log(`Spacing fixed: ${this.stats.spacingFixed}`);
    console.log(`Inline styles removed: ${this.stats.inlineStylesFixed}`);

    if (this.stats.errors.length > 0) {
      console.log(`\n⚠️ Errors: ${this.stats.errors.length}`);
      this.stats.errors.slice(0, 5).forEach((err) => {
        console.log(`  • ${err.file}: ${err.error}`);
      });
    }

    console.log(
      `\n${this.options.dryRun ? '(DRY RUN - no files modified)' : '✅ All changes applied'}`
    );
  }
}

// Get HIGH priority components from analysis
const analysisPath = '.component-token-analysis.json';
let highPriorityComponents = [];

if (fs.existsSync(analysisPath)) {
  const analysis = JSON.parse(fs.readFileSync(analysisPath, 'utf8'));
  const allComponents = analysis.components || [];

  // Filter HIGH priority (>= 12 violations)
  highPriorityComponents = allComponents
    .filter((c) => {
      const violations = Object.values(c.violations).reduce(
        (sum, v) => sum + v.count,
        0
      );
      return violations >= 12;
    })
    .slice(0, 15);

  console.log(`Found ${highPriorityComponents.length} HIGH priority components\n`);
}

// CLI execution
if (require.main === module) {
  const args = process.argv.slice(2);
  const options = {
    dryRun: args.includes('--dry-run'),
    verbose: args.includes('--verbose'),
  };

  if (options.dryRun && !args.includes('--fix')) {
    console.log('🔍 DRY RUN MODE - No files will be modified\n');
  }

  const migrator = new TokenMigrator(options);

  if (highPriorityComponents.length > 0) {
    migrator.migrateComponentList(highPriorityComponents);
  } else {
    console.log('⚠️ No HIGH priority components found.');
    console.log('Run: node bin/analyze-component-tokens.js --export');
  }
}

module.exports = TokenMigrator;
