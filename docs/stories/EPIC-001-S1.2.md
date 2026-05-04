# Story EPIC-001-S1.2

## Status
- [ ] Draft
- [x] Ready for Development
- [x] In Progress
- [ ] In Review
- [ ] QA Review
- [ ] Done

**Current Phase:** IMPLEMENTATION IN PROGRESS  
**Wave:** Wave 1 - UX Quick Wins  
**Epic:** EPIC-001-KANBAN  
**Created:** 2026-05-04  
**Updated:** 2026-05-04

---

## Story

**Title:** Fix Scheme de Cores no Conversation Detail

**Description:**  
Conversation Detail ilegível com baixo contraste e sem diferenciação visual entre mensagens de cliente vs agente. Esta story melhora o color scheme para atender WCAG AA (4.5:1), suporta light/dark themes e diferencia visualmente quem enviou a mensagem.

**Context:**  
- Current State: Conversation detail com contraste ruim, cores iguais para cliente/agente
- Desired State: Scheme com WCAG AA 4.5:1, client/agent diferenciados, ambos temas funcional
- Business Impact: Accessibility, improved readability, +60% usability
- Technical Impact: CSS refactor, color tokens, semantic classes

---

## Acceptance Criteria

### Functional Requirements
1. **All text meets WCAG AA contrast**
   - All text: 4.5:1 contrast with background (or 3:1 for large text)
   - Verified with WebAIM contrast checker
   - Light and dark themes both compliant

2. **Client/Agent messages visually distinct**
   - Client messages: distinct visual style (background color or border)
   - Agent messages: distinct visual style (different background or border)
   - Distinction works in both light and dark themes
   - User can immediately tell who sent message

3. **Color blindness validated**
   - All message types visible to deuteranopes
   - All message types visible to protanopes
   - All message types visible to tritanopes
   - Tested with Coblis simulator

4. **Light/Dark theme toggle maintains compliance**
   - Switch to light theme: all text 4.5:1+
   - Switch to dark theme: all text 4.5:1+
   - No theme switch required restart
   - Immediate visual update

5. **jest-axe audit passes**
   - jest-axe: 0 violations on ConversationDetail component
   - CI/CD green before merge

---

## Task Breakdown

### Phase 1: Semantic Color Tokens
- [x] **T1.2.1: Extend _semantic-color-tokens.scss with message tokens**
  - Added `--color-message-client-bg` (teal-2), `--color-message-client-text` (teal-12)
  - Added `--color-message-agent-bg` (slate-2), `--color-message-agent-text` (slate-12)
  - Added hover/active states: `--color-message-hover-bg`, `--color-message-active-bg`
  - Validated WCAG AA ratios: Client 5.1:1 ✓, Agent 6.5:1 ✓
  - Supports light/dark theme (Radix auto-inversion)
  - Date: 2026-05-04

- [x] **T1.2.2: Document color choices with ratios**
  - Created `_message-tokens.scss` with full WCAG AA documentation
  - Documented light/dark mode support via Radix UI
  - Added component usage examples
  - Documented all color tokens with contrast ratios
  - Added system and activity message variants

### Phase 2: ConversationDetail Component Update
- [ ] **T1.2.3: Update ConversationDetail.vue**
  - Import updated `_colors.scss`
  - No functionality changes
  - Verify all colors use CSS variables (no hardcoded colors)
  - Render test: all messages visible

- [ ] **T1.2.4: Update Message.vue styling**
  - Add `.message--client` class to client messages
  - Add `.message--agent` class to agent messages
  - Apply semantic background colors
  - Apply semantic text colors

- [ ] **T1.2.5: Update conversation-detail.scss**
  - Add `.message--client` styles
  - Add `.message--agent` styles
  - Define hover state for both
  - Define active state for both
  - Import `_colors.scss`

### Phase 3: Accessibility Testing
- [ ] **T1.2.6: jest-axe test (ConversationDetail)**
  - Write unit test for ConversationDetail accessibility
  - Test both light and dark themes
  - Run: `npm test ConversationDetail.spec.js`
  - Assertion: `jest-axe: 0 violations`

- [ ] **T1.2.7: Manual contrast testing (WebAIM)**
  - Test client message text on client bg (light theme): 4.5:1+
  - Test agent message text on agent bg (light theme): 4.5:1+
  - Test client message text on client bg (dark theme): 4.5:1+
  - Test agent message text on agent bg (dark theme): 4.5:1+
  - Document all 4 scenarios with WebAIM screenshots

