// ═══════════════════════════════════════════════════════════════════════════
// TOKEN EXPORTER — Design System Token Export Utilities
// ═══════════════════════════════════════════════════════════════════════════
//
// Extracts CSS custom properties from stylesheets and exports them in
// various formats: JSON, YAML, Figma-compatible, and documentation.
//
// Usage:
//   const exporter = new TokenExporter();
//   const tokens = exporter.extractAllTokens();
//   exporter.exportJSON('tokens.json');
//   exporter.exportYAML('tokens.yaml');
//   exporter.generateFigmaTokens();
//
// ═══════════════════════════════════════════════════════════════════════════

export class TokenExporter {
  constructor() {
    this.tokens = {};
    this.categories = {
      color: [],
      spacing: [],
      typography: [],
      shadow: [],
      zIndex: [],
      semantic: [],
    };
  }

  // Extracts all CSS custom properties from stylesheets
  extractAllTokens() {
    const root = document.documentElement;
    const styles = getComputedStyle(root);

    // Extract all custom properties
    Array.from(styles).forEach(prop => {
      if (prop.startsWith('--')) {
        const value = styles.getPropertyValue(prop).trim();
        this.tokens[prop] = value;
        this.categorizeToken(prop, value);
      }
    });

    return this.tokens;
  }

  // Categorizes tokens by type
  categorizeToken(property, value) {
    const prop = property.toLowerCase();

    if (prop.includes('color') || prop.includes('-[0-9]')) {
      this.categories.color.push({ property, value });
    } else if (
      prop.includes('space') ||
      prop.includes('padding') ||
      prop.includes('margin') ||
      prop.includes('gap')
    ) {
      this.categories.spacing.push({ property, value });
    } else if (
      prop.includes('font') ||
      prop.includes('line-height') ||
      prop.includes('letter-spacing')
    ) {
      this.categories.typography.push({ property, value });
    } else if (prop.includes('shadow') || prop.includes('elevation')) {
      this.categories.shadow.push({ property, value });
    } else if (prop.includes('z-') || prop.includes('z_')) {
      this.categories.zIndex.push({ property, value });
    } else if (
      prop.includes('color-button') ||
      prop.includes('color-input') ||
      prop.includes('color-label')
    ) {
      this.categories.semantic.push({ property, value });
    }
  }

  // Exports tokens as JSON
  exportJSON() {
    return JSON.stringify(
      {
        tokens: this.tokens,
        categories: this.categories,
        metadata: {
          exportDate: new Date().toISOString(),
          version: '1.0',
          format: 'json',
        },
      },
      null,
      2
    );
  }

  // Exports tokens as YAML format (for manual YAML file creation)
  exportYAML() {
    let yaml = '# Design System Tokens - YAML Export\n';
    yaml += `# Generated: ${new Date().toISOString()}\n\n`;
    yaml += 'tokens:\n';

    Object.entries(this.tokens).forEach(([key, value]) => {
      yaml += `  ${key}: "${value}"\n`;
    });

    yaml += '\ncategories:\n';
    Object.entries(this.categories).forEach(([category, tokens]) => {
      yaml += `  ${category}:\n`;
      tokens.forEach(({ property, value }) => {
        yaml += `    - property: ${property}\n`;
        yaml += `      value: "${value}"\n`;
      });
    });

    return yaml;
  }

  // Exports tokens in Figma Tokens format
  exportFigmaTokens() {
    const figmaFormat = {
      global: {},
      light: {},
      dark: {},
    };

    // Organize tokens for Figma
    this.categories.color.forEach(({ property, value }) => {
      const name = property.replace(/^--/, '').replace(/-/g, '/');
      figmaFormat.global[name] = {
        value,
        type: 'color',
      };
    });

    this.categories.spacing.forEach(({ property, value }) => {
      const name = property.replace(/^--/, '').replace(/-/g, '/');
      figmaFormat.global[name] = {
        value,
        type: 'sizing',
      };
    });

    this.categories.typography.forEach(({ property, value }) => {
      const name = property.replace(/^--/, '').replace(/-/g, '/');
      figmaFormat.global[name] = {
        value,
        type: 'typography',
      };
    });

    this.categories.shadow.forEach(({ property, value }) => {
      const name = property.replace(/^--/, '').replace(/-/g, '/');
      figmaFormat.global[name] = {
        value,
        type: 'boxShadow',
      };
    });

    return JSON.stringify(figmaFormat, null, 2);
  }

