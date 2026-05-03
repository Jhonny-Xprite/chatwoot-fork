#!/usr/bin/env node

// ═══════════════════════════════════════════════════════════════════════════
// DETAILED VIOLATION SCANNER
// ═══════════════════════════════════════════════════════════════════════════
//
// Shows exact line numbers and violations for components
//
// Usage:
//   node bin/detail-violations.js Avatar.vue
//   node bin/detail-violations.js app/javascript/dashboard/components-next/avatar/Avatar.vue
//
// ═══════════════════════════════════════════════════════════════════════════

const fs = require('fs');
const path = require('path');

function findFile(search) {
  const baseDir = 'app/javascript/dashboard';

  const walkDir = (dir) => {
    try {
      const entries = fs.readdirSync(dir, { withFileTypes: true });

      for (const entry of entries) {
        const fullPath = path.join(dir, entry.name);

        if (entry.isDirectory()) {
          const result = walkDir(fullPath);
          if (result) return result;
        } else if (entry.name === search || fullPath.includes(search)) {
          return fullPath;
        }
      }
    } catch (err) {
      return null;
    }
  };

  return walkDir(baseDir);
}

function analyzeFile(filePath) {
  const content = fs.readFileSync(filePath, 'utf8');
  const lines = content.split('\n');

  const violations = {
    hexColors: [],
    rgbColors: [],
    inlineStyles: [],
    hardcodedPx: [],
  };

  lines.forEach((line, index) => {
    const lineNum = index + 1;

    // Hex colors
    const hexMatches = line.match(/#[0-9a-fA-F]{3}(?:[0-9a-fA-F]{3})?\b/g);
    if (hexMatches) {
      hexMatches.forEach(hex => {
        violations.hexColors.push({
          line: lineNum,
          text: line.trim(),
          value: hex,
        });
      });
    }

    // RGB colors
    const rgbMatches = line.match(/rgba?\s*\(\s*\d+\s*,\s*\d+\s*,\s*\d+[^)]*\)/gi);
    if (rgbMatches) {
      rgbMatches.forEach(rgb => {
        violations.rgbColors.push({
          line: lineNum,
          text: line.trim(),
          value: rgb,
        });
      });
    }

    // Inline styles
    if (line.includes('style') && line.includes('=')) {
      violations.inlineStyles.push({
        line: lineNum,
        text: line.trim(),
      });
    }

    // Hardcoded px
    const pxMatches = line.match(/['"]?\d+px['"]?/g);
    if (pxMatches) {
      pxMatches.forEach(px => {
        violations.hardcodedPx.push({
          line: lineNum,
          text: line.trim(),
          value: px,
        });
      });
    }
  });

  return violations;
}

// Main execution
if (require.main === module) {
  const search = process.argv[2];

  if (!search) {
    console.log('Usage: node bin/detail-violations.js <component-name>');
    console.log('Example: node bin/detail-violations.js Avatar.vue');
    process.exit(1);
  }

  const filePath = findFile(search);

  if (!filePath) {
    console.log(`❌ File not found: ${search}`);
    process.exit(1);
  }

  console.log(`📄 Analyzing: ${filePath}\n`);

  const violations = analyzeFile(filePath);

  console.log('📊 VIOLATIONS FOUND\n');

  if (violations.hexColors.length > 0) {
    console.log(`🎨 HEX COLORS (${violations.hexColors.length})`);
    violations.hexColors.slice(0, 5).forEach(v => {
      console.log(`  Line ${v.line}: ${v.value}`);
      console.log(`    ${v.text}`);
    });
    if (violations.hexColors.length > 5) {
      console.log(`  ... and ${violations.hexColors.length - 5} more`);
    }
    console.log();
  }

  if (violations.rgbColors.length > 0) {
    console.log(`🌈 RGB COLORS (${violations.rgbColors.length})`);
    violations.rgbColors.slice(0, 5).forEach(v => {
      console.log(`  Line ${v.line}: ${v.value}`);
      console.log(`    ${v.text}`);
    });
    if (violations.rgbColors.length > 5) {
      console.log(`  ... and ${violations.rgbColors.length - 5} more`);
    }
    console.log();
  }

  if (violations.inlineStyles.length > 0) {
    console.log(`💅 INLINE STYLES (${violations.inlineStyles.length})`);
    violations.inlineStyles.slice(0, 5).forEach(v => {
      console.log(`  Line ${v.line}:`);
      console.log(`    ${v.text}`);
    });
    if (violations.inlineStyles.length > 5) {
      console.log(`  ... and ${violations.inlineStyles.length - 5} more`);
    }
    console.log();
  }

  if (violations.hardcodedPx.length > 0) {
    console.log(`📏 HARDCODED PX (${violations.hardcodedPx.length})`);
    violations.hardcodedPx.slice(0, 5).forEach(v => {
      console.log(`  Line ${v.line}: ${v.value}`);
      console.log(`    ${v.text}`);
    });
    if (violations.hardcodedPx.length > 5) {
      console.log(`  ... and ${violations.hardcodedPx.length - 5} more`);
    }
    console.log();
  }

  const total = violations.hexColors.length + violations.rgbColors.length +
                violations.inlineStyles.length + violations.hardcodedPx.length;

  console.log(`📈 TOTAL: ${total} violations`);
}

module.exports = { findFile, analyzeFile };