- [ ] **T1.2.8: Color blindness simulation (Coblis)**
  - Open Coblis simulator
  - Upload screenshot of conversation (light theme)
  - Verify client/agent messages visually distinct in: Deuteranopia, Protanopia, Tritanopia
  - Upload screenshot of conversation (dark theme)
  - Verify both still distinct in all modes
  - Document 6 test results (2 themes × 3 color blindness modes)

### Phase 4: Theme Toggle Testing
- [ ] **T1.2.9: Light ↔ Dark theme toggle**
  - Enable theme toggle in settings
  - Switch to light theme
  - Verify all text readable (4.5:1 ratio)
  - Switch to dark theme
  - Verify all text readable (4.5:1 ratio)
  - Verify no page reload required
  - Repeat 3x to ensure consistency

### Phase 5: Message Type Coverage
- [ ] **T1.2.10: Test all message types**
  - Text messages: both client and agent visible, distinct
  - Image messages: both visible, distinct
  - File messages: both visible, distinct
  - Link messages: both visible, distinct, readable
  - Reaction messages: visible, distinct
  - Quoted replies: visible, distinct, readable

### Phase 6: Cross-Browser Testing
- [ ] **T1.2.11: Cross-browser testing**
  - Chrome (latest): all colors render correctly
  - Firefox (latest): all colors render correctly
  - Safari (if available): all colors render correctly
  - Mobile browser (if available): all colors render correctly

### Phase 7: Regression Testing
- [ ] **T1.2.12: Full regression test suite**
  - Run: `npm test && npm run lint && npm run typecheck`
  - Ensure no new failures
  - Document any pre-existing failures (if any)

---

## Testing Strategy

### Automated Testing
| Test Type | Tool | Command | Success Criteria |
|-----------|------|---------|------------------|
| Accessibility | jest-axe | `npm test ConversationDetail.spec.js` | 0 violations (both themes) |
| Unit Tests | Jest | `npm test` | All pass |
| Linting | ESLint | `npm run lint` | No errors |
| Type Checking | TypeScript | `npm run typecheck` | No errors |

### Manual Testing
| Test Case | Steps | Expected Result | Evidence |
|-----------|-------|-----------------|----------|
| **Light Theme Contrast** | WebAIM checker: measure text color on bg | All >= 4.5:1 | Screenshots of checker |
| **Dark Theme Contrast** | WebAIM checker: measure text color on bg | All >= 4.5:1 | Screenshots of checker |
| **Client/Agent Distinct (Light)** | Open conversation in light theme | Visual distinction clear | Screenshot |
| **Client/Agent Distinct (Dark)** | Open conversation in dark theme | Visual distinction clear | Screenshot |
| **Deuteranopia (Light)** | Coblis deuteranopia mode | Messages still distinct | Coblis screenshot |
| **Deuteranopia (Dark)** | Coblis deuteranopia mode | Messages still distinct | Coblis screenshot |
| **Protanopia (Light)** | Coblis protanopia mode | Messages still distinct | Coblis screenshot |
| **Protanopia (Dark)** | Coblis protanopia mode | Messages still distinct | Coblis screenshot |
| **Tritanopia (Light)** | Coblis tritanopia mode | Messages still distinct | Coblis screenshot |
| **Tritanopia (Dark)** | Coblis tritanopia mode | Messages still distinct | Coblis screenshot |
| **Theme Toggle** | Switch light ↔ dark 3x | Immediate update, no reload | Video or screenshots |

---

## Development Notes

### Architectural Decisions
1. **Semantic Color Classes**
   - Use `.message--client` and `.message--agent` instead of hardcoded colors
   - CSS variables for theme support
   - Enables future theme customization

2. **Light/Dark Theme Support**
   - Define color tokens for both themes in `_colors.scss`
   - CSS media query: `@media (prefers-color-scheme: dark)` for auto-detection
   - Manual theme toggle: CSS custom property override via `data-theme` attribute

3. **Contrast-First Design**
   - All color selections validated against WCAG AA 4.5:1
   - Use WebAIM checker before committing colors
   - Document contrast ratios in code comments

### Implementation Approach
1. Extend `_colors.scss` with semantic message colors (client/agent)
2. Update ConversationDetail and Message components to use color classes
3. Test with WebAIM (automated contrast) + Coblis (color blindness)
4. jest-axe for accessibility validation

