#!/usr/bin/env node

// ═══════════════════════════════════════════════════════════════════════════
// COMPONENT TOKEN USAGE ANALYZER
// ═══════════════════════════════════════════════════════════════════════════
//
// Analyzes Vue components to determine:
// • Which components use design system tokens
// • Which components need migration to tokens
// • Token adoption rate and patterns
// • Migration priority and effort
//
// Usage:
//   node bin/analyze-component-tokens.js
//   node bin/analyze-component-tokens.js --verbose
//   node bin/analyze-component-tokens.js --export
//
// ═══════════════════════════════════════════════════════════════════════════

const fs = require('fs');
const path = require('path');

class ComponentTokenAnalyzer {
  constructor(options = {}) {
    this.options = {
      verbose: options.verbose || false,
      export: options.export || false,
      ...options,
    };

    this.components = [];
    this.analysis = {
      totalComponents: 0,
      tokenAdoption: {
        full: [],
        partial: [],
        none: [],
      },
      patterns: {},
      violations: {},
    };

    this.patterns = {
      // Token usage patterns
      cssVariable: /var\(--[\w-]+\)/g,
      tailwindClass: /class="[^"]*(?:p-|m-|gap-|text-|shadow-|z-|bg-|border-)[^"]*"/g,
      semanticColor: /var\(--color-[\w-]+\)/g,
      dynamicColor: /getColorDotStyle|useColorStyle|getLabelBackgroundStyle/g,

      // Violation patterns
      hexColor: /#[0-9a-fA-F]{3}(?:[0-9a-fA-F]{3})?\b/g,
      rgbColor: /rgba?\s*\(\s*\d+\s*,\s*\d+\s*,\s*\d+[^)]*\)/gi,
      inlineStyle: /style\s*=\s*['"]\{?[^'"]*backgroundColor|color|padding|margin[^'"]*['"]/g,
      hardcodedPx: /['"]\d+px['"]/g,
    };

    this.targetPatterns = [
      'app/javascript/dashboard/components/**/*.vue',
      'app/javascript/dashboard/components-next/**/*.vue',
      'app/javascript/dashboard/routes/**/*.vue',
    ];

    this.excludePatterns = [
      '**/node_modules/**',
      '**/dist/**',
      '**/build/**',
      '**/.git/**',
    ];
  }

  // Analyzes all components
  analyze() {
    console.log('🔍 Analyzing component token usage...\n');

    const files = this.findComponents();
    console.log(`Found ${files.length} components\n`);

    files.forEach((file, index) => {
      if (this.options.verbose) {
        console.log(`[${index + 1}/${files.length}] ${file}`);
      }
      this.analyzeComponent(file);
    });

    this.generateReport();
    return this.analysis;
  }

  // Finds all Vue component files recursively
  findComponents() {
    const files = [];
    const basePath = 'app/javascript/dashboard';

    const excludePaths = [
      'node_modules',
      'dist',
      'build',
      '.git',
      '.git/',
    ];

    const walkDir = (dir) => {
      try {
        const entries = fs.readdirSync(dir, { withFileTypes: true });

        entries.forEach(entry => {
          const fullPath = path.join(dir, entry.name);
          const relativePath = path.relative(process.cwd(), fullPath);

          // Skip excluded paths
          if (excludePaths.some(ex => relativePath.includes(ex))) {
            return;
          }

          if (entry.isDirectory()) {
            walkDir(fullPath);
          } else if (entry.isFile() && entry.name.endsWith('.vue')) {
            files.push(relativePath);
          }
        });
      } catch (err) {
        // Skip directories we can't read
      }
    };

    walkDir(basePath);
    return [...new Set(files)];
  }

  // Analyzes a single component
  analyzeComponent(filePath) {
    try {
      const content = fs.readFileSync(filePath, 'utf8');
      const filename = path.basename(filePath);

      const componentAnalysis = {
        file: filePath,
        filename: filename,
        type: this.getComponentType(filePath),
        size: content.length,
        lines: content.split('\n').length,
        tokenUsage: this.analyzeTokenUsage(content),
        violations: this.analyzeViolations(content),
        patterns: this.extractPatterns(content),
        adoptionLevel: 'none',
        migrationEffort: 'low',
      };

      // Determine adoption level
      const totalViolations = Object.keys(componentAnalysis.violations).reduce(
        (sum, key) => sum + componentAnalysis.violations[key].count,
        0
      );
      const tokenReferences = componentAnalysis.tokenUsage.cssVariables +
        componentAnalysis.tokenUsage.tailwindClasses +
        componentAnalysis.tokenUsage.semanticColors;

      if (tokenReferences > 0 && totalViolations === 0) {
        componentAnalysis.adoptionLevel = 'full';
      } else if (tokenReferences > 0 && totalViolations > 0) {
        componentAnalysis.adoptionLevel = 'partial';
      } else {
        componentAnalysis.adoptionLevel = 'none';
      }

      // Determine migration effort
      if (totalViolations > 10) {
        componentAnalysis.migrationEffort = 'high';
      } else if (totalViolations > 5) {
        componentAnalysis.migrationEffort = 'medium';
      }

      this.components.push(componentAnalysis);
      this.analysis.tokenAdoption[componentAnalysis.adoptionLevel].push(filePath);

      // Track patterns
      if (!this.analysis.patterns[componentAnalysis.type]) {
        this.analysis.patterns[componentAnalysis.type] = {
          total: 0,
          full: 0,
          partial: 0,
          none: 0,
        };
      }
      this.analysis.patterns[componentAnalysis.type].total += 1;
      this.analysis.patterns[componentAnalysis.type][componentAnalysis.adoptionLevel] += 1;
    } catch (error) {
      console.error(`Error analyzing ${filePath}:`, error.message);
    }
  }

  // Analyzes token usage in component
  analyzeTokenUsage(content) {
    return {
      cssVariables: (content.match(this.patterns.cssVariable) || []).length,
      tailwindClasses: (content.match(/class="[^"]*(?:p-|m-|gap-|text-|shadow-|z-|bg-|border-)[^"]*"/g) || []).length,
      semanticColors: (content.match(this.patterns.semanticColor) || []).length,
      dynamicColors: (content.match(this.patterns.dynamicColor) || []).length,
    };
  }

  // Analyzes violations in component
  analyzeViolations(content) {
    return {
      hexColors: {
        count: (content.match(this.patterns.hexColor) || []).length,
        type: 'hardcoded-hex-color',
      },
      rgbColors: {
        count: (content.match(this.patterns.rgbColor) || []).length,
        type: 'hardcoded-rgb-color',
      },
      inlineStyles: {
        count: (content.match(this.patterns.inlineStyle) || []).length,
        type: 'static-inline-style',
      },
      hardcodedPx: {
        count: (content.match(this.patterns.hardcodedPx) || []).length,
        type: 'hardcoded-spacing',
      },
    };
  }

  // Extracts component patterns
  extractPatterns(content) {
    const patterns = {
      usesComposable: content.includes('useColorStyle') || content.includes('useStore'),
      usesComputed: content.includes('computed'),
      usesVModel: content.includes('v-model'),
      hasDarkMode: content.includes('dark:'),
      hasInlineScript: content.includes('<script'),
      hasInlineStyle: content.includes('<style'),
    };

    return patterns;
  }

  // Determines component type
  getComponentType(filePath) {
    if (filePath.includes('components-next')) return 'next-gen';
    if (filePath.includes('routes')) return 'page';
    if (filePath.includes('widgets')) return 'widget';
    return 'component';
  }

  // Generates comprehensive report
  generateReport() {
    const report = [];

    report.push('\n📊 COMPONENT TOKEN ADOPTION REPORT');
    report.push('═'.repeat(70));

    // Summary statistics
    report.push('\n📈 SUMMARY');
    report.push('─'.repeat(70));
    const full = this.analysis.tokenAdoption.full.length;
    const partial = this.analysis.tokenAdoption.partial.length;
    const none = this.analysis.tokenAdoption.none.length;
    const total = full + partial + none;

    const adoptionRate = ((full + partial) / total * 100).toFixed(1);
    report.push(`Total Components: ${total}`);
    report.push(`✅ Full Adoption (no violations): ${full} (${(full / total * 100).toFixed(1)}%)`);
    report.push(`🟡 Partial Adoption (has violations): ${partial} (${(partial / total * 100).toFixed(1)}%)`);
    report.push(`❌ No Adoption (no tokens): ${none} (${(none / total * 100).toFixed(1)}%)`);
    report.push(`\n📊 Overall Adoption Rate: ${adoptionRate}%`);

    // Adoption by component type
    report.push('\n📂 ADOPTION BY COMPONENT TYPE');
    report.push('─'.repeat(70));
    Object.entries(this.analysis.patterns).forEach(([type, stats]) => {
      const rate = (stats.full + stats.partial) / stats.total * 100;
      report.push(
        `${type.padEnd(15)} | Total: ${stats.total.toString().padEnd(3)} | ✅ ${stats.full.toString().padEnd(3)} | 🟡 ${stats.partial.toString().padEnd(3)} | ❌ ${stats.none.toString().padEnd(3)} | ${rate.toFixed(1)}% adopted`
      );
    });

    // Priority migration list (high effort, high impact)
    report.push('\n🎯 MIGRATION PRIORITY (High Impact)');
    report.push('─'.repeat(70));
    const violations = this.components
      .filter(c => c.adoptionLevel === 'none' || c.adoptionLevel === 'partial')
      .sort((a, b) => {
        const violationsA = Object.values(a.violations).reduce((sum, v) => sum + v.count, 0);
        const violationsB = Object.values(b.violations).reduce((sum, v) => sum + v.count, 0);
        return violationsB - violationsA;
      })
      .slice(0, 15);

    violations.forEach((comp, idx) => {
      const vCount = Object.values(comp.violations).reduce((sum, v) => sum + v.count, 0);
      report.push(
        `${idx + 1}. [${comp.migrationEffort.toUpperCase()}] ${comp.filename.padEnd(40)} | ${vCount} violations | ${comp.adoptionLevel}`
      );
    });

    // Well-adopted components (examples)
    report.push('\n✨ WELL-ADOPTED COMPONENTS (Examples)');
    report.push('─'.repeat(70));
    const wellAdopted = this.components
      .filter(c => c.adoptionLevel === 'full')
      .slice(0, 10);

    wellAdopted.forEach((comp, idx) => {
      const tokens = comp.tokenUsage.cssVariables +
        comp.tokenUsage.tailwindClasses +
        comp.tokenUsage.semanticColors;
      report.push(`${idx + 1}. ${comp.filename.padEnd(40)} | ${tokens} token references`);
    });

    // Violation summary
    report.push('\n⚠️ VIOLATION SUMMARY');
    report.push('─'.repeat(70));
    const violationSummary = {};
    this.components.forEach(comp => {
      Object.entries(comp.violations).forEach(([key, violation]) => {
        if (!violationSummary[key]) violationSummary[key] = 0;
        violationSummary[key] += violation.count;
      });
    });

    Object.entries(violationSummary)
      .sort((a, b) => b[1] - a[1])
      .forEach(([type, count]) => {
        report.push(`${type.padEnd(30)} | ${count} instances`);
      });

    // Recommendations
    report.push('\n💡 RECOMMENDATIONS');
    report.push('─'.repeat(70));
    report.push('1. Start with "High Effort" components for maximum impact');
    report.push('2. Use components in "Well-Adopted" section as migration templates');
    report.push('3. Run violation detector to get file:line details');
    report.push('4. Consider batch migration of similar component types');
    report.push('5. Update DESIGN-SYSTEM-GUIDELINES with examples from well-adopted');

    const reportText = report.join('\n');
    console.log(reportText);

    if (this.options.export) {
      this.exportAnalysis();
    }
  }

  // Exports analysis as JSON
  exportAnalysis() {
    const exportData = {
      generatedAt: new Date().toISOString(),
      summary: {
        totalComponents: this.components.length,
        fullAdoption: this.analysis.tokenAdoption.full.length,
        partialAdoption: this.analysis.tokenAdoption.partial.length,
        noAdoption: this.analysis.tokenAdoption.none.length,
        adoptionRate: (
          ((this.analysis.tokenAdoption.full.length + this.analysis.tokenAdoption.partial.length) / this.components.length) * 100
        ).toFixed(1),
      },
      patterns: this.analysis.patterns,
      components: this.components,
    };

    const filename = '.component-token-analysis.json';
    fs.writeFileSync(filename, JSON.stringify(exportData, null, 2));
    console.log(`\n📁 Analysis exported to ${filename}`);
  }
}

// CLI execution
if (require.main === module) {
  const args = process.argv.slice(2);
  const options = {
    verbose: args.includes('--verbose'),
    export: args.includes('--export'),
  };

  const analyzer = new ComponentTokenAnalyzer(options);
  analyzer.analyze();
}

module.exports = ComponentTokenAnalyzer;
