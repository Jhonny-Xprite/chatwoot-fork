# Design System Token Adoption Roadmap

## Executive Summary

**Current Status:** 84.1% adoption rate (789/939 components)

- ✅ **535 (57%)** - Full adoption (no violations)
- 🟡 **254 (27%)** - Partial adoption (mix of tokens + violations)  
- ❌ **150 (16%)** - No adoption (using hardcoded values)

**Goal:** Reach 100% adoption across all components

---

## Phase 1: Zero-Adoption Components (16% → 0%)

### What needs to happen
Migrate the 150 components with ZERO token adoption to use design system tokens.

### High-Priority Components (>= 12 violations)

```
1.  Avatar.vue (27 violations) - ANALYZED ✓
2.  File.vue (23 violations)
3.  ExclusionRules.story.vue (17 violations)
4.  ShareModal.vue (17 violations)
5.  Label.vue (16 violations)
6.  Button.story.vue (15 violations)
7.  ViewCustomizer.vue (14 violations)
8.  commandbar.vue (14 violations)
9.  Guardrails.vue (13 violations)
10. ResponseGuidelines.vue (13 violations)
11. Scenarios.vue (13 violations)
12. Settings.vue (13 violations) - Multiple instances
13. ConversationCard.story.vue (13 violations)
14. PipelineEntitySelector.vue (12 violations)
15. ... (135 more components with < 12 violations)
```

### Tools Available

```bash
# Analyze specific component
node bin/detail-violations.js <component-name>

# Auto-migrate (dry-run)
node bin/auto-migrate-tokens.js --dry-run --verbose

# Auto-migrate (apply)
node bin/auto-migrate-tokens.js --fix --verbose

# Get detailed analysis
cat .component-token-analysis.json | jq '.components[] | select(.adoptionLevel == "none")'
```

### Common Violation Patterns

| Pattern | Example | Migration |
|---------|---------|-----------|
| Hardcoded colors | `backgroundColor: '#ffffff'` | → `var(--n-slate-0)` |
| Hardcoded spacing | `padding: '16px'` | → `class="p-4"` |
| Inline styles | `style="color: #333"` | → use Tailwind + tokens |
| RGB colors | `rgb(100, 100, 100)` | → identify closest token |

---

## Phase 2: Partial Adoption Components (27% → 0%)

### What needs to happen
Complete the migration for 254 components with mixed token/violation usage.

### Approach
1. Run `node bin/detail-violations.js <component>` to see specific issues
2. Replace violations with tokens
3. Consolidate all styling to use design system

### Expected Effort
- Most have only 5-10 violations each
- Auto-migration tool can handle many cases
- Manual review needed for edge cases

---

## Phase 3: Validation & Testing

### Quality Checks
- [ ] ESLint passes: `npm run eslint`
- [ ] No console warnings in browser
- [ ] Visual regression tests pass
- [ ] Component stories render correctly

### Commit Strategy
- Create focused commits per component or small batches
- Reference this roadmap in commit messages
- Use: `feat(design-system): migrate {component} to tokens [Roadmap Phase 1]`

---

## Adoption Metrics by Component Type

| Type | Total | Full | Partial | None | Adoption % |
|------|-------|------|---------|------|------------|
| component | 95 | 57 | 22 | 16 | 83.2% |
| widget | 101 | 63 | 23 | 15 | 85.1% |
| next-gen | 411 | 192 | 165 | 54 | 86.9% |
| page | 332 | 223 | 44 | 65 | 80.4% |

### Recommendation
Focus Phase 1 on `page` components (80.4% adoption) - they have more room for improvement.

---

## Token Violation Summary

Total instances to fix: 771

```
inlineStyles        554 (71.8%)
hexColors           125 (16.2%)
hardcodedPx         83  (10.8%)
rgbColors           9   (1.2%)
```

**Priority Order:**
1. **Inline Styles** (554) - Highest count, biggest impact
2. **Hex Colors** (125) - Create color token mapping
3. **Hardcoded Px** (83) - Map to spacing tokens
4. **RGB Colors** (9) - Edge cases, manual review

---

## Implementation Timeline

### Week 1: High Priority (>= 12 violations)
- [ ] Migrate Avatar.vue
- [ ] Migrate File.vue  
- [ ] Migrate top 15 components
- [ ] Iterate with auto-migration tool
- **Target:** 15 components → 0 violations

### Week 2: Medium Priority (5-11 violations)
- [ ] Auto-migrate batch groups
- [ ] Manual review problem cases
- [ ] Test in browser
- **Target:** 50+ components → full adoption

### Week 3: Low Priority + Validation
- [ ] Migrate remaining zero-adoption components
- [ ] Fix all partial adoption violations
- [ ] Comprehensive testing
- **Target:** 100% adoption

---

## Resources

- **Token Reference:** [DESIGN-SYSTEM-GUIDELINES.md](./app/javascript/dashboard/assets/scss/DESIGN-SYSTEM-GUIDELINES.md)
- **Token Analyzer:** `node bin/analyze-component-tokens.js --export`
- **Violation Scanner:** `node bin/detail-violations.js <component>`
- **Auto-Migrator:** `node bin/auto-migrate-tokens.js --fix`
- **Analysis Data:** `.component-token-analysis.json`

---

## Success Criteria

- [ ] **0 violations** in 150 zero-adoption components
- [ ] **0 violations** in 254 partial-adoption components
- [ ] **100% adoption rate** (939/939 components)
- [ ] All linting passes: `npm run eslint`
- [ ] All tests pass: `npm test`
- [ ] Visual regression tests pass
- [ ] No breaking changes in component APIs

---

## Notes

### False Positives
Some "violations" detected are actually valid patterns:
- Dynamic styles (`:style="computed_style"`) - These are legitimate
- Colors in configuration objects - Needed for logic
- Comments mentioning px values - Not actual code

### Manual Review Needed For
- Components with computed/dynamic colors
- Components using CSS-in-JS or v-bind styles
- Story/demo components with special styling

### Quick Wins
- Simple color replacements: ~100 instances
- Basic inline style removals: ~150 instances
- Spacing class additions: ~50 instances

---

## Next Steps

1. **Start Phase 1:** Pick top 5 components from HIGH priority list
2. **Run analysis:** `node bin/detail-violations.js Avatar.vue`
3. **Auto-migrate:** `node bin/auto-migrate-tokens.js --dry-run` (review results)
4. **Manual review:** Fix edge cases
5. **Test:** `npm run eslint && npm test`
6. **Iterate:** Process next batch

---

**Last Updated:** 2026-05-03  
**Status:** Ready for execution  
**Ownership:** Design System Team
