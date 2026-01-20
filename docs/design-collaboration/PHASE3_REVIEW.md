# Phase 3 Design System Review

## design-system-architect - Review Findings

**Review Date:** 2026-01-19  
**Files Reviewed:** 6 JS modules, 1 component, 2 CSS files, 4 HTML pages

---

## Token Usage Issues

### Critical: Hardcoded Colors

| File | Line | Issue | Recommended Fix |
|------|------|-------|-----------------|
| `ui.js` | 62 | `rgba(15, 23, 42, 0.8)` loading overlay | Create `--color-overlay` token |
| `components.css` | 58, 91 | `color: white` on buttons | Use `var(--color-text-inverse)` |
| `components.css` | 109, 114 | `rgba(79, 70, 229, 0.1)` ghost button hover | Create `--color-indigo-alpha-10` token |
| `components.css` | 177 | `rgba(79, 70, 229, 0.1)` focus ring | Use alpha token |
| `components.css` | 507 | `rgba(0, 0, 0, 0.6)` modal overlay | Create `--color-backdrop` token |
| `components.css` | 457-473 | Multiple `color: white` on badges | Use `var(--color-text-inverse)` |

### Medium: Hardcoded Spacing

| File | Line | Issue | Recommended Fix |
|------|------|-------|-----------------|
| `components.css` | 33 | `padding: 0.75rem 1.5rem` btn | Use `var(--spacing-3) var(--spacing-6)` |
| `components.css` | 105 | `padding: 0.5rem 1rem` btn-ghost | Use `var(--spacing-2) var(--spacing-4)` |
| `components.css` | 119, 124, 129 | Button size variants | Use spacing tokens |
| `components.css` | 156 | Form input padding | Use spacing tokens |
| `components.css` | 445 | Badge padding | Use `var(--spacing-1) var(--spacing-2)` |

### Medium: Hardcoded Z-Index Values

| File | Line | Value | Recommended Token |
|------|------|-------|-------------------|
| `ui.js` | 17 | `9999` toast container | `--z-toast` |
| `ui.js` | 66 | `10000` loading overlay | `--z-loading` |
| `components.css` | 426 | `10` table header | `--z-sticky` |
| `components.css` | 489 | `9999` modal | `--z-modal` |
| `components.css` | 519 | `1` modal container | `--z-modal-content` |

### Low: Hardcoded Sizes

| File | Line | Issue | Recommendation |
|------|------|-------|----------------|
| `ui.js` | 33-34 | Toast width `250px/400px` | Create toast size tokens |
| `components.css` | 522 | Modal `max-width: 500px` | Already have modal sizes, use consistently |
| `components.css` | 595 | Message `max-width: 80%` | Create message width token |
| `components.css` | 769, 774 | `min-height: 44px` touch targets | Create `--touch-target-min` token |
| `index.html` | 50 | Scrollbar `width: 8px` | Create `--scrollbar-width` token |

---

## Component Consistency

### Pattern Violations

1. **Header Component Not Used in admin.html**
   - `header.js` provides `initHeader()` and `renderHeader()`
   - But `admin.html` has a completely different inline header structure
   - **Impact:** Two different header implementations to maintain

2. **Form Components Not Used**
   - `forms.js` exports `renderForm()` and `renderFormField()`
   - All HTML pages use handwritten form markup
   - **Impact:** Inconsistent form structure, duplicated validation patterns

3. **Modal Implementation Mismatch**
   - `modal.js` provides `createModal()` for dynamic modals
   - `admin.html` has inline static modal HTML
   - Modal close handlers are duplicated in admin.html
   - **Impact:** Two modal patterns, event handler duplication

4. **Toast vs Alert Confusion**
   - `ui.js` uses `.alert` classes for toasts
   - `components.css` has separate `.toast` classes unused
   - **Impact:** Unused CSS, inconsistent naming

### Consistency Wins (Good Patterns)

- Table rendering via `renderTableWithActions()` - used correctly in admin.html
- Skeleton loading via `renderSkeleton()` - used correctly
- Auth utilities (`requireAuth`, `setTokens`) - consistent usage
- API wrapper (`api.get`, `api.post`) - clean abstraction

---

## Missing Abstractions

### High Priority

1. **Page Layout Component**
   ```
   Current: Each HTML page manually sets up body flexbox, containers
   Needed: <cortex-page-layout> or renderPageLayout()
   ```

2. **Auth Form Component**
   ```
   Current: login.html and register.html are 80% identical
   Needed: renderAuthForm({ mode: 'login' | 'register' })
   ```

3. **Section Component**
   ```
   Current: admin.html repeats section structure 3 times
   Needed: renderSection({ title, actions, content })
   ```