  // Generates Figma tokens plugin JSON
  generateFigmaTokensPlugin() {
    return {
      version: '1.0',
      $themes: [],
      $metadata: {
        tokenSetOrder: ['global'],
      },
      global: this.buildFigmaTokenSet(),
    };
  }

  // Builds token set for Figma format
  buildFigmaTokenSet() {
    // Color tokens
    const colors = {};
    this.categories.color.forEach(({ property, value }) => {
      const name = property.replace(/^--/, '').replace(/-/g, '/');
      colors[name] = {
        value,
        type: 'color',
      };
    });

    // Spacing tokens
    const spacing = {};
    this.categories.spacing.forEach(({ property, value }) => {
      const name = property.replace(/^--/, '').replace(/-/g, '/');
      spacing[name] = {
        value,
        type: 'sizing',
      };
    });

    // Typography tokens
    const typography = {};
    this.categories.typography.forEach(({ property, value }) => {
      const name = property.replace(/^--/, '').replace(/-/g, '/');
      typography[name] = {
        value,
        type: 'typography',
      };
    });

    return {
      ...colors,
      ...spacing,
      ...typography,
    };
  }

  // Generates comprehensive design system documentation
  generateDocumentation() {
    let doc = '# Design System Token Reference\n\n';
    doc += `Generated: ${new Date().toISOString()}\n\n`;

    // Color tokens documentation
    doc += '## Color Tokens\n\n';
    this.categories.color.forEach(({ property, value }) => {
      doc += `- \`${property}\` → \`${value}\`\n`;
    });

    // Spacing tokens documentation
    doc += '\n## Spacing Tokens\n\n';
    this.categories.spacing.forEach(({ property, value }) => {
      doc += `- \`${property}\` → \`${value}\`\n`;
    });

    // Typography tokens documentation
    doc += '\n## Typography Tokens\n\n';
    this.categories.typography.forEach(({ property, value }) => {
      doc += `- \`${property}\` → \`${value}\`\n`;
    });

    // Shadow tokens documentation
    doc += '\n## Shadow Tokens\n\n';
    this.categories.shadow.forEach(({ property, value }) => {
      doc += `- \`${property}\` → \`${value}\`\n`;
    });

    // Z-Index tokens documentation
    doc += '\n## Z-Index Tokens\n\n';
    this.categories.zIndex.forEach(({ property, value }) => {
      doc += `- \`${property}\` → \`${value}\`\n`;
    });

    // Semantic color tokens documentation
    doc += '\n## Semantic Color Tokens\n\n';
    this.categories.semantic.forEach(({ property, value }) => {
      doc += `- \`${property}\` → \`${value}\`\n`;
    });

    return doc;
  }

  // Counts tokens by category
  getTokenStats() {
    return {
      total: Object.keys(this.tokens).length,
      colors: this.categories.color.length,
      spacing: this.categories.spacing.length,
      typography: this.categories.typography.length,
      shadows: this.categories.shadow.length,
      zIndex: this.categories.zIndex.length,
      semantic: this.categories.semantic.length,
    };
  }

  // Validates token naming conventions
  validateTokenNames() {
    const violations = [];

    Object.keys(this.tokens).forEach(token => {
      // Check if token follows naming convention
      if (!token.startsWith('--')) {
        violations.push({
          token,
          issue: 'Does not start with --',
        });
      }

      // Check for camelCase (should be kebab-case)
      if (/[A-Z]/.test(token)) {
        violations.push({
          token,
          issue: 'Uses camelCase instead of kebab-case',
        });
      }

      // Check for spaces
      if (token.includes(' ')) {
        violations.push({
          token,
          issue: 'Contains spaces',
        });
      }
    });

    return violations;
  }
}

export default TokenExporter;