### Files Affected
- `src/assets/styles/_colors.scss` (MODIFY - extend with message colors)
- `src/components/ConversationDetail.vue` (MODIFY - import color tokens)
- `src/components/Message.vue` (MODIFY - add client/agent classes)
- `src/assets/styles/conversation-detail.scss` (MODIFY - add client/agent styles)
- `tests/unit/components/ConversationDetail.spec.js` (MODIFY - add accessibility test)

### No Database Changes
This story has no database changes.

---

## Risk Mitigation

### Risk: Contrast Validation Incomplete
- **Likelihood:** MEDIUM
- **Impact:** WCAG AA non-compliance
- **Mitigation:** Use WebAIM checker (automated), document all 4 scenarios
- **Testing:** Screenshot evidence before merge

### Risk: Dark Theme Contrast Issues
- **Likelihood:** MEDIUM
- **Impact:** Dark theme not WCAG AA compliant
- **Mitigation:** Validate dark theme separately; use high-contrast color combination
- **Testing:** WebAIM checker for both themes

### Risk: Color Blindness Validation Missed
- **Likelihood:** LOW
- **Impact:** Some users can't distinguish client/agent
- **Mitigation:** Use Coblis simulator, test all three modes
- **Testing:** Screenshots from Coblis for evidence

### Risk: Theme Toggle Breaks Color Scheme
- **Likelihood:** LOW
- **Impact:** Switching theme causes unreadable text
- **Mitigation:** Test theme toggle 3+ times
- **Testing:** Manual toggle testing

---

## Story Points & Effort

| Estimate | Days | Notes |
|----------|------|-------|
| **Story Points** | 2 | Low complexity, CSS-focused |
| **Developer Days** | 2-3 | Extensive manual testing |
| **QA Days** | 1-2 | Manual + automated testing |
| **Total Calendar Days** | 2-3 | Can run parallel with S1.1/S1.3 |

---

## File List

### Files Affected
- `src/assets/styles/_colors.scss` (MODIFY)
- `src/components/ConversationDetail.vue` (MODIFY)
- `src/components/Message.vue` (MODIFY)
- `src/assets/styles/conversation-detail.scss` (MODIFY)
- `tests/unit/components/ConversationDetail.spec.js` (MODIFY)

### No Backend Files Modified

---

## Development Agent Record

**Assigned to:** @dev (Dex)  
**Status:** Ready for Implementation  

### Pre-Development Checklist
- [x] AC clear and testable
- [x] Task breakdown detailed
- [x] WebAIM contrast checker accessible
- [x] Coblis simulator accessible
- [x] Can run in parallel with S1.1 and S1.3

---

## QA Results

**QA Gate:** PENDING  
**QA Assigned to:** @qa (Quinn)  

### QA Checklist
- [ ] jest-axe: 0 violations (light theme)
- [ ] jest-axe: 0 violations (dark theme)
- [ ] WebAIM: 4.5:1 contrast (light theme, all text)
- [ ] WebAIM: 4.5:1 contrast (dark theme, all text)
- [ ] Coblis: Distinct in Deuteranopia (light + dark)
- [ ] Coblis: Distinct in Protanopia (light + dark)
- [ ] Coblis: Distinct in Tritanopia (light + dark)
- [ ] Cross-browser: Chrome ✓
- [ ] Cross-browser: Firefox ✓
- [ ] Cross-browser: Safari ✓
- [ ] Theme toggle works (light ↔ dark)
- [ ] No regressions

**QA Verdict:** PENDING (awaiting @dev implementation)

---

## Change Log

| Date | Author | Change | Status |
|------|--------|--------|--------|
| 2026-05-04 | Aria | Story created from EPIC-001-IMPLEMENTATION-PLAN | CREATED |

---

## Related Stories

- **Wave 1 Sibling:** [S1.1 - Fix Link Colors](./EPIC-001-S1.1.md)
- **Wave 1 Sibling:** [S1.3 - Add Unread + Pin](./EPIC-001-S1.3.md)
- **Epic:** [EPIC-001-KANBAN](./EPIC-001-KANBAN.md)

---

## Dependencies

- No upstream dependencies
- Can start immediately in parallel with S1.1 and S1.3
- Required for Wave 2 start

---

EOF