4. **Nav Component**
   ```
   Current: Inline nav buttons with manual active state
   Needed: renderNav([{ label, section, active }])
   ```

### Medium Priority

5. **Error Display Abstraction**
   ```
   Current: Mix of inline alerts, toasts, console.error
   Needed: Unified error handling with display strategy
   ```

6. **Loading State Abstraction**
   ```
   Current: renderSkeleton() + showLoading() (different styles)
   Needed: Unified loading strategy per context
   ```

7. **Code Block Component**
   ```
   Current: .code-block in admin.html inline styles
   Needed: Extract to components.css or component
   ```

8. **Icon System**
   ```
   Current: Emoji icons (📋, 👥, 🔑, ⏳)
   Needed: Formal icon tokens or icon component
   ```

### Low Priority

9. **Copy-to-Clipboard Component**
10. **Confirmation Dialog Component** (exists but could be more configurable)
11. **Pill/Chip Component** (for tags, filters)

---

## Architecture Recommendations

### Phase 3 Priorities

#### 1. Create Missing Design Tokens

```css
/* Add to design-tokens.css */

/* Z-Index Scale */
--z-dropdown: 100;
--z-sticky: 200;
--z-modal: 1000;
--z-toast: 1100;
--z-loading: 1200;

/* Alpha Color Variants */
--color-indigo-alpha-5: rgba(79, 70, 229, 0.05);
--color-indigo-alpha-10: rgba(79, 70, 229, 0.1);
--color-indigo-alpha-20: rgba(79, 70, 229, 0.2);

/* Overlay/Backdrop */
--color-backdrop: rgba(0, 0, 0, 0.6);
--color-backdrop-blur: 4px;

/* Touch Targets */
--touch-target-min: 44px;

/* Scrollbar */
--scrollbar-width: 8px;
--scrollbar-thumb: var(--color-bg-tertiary);
--scrollbar-track: var(--color-bg-primary);
```

#### 2. Standardize State Classes

```css
/* Add to components.css */
.is-loading { }
.is-disabled { opacity: 0.6; pointer-events: none; }
.is-active { }
.is-hidden { display: none; }
.is-visible { display: block; }
```

#### 3. Create Layout Primitives

```css
/* Stack - vertical spacing */
.stack { display: flex; flex-direction: column; }
.stack-sm { gap: var(--spacing-2); }
.stack-md { gap: var(--spacing-4); }
.stack-lg { gap: var(--spacing-6); }

/* Cluster - horizontal wrapping */
.cluster { display: flex; flex-wrap: wrap; }
.cluster-sm { gap: var(--spacing-2); }
.cluster-md { gap: var(--spacing-4); }

/* Center - centered content */
.center { display: flex; align-items: center; justify-content: center; }
```

#### 4. Refactor Component Hierarchy

```
static/
├── design-tokens.css          # Tokens only
├── components.css             # Base components
├── layouts.css                # NEW: Layout primitives
├── utilities.css              # NEW: Utility classes
├── js/
│   ├── auth.js               ✓ Keep as-is
│   ├── api.js                ✓ Keep as-is
│   ├── ui.js                 → Refactor toast system
│   ├── forms.js              → Promote usage
│   ├── table.js              ✓ Keep as-is
│   └── modal.js              → Standardize with HTML modals
└── components/
    ├── header.js             → Use everywhere
    ├── section.js            # NEW
    ├── nav.js                # NEW
    └── auth-form.js          # NEW
```

#### 5. Documentation Needs

- Component usage examples
- Token reference sheet
- Pattern library page (living style guide)
- Migration guide for inline styles

---

## Metrics Summary

| Category | Status | Count |
|----------|--------|-------|
| Hardcoded colors | Needs fix | 12 instances |
| Hardcoded spacing | Needs fix | 8 instances |
| Hardcoded z-index | Needs fix | 5 instances |
| Unused components | Needs adoption | 3 (forms, toast CSS, modal CSS) |
| Missing abstractions | High priority | 4 |
| Missing abstractions | Medium priority | 4 |
| Token coverage | Good | ~85% |
| Component reuse | Moderate | ~60% |

---

## Recommended Phase 3 Scope

1. **Token Completion** - Add z-index scale, alpha colors, touch targets
2. **Header Unification** - Migrate admin.html to use header component
3. **Form Component Adoption** - Refactor all forms to use renderFormField()
4. **Layout Primitives** - Add stack, cluster, center utilities
5. **Toast/Alert Consolidation** - Pick one pattern, remove other
6. **Auth Form Extraction** - Create shared component for login/register

**Estimated effort:** 4-6 hours for full Phase 3 implementation
