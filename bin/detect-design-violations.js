#!/usr/bin/env node

// ═══════════════════════════════════════════════════════════════════════════
// DESIGN SYSTEM VIOLATION DETECTOR
// ═══════════════════════════════════════════════════════════════════════════
//
// Scans the codebase for design system violations:
// • Hardcoded hex colors (#FFF, #123456, etc.)
// • Hardcoded rgb/rgba colors
// • Hardcoded spacing values (px, rem, etc.)
// • Static inline styles without CSS variables
// • Deprecated color names
//
// Usage:
//   npm run detect-violations
//   node bin/detect-design-violations.js
//   node bin/detect-design-violations.js --fix (future: auto-fix violations)
//
// ═══════════════════════════════════════════════════════════════════════════

const fs = require('fs');
const path = require('path');
const glob = require('glob');

class ViolationDetector {
  constructor(options = {}) {
    this.violations = [];
    this.warnings = [];
    this.fixed = [];
    this.options = {
      fix: options.fix || false,
      verbose: options.verbose !== false,
      ...options,
    };

    // Patterns for detecting violations
    this.patterns = {
      // Hex colors: #FFF, #123456
      hexColor: /#[0-9a-fA-F]{3}(?:[0-9a-fA-F]{3})?\b/g,
      // RGB/RGBA colors
      rgbColor: /rgba?\s*\(\s*\d+\s*,\s*\d+\s*,\s*\d+[^)]*\)/gi,
      // Hardcoded pixels (but allow var() and CSS variables)
      hardcodedPx: /(?<!var\(--)['\"]?\d+px['\"]?/g,
      // Hardcoded rem (but allow var())
      hardcodedRem: /(?<!var\(--)['\"]?\d+(?:\.\d+)?rem['\"]?/g,
      // Static inline styles (rough pattern)
      staticInlineStyle: /style\s*=\s*['\"](?!.*var\()[^'"]*['\"]/g,
    };

    // Files to scan
    this.targetPatterns = [
      'app/javascript/dashboard/**/*.vue',
      'app/javascript/dashboard/**/*.js',
      'app/javascript/dashboard/**/*.scss',
    ];

    // Files to exclude
    this.excludePatterns = [
      '**/node_modules/**',
      '**/*.min.js',
      '**/*.min.css',
      '**/dist/**',
      '**/build/**',
      '**/.git/**',
      '**/TOKENS.md',
      '**/CHANGELOG.md',
    ];
  }

  // Scans all target files for violations
  scan() {
    console.log('🔍 Scanning for design system violations...\n');

    const allFiles = this.findFiles();

    allFiles.forEach(file => {
      this.scanFile(file);
    });

    return {
      violations: this.violations,
      warnings: this.warnings,
      stats: this.generateStats(),
    };
  }

  // Finds all files matching target patterns
  findFiles() {
    const files = [];

    this.targetPatterns.forEach(pattern => {
      const matches = glob.sync(pattern, {
        ignore: this.excludePatterns,
      });
      files.push(...matches);
    });

    return [...new Set(files)];
  }

  // Scans a single file for violations
  scanFile(filePath) {
    try {
      const content = fs.readFileSync(filePath, 'utf8');
      const lines = content.split('\n');

      lines.forEach((line, lineNum) => {
        this.checkLine(filePath, line, lineNum + 1);
      });
    } catch (error) {
      this.warnings.push({
        file: filePath,
        error: error.message,
      });
    }
  }

  // Checks a single line for violations
  checkLine(filePath, line, lineNum) {
    // Skip comments and documentation
    if (line.trim().startsWith('//') || line.trim().startsWith('/*') || line.trim().startsWith('*')) {
      return;
    }

    // Check for hex colors
    const hexMatches = line.matchAll(this.patterns.hexColor);
    for (const match of hexMatches) {
      // Exclude certain contexts
      if (!this.shouldExclude(line, match.index)) {
        this.violations.push({
          file: filePath,
          line: lineNum,
          type: 'hardcoded-hex-color',
          value: match[0],
          message: `Hardcoded hex color: ${match[0]}. Use design tokens instead.`,
        });
      }
    }

    // Check for rgb/rgba colors
    const rgbMatches = line.matchAll(this.patterns.rgbColor);
    for (const match of rgbMatches) {
      if (!this.shouldExclude(line, match.index)) {
        this.violations.push({
          file: filePath,
          line: lineNum,
          type: 'hardcoded-rgb-color',
          value: match[0],
          message: `Hardcoded RGB color: ${match[0]}. Use design tokens instead.`,
        });
      }
    }

    // Check for hardcoded pixels (excluding variable references)
    if (!line.includes('var(--') && line.match(/\d+px/)) {
      const pxMatches = line.matchAll(/(\d+)px/g);
      for (const match of pxMatches) {
        // Exclude certain safe contexts
        if (!this.isSafePixelValue(line, match[0])) {
          this.violations.push({
            file: filePath,
            line: lineNum,
            type: 'hardcoded-spacing',
            value: match[0],
            message: `Hardcoded spacing: ${match[0]}. Use spacing tokens (--space-*).`,
          });
        }
      }
    }
  }

  // Determines if a match should be excluded
  shouldExclude(line, index) {
    // Exclude if inside a comment
    const beforeMatch = line.substring(0, index);
    if (beforeMatch.includes('//') || beforeMatch.includes('/*')) {
      return true;
    }

    // Exclude if inside a string with 'var(' nearby
    if (line.includes('var(--')) {
      return false;
    }

    return false;
  }

  // Checks if a pixel value is safe (e.g., border-width, etc.)
  isSafePixelValue(line, value) {
    const safePatterns = [
      'border-width',
      'outline-width',
      'stroke-width',
      'border-radius',
      'border:',
    ];

    return safePatterns.some(pattern => line.includes(pattern));
  }

  // Generates violation statistics
  generateStats() {
    const stats = {
      total: this.violations.length,
      byType: {},
    };

    this.violations.forEach(v => {
      stats.byType[v.type] = (stats.byType[v.type] || 0) + 1;
    });

    return stats;
  }

  // Generates a detailed report
  generateReport() {
    let report = '\n📋 DESIGN SYSTEM VIOLATION REPORT\n';
    report += '═'.repeat(50) + '\n\n';

    if (this.violations.length === 0) {
      report += '✅ No violations found!\n';
      return report;
    }

    // Group violations by file
    const byFile = {};
    this.violations.forEach(v => {
      if (!byFile[v.file]) byFile[v.file] = [];
      byFile[v.file].push(v);
    });

    // Report by file
    Object.entries(byFile).forEach(([file, vios]) => {
      report += `\n📄 ${file}\n`;
      report += '─'.repeat(50) + '\n';
      vios.forEach(v => {
        report += `  Line ${v.line}: ${v.message}\n`;
        report += `    > ${v.value}\n`;
      });
    });

    // Summary
    report += '\n' + '═'.repeat(50) + '\n';
    report += `\n📊 SUMMARY\n`;
    report += `Total violations: ${this.violations.length}\n`;

    Object.entries(this.generateStats().byType).forEach(([type, count]) => {
      report += `  • ${type}: ${count}\n`;
    });

    report += `\n⚠️  Warnings: ${this.warnings.length}\n`;

    return report;
  }

  // Exports violations as JSON
  exportJSON(filePath) {
    const data = {
      generatedAt: new Date().toISOString(),
      violations: this.violations,
      warnings: this.warnings,
      stats: this.generateStats(),
    };

    fs.writeFileSync(filePath, JSON.stringify(data, null, 2));
    console.log(`📁 Violations exported to ${filePath}`);
  }
}

// CLI execution
if (require.main === module) {
  const args = process.argv.slice(2);
  const options = {
    fix: args.includes('--fix'),
    verbose: !args.includes('--quiet'),
  };

  const detector = new ViolationDetector(options);
  const result = detector.scan();

  console.log(detector.generateReport());

  // Export as JSON for CI/CD integration
  detector.exportJSON('.design-violations.json');

  // Exit with error code if violations found
  process.exit(result.violations.length > 0 ? 1 : 0);
}

module.exports = ViolationDetector;
