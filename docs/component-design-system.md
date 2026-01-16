# Cortex Platform: Component Design System

**Version:** 1.0  
**Date:** 2026-01-16  
**Status:** Draft Specification

---

## Table of Contents

1. [Introduction](#introduction)
2. [Design Tokens](#design-tokens)
3. [Component Specifications](#component-specifications)
4. [Implementation Guidelines](#implementation-guidelines)

---

## Introduction

### Purpose

This document specifies a modular, reusable component library for the Cortex platform. Components are designed to be:

- **Framework-agnostic**: Specified in semantic HTML/CSS, portable to React/Vue/native
- **Accessible**: WCAG 2.1 AA compliant with ARIA support
- **Themeable**: Support both light and dark modes
- **Consistent**: Unified visual language across all interfaces

### Design Philosophy

1. **Progressive Enhancement**: Components work without JavaScript, enhanced with it
2. **Semantic HTML**: Proper HTML5 elements for structure and accessibility
3. **Composability**: Small components combine to build complex UIs
4. **State-Driven**: Visual appearance reflects component state clearly

---

## Design Tokens

### Color Palette

```css
/* Primary Colors */
--color-primary-50: #f0f4ff;
--color-primary-100: #e0e7ff;
--color-primary-200: #c7d2fe;
--color-primary-300: #a5b4fc;
--color-primary-400: #818cf8;
--color-primary-500: #667eea;  /* Primary brand */
--color-primary-600: #5568d3;
--color-primary-700: #4c51bf;
--color-primary-800: #434190;
--color-primary-900: #3730a3;

/* Secondary Colors */
--color-secondary-500: #764ba2;  /* Secondary brand */
--color-secondary-gradient: linear-gradient(135deg, #667eea 0%, #764ba2 100%);

/* Semantic Colors */
--color-success-50: #f0fdf4;
--color-success-500: #4caf50;
--color-success-600: #45a049;
--color-success-700: #388e3c;

--color-danger-50: #fef2f2;
--color-danger-500: #f44336;
--color-danger-600: #d32f2f;
--color-danger-700: #c62828;

--color-warning-50: #fffbeb;
--color-warning-500: #fbbf24;
--color-warning-600: #f59e0b;

--color-info-50: #e3f2fd;
--color-info-500: #1976d2;
--color-info-600: #1565c0;

/* Neutral Colors - Light Theme */
--color-neutral-0: #ffffff;
--color-neutral-50: #f9f9f9;
--color-neutral-100: #f5f5f5;
--color-neutral-200: #e0e0e0;
--color-neutral-300: #d0d0d0;
--color-neutral-400: #9e9e9e;
--color-neutral-500: #666666;
--color-neutral-600: #4a4a4a;
--color-neutral-700: #333333;
--color-neutral-800: #1a1a1a;
--color-neutral-900: #0a0a0a;

/* Dark Theme Overrides */
[data-theme="dark"] {
  --color-bg-primary: #1a1a1a;
  --color-bg-secondary: #2a2a2a;
  --color-bg-tertiary: #3a3a3a;
  --color-text-primary: #e0e0e0;
  --color-text-secondary: #b0b0b0;
  --color-border: #3a3a3a;
}

/* Light Theme Defaults */
[data-theme="light"], :root {
  --color-bg-primary: #ffffff;
  --color-bg-secondary: #f5f5f5;
  --color-bg-tertiary: #e0e0e0;
  --color-text-primary: #333333;
  --color-text-secondary: #666666;
  --color-border: #e0e0e0;
}
```

### Typography

```css
/* Font Families */
--font-family-base: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 
                     Oxygen, Ubuntu, Cantarell, sans-serif;
--font-family-mono: 'Courier New', 'Monaco', 'Consolas', monospace;

/* Font Sizes */
--font-size-xs: 0.75rem;    /* 12px */
--font-size-sm: 0.875rem;   /* 14px */
--font-size-base: 1rem;     /* 16px */
--font-size-lg: 1.125rem;   /* 18px */
--font-size-xl: 1.25rem;    /* 20px */
--font-size-2xl: 1.5rem;    /* 24px */
--font-size-3xl: 2rem;      /* 32px */

/* Font Weights */
--font-weight-normal: 400;
--font-weight-medium: 500;
--font-weight-semibold: 600;
--font-weight-bold: 700;

/* Line Heights */
--line-height-tight: 1.3;
--line-height-normal: 1.5;
--line-height-relaxed: 1.6;
```

### Spacing

```css
/* Spacing Scale (rem-based for accessibility) */
--space-xs: 0.25rem;   /* 4px */
--space-sm: 0.5rem;    /* 8px */
--space-md: 0.75rem;   /* 12px */
--space-lg: 1rem;      /* 16px */
--space-xl: 1.5rem;    /* 24px */
--space-2xl: 2rem;     /* 32px */
--space-3xl: 3rem;     /* 48px */
```

### Border Radius

```css
--radius-sm: 4px;
--radius-md: 6px;
--radius-lg: 8px;
--radius-xl: 12px;
--radius-full: 9999px;
```

### Shadows

```css
--shadow-sm: 0 1px 2px rgba(0, 0, 0, 0.05);
--shadow-md: 0 2px 5px rgba(0, 0, 0, 0.05);
--shadow-lg: 0 4px 10px rgba(0, 0, 0, 0.1);
--shadow-xl: 0 10px 30px rgba(0, 0, 0, 0.15);
--shadow-2xl: 0 20px 60px rgba(0, 0, 0, 0.3);
```

### Transitions

```css
--transition-fast: 150ms cubic-bezier(0.4, 0, 0.2, 1);
--transition-base: 200ms cubic-bezier(0.4, 0, 0.2, 1);
--transition-slow: 300ms cubic-bezier(0.4, 0, 0.2, 1);
```

---

## Component Specifications

### 1. Button Component

#### Purpose
Interactive element for user actions with clear visual hierarchy and feedback.

#### Variants

##### 1.1 Primary Button

```html
<button class="btn btn-primary" type="button">
  Primary Action
</button>
```

**Visual Specs:**
- Background: `--color-primary-gradient` or `--color-primary-500`
- Text: white
- Padding: `0.75rem 1.5rem` (12px 24px)
- Border-radius: `--radius-md`
- Font-weight: `--font-weight-semibold`
- Font-size: `--font-size-base`

**States:**
```css
.btn-primary {
  /* Default */
  background: var(--color-primary-500);
  color: white;
  border: none;
  padding: 0.75rem 1.5rem;
  border-radius: var(--radius-md);
  font-size: var(--font-size-base);
  font-weight: var(--font-weight-semibold);
  cursor: pointer;
  transition: all var(--transition-base);
}

.btn-primary:hover {
  background: var(--color-primary-600);
  transform: translateY(-2px);
  box-shadow: var(--shadow-md);
}

.btn-primary:active {
  transform: translateY(0);
  background: var(--color-primary-700);
}

.btn-primary:focus-visible {
  outline: 2px solid var(--color-primary-400);
  outline-offset: 2px;
}

.btn-primary:disabled {
  opacity: 0.6;
  cursor: not-allowed;
  transform: none;
}
```

##### 1.2 Secondary Button

```html
<button class="btn btn-secondary" type="button">
  Secondary Action
</button>
```

**Visual Specs:**
- Background: `--color-bg-secondary`
- Text: `--color-text-primary`
- Border: 1px solid `--color-border`
- Same padding/sizing as primary

**States:**
```css
.btn-secondary {
  background: var(--color-bg-secondary);
  color: var(--color-text-primary);
  border: 1px solid var(--color-border);
  padding: 0.75rem 1.5rem;
  border-radius: var(--radius-md);
  font-size: var(--font-size-base);
  font-weight: var(--font-weight-semibold);
  cursor: pointer;
  transition: all var(--transition-base);
}

.btn-secondary:hover {
  background: var(--color-neutral-200);
  border-color: var(--color-neutral-300);
  transform: translateY(-1px);
}

.btn-secondary:active {
  transform: translateY(0);
  background: var(--color-neutral-300);
}

.btn-secondary:focus-visible {
  outline: 2px solid var(--color-primary-400);
  outline-offset: 2px;
}

.btn-secondary:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}
```

##### 1.3 Danger Button

```html
<button class="btn btn-danger" type="button">
  Delete
</button>
```

**Visual Specs:**
- Background: `--color-danger-500`
- Text: white
- Same structure as primary

**States:**
```css
.btn-danger {
  background: var(--color-danger-500);
  color: white;
  border: none;
  padding: 0.75rem 1.5rem;
  border-radius: var(--radius-md);
  font-size: var(--font-size-base);
  font-weight: var(--font-weight-semibold);
  cursor: pointer;
  transition: all var(--transition-base);
}

.btn-danger:hover {
  background: var(--color-danger-600);
  transform: translateY(-2px);
}

.btn-danger:active {
  transform: translateY(0);
  background: var(--color-danger-700);
}

.btn-danger:focus-visible {
  outline: 2px solid var(--color-danger-300);
  outline-offset: 2px;
}

.btn-danger:disabled {
  opacity: 0.6;
  cursor: not-allowed;
  transform: none;
}
```

##### 1.4 Ghost Button

```html
<button class="btn btn-ghost" type="button">
  Ghost Action
</button>
```

**Visual Specs:**
- Background: transparent
- Text: `--color-primary-500`
- Border: none
- Minimal padding: `0.5rem 1rem`

**States:**
```css
.btn-ghost {
  background: transparent;
  color: var(--color-primary-500);
  border: none;
  padding: 0.5rem 1rem;
  border-radius: var(--radius-md);
  font-size: var(--font-size-base);
  font-weight: var(--font-weight-medium);
  cursor: pointer;
  transition: all var(--transition-base);
}

.btn-ghost:hover {
  background: var(--color-primary-50);
  color: var(--color-primary-600);
}

.btn-ghost:active {
  background: var(--color-primary-100);
}

.btn-ghost:focus-visible {
  outline: 2px solid var(--color-primary-400);
  outline-offset: 2px;
}

.btn-ghost:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

/* Dark theme override */
[data-theme="dark"] .btn-ghost:hover {
  background: rgba(102, 126, 234, 0.1);
}
```

#### Size Variants

```html
<!-- Small -->
<button class="btn btn-primary btn-sm">Small</button>

<!-- Base (default) -->
<button class="btn btn-primary">Base</button>

<!-- Large -->
<button class="btn btn-primary btn-lg">Large</button>
```

```css
.btn-sm {
  padding: 0.5rem 1rem;
  font-size: var(--font-size-sm);
}

.btn-lg {
  padding: 1rem 2rem;
  font-size: var(--font-size-lg);
}
```

#### Icon Buttons

```html
<!-- Icon + Text -->
<button class="btn btn-primary">
  <svg class="btn-icon" aria-hidden="true"><!-- icon --></svg>
  <span>Send Message</span>
</button>

<!-- Icon Only -->
<button class="btn btn-ghost btn-icon-only" aria-label="Close">
  <svg aria-hidden="true"><!-- close icon --></svg>
</button>
```

```css
.btn-icon {
  width: 1.25rem;
  height: 1.25rem;
  margin-right: 0.5rem;
}

.btn-icon-only {
  padding: 0.75rem;
  aspect-ratio: 1;
}
```

#### Accessibility

- **Role**: Native `<button>` element provides implicit role
- **Keyboard**: Activates on Enter and Space
- **Focus**: Clear focus indicator with outline
- **States**: `disabled` attribute prevents interaction
- **Labels**: Use `aria-label` for icon-only buttons
- **Loading**: Add `aria-busy="true"` during async operations

**Loading State:**
```html
<button class="btn btn-primary" aria-busy="true" disabled>
  <span class="spinner" aria-hidden="true"></span>
  <span>Loading...</span>
</button>
```

#### Usage Guidelines

✅ **Do:**
- Use primary for main actions (one per section)
- Use secondary for supporting actions
- Use danger for destructive actions with confirmation
- Keep labels concise (2-4 words)
- Show loading states for async actions

❌ **Don't:**
- Have multiple primary buttons competing
- Use danger without confirmation dialogs
- Disable without explaining why
- Use buttons for navigation (use links instead)

---

### 2. Input Component

#### Purpose
Text input fields for user data entry with validation feedback.

#### Base Structure

```html
<div class="form-group">
  <label for="username" class="form-label">
    Username
    <span class="form-label-optional">(optional)</span>
  </label>
  <input 
    type="text" 
    id="username" 
    name="username"
    class="form-input"
    placeholder="Enter username"
    aria-describedby="username-hint"
  />
  <div id="username-hint" class="form-hint">
    Minimum 3 characters
  </div>
</div>
```

#### Visual Specs

```css
.form-group {
  margin-bottom: var(--space-xl);
}

.form-label {
  display: block;
  margin-bottom: var(--space-sm);
  color: var(--color-text-primary);
  font-weight: var(--font-weight-medium);
  font-size: var(--font-size-sm);
}

.form-label-optional {
  color: var(--color-text-secondary);
  font-weight: var(--font-weight-normal);
  font-size: var(--font-size-xs);
}

.form-input {
  width: 100%;
  padding: 0.75rem;
  border: 2px solid var(--color-border);
  border-radius: var(--radius-md);
  background: var(--color-bg-primary);
  color: var(--color-text-primary);
  font-size: var(--font-size-base);
  font-family: var(--font-family-base);
  transition: border-color var(--transition-base);
}

.form-input::placeholder {
  color: var(--color-text-secondary);
  opacity: 0.7;
}

.form-input:focus {
  outline: none;
  border-color: var(--color-primary-500);
  box-shadow: 0 0 0 3px var(--color-primary-100);
}

.form-input:disabled {
  background: var(--color-bg-secondary);
  cursor: not-allowed;
  opacity: 0.6;
}

.form-hint {
  margin-top: var(--space-sm);
  font-size: var(--font-size-xs);
  color: var(--color-text-secondary);
}
```

#### Validation States

##### Success State

```html
<div class="form-group">
  <label for="email" class="form-label">Email</label>
  <input 
    type="email" 
    id="email"
    class="form-input form-input-success"
    value="user@example.com"
    aria-invalid="false"
    aria-describedby="email-success"
  />
  <div id="email-success" class="form-message form-message-success">
    ✓ Email is available
  </div>
</div>
```

```css
.form-input-success {
  border-color: var(--color-success-500);
}

.form-input-success:focus {
  box-shadow: 0 0 0 3px var(--color-success-50);
}

.form-message-success {
  margin-top: var(--space-sm);
  color: var(--color-success-700);
  font-size: var(--font-size-sm);
  display: flex;
  align-items: center;
  gap: var(--space-sm);
}
```

##### Error State

```html
<div class="form-group">
  <label for="password" class="form-label">Password</label>
  <input 
    type="password" 
    id="password"
    class="form-input form-input-error"
    aria-invalid="true"
    aria-describedby="password-error"
  />
  <div id="password-error" class="form-message form-message-error" role="alert">
    ✕ Password must be at least 8 characters
  </div>
</div>
```

```css
.form-input-error {
  border-color: var(--color-danger-500);
}

.form-input-error:focus {
  box-shadow: 0 0 0 3px var(--color-danger-50);
}

.form-message-error {
  margin-top: var(--space-sm);
  color: var(--color-danger-600);
  font-size: var(--font-size-sm);
  display: flex;
  align-items: center;
  gap: var(--space-sm);
}
```

##### Warning State

```html
<div class="form-group">
  <label for="api-key" class="form-label">API Key</label>
  <input 
    type="text" 
    id="api-key"
    class="form-input form-input-warning"
    aria-describedby="api-key-warning"
  />
  <div id="api-key-warning" class="form-message form-message-warning">
    ⚠ This key will expire in 3 days
  </div>
</div>
```

```css
.form-input-warning {
  border-color: var(--color-warning-500);
}

.form-input-warning:focus {
  box-shadow: 0 0 0 3px var(--color-warning-50);
}

.form-message-warning {
  margin-top: var(--space-sm);
  color: var(--color-warning-600);
  font-size: var(--font-size-sm);
  display: flex;
  align-items: center;
  gap: var(--space-sm);
}
```

#### Input with Icon

```html
<div class="form-group">
  <label for="search" class="form-label">Search</label>
  <div class="form-input-wrapper">
    <svg class="form-input-icon" aria-hidden="true"><!-- search icon --></svg>
    <input 
      type="search" 
      id="search"
      class="form-input form-input-with-icon"
      placeholder="Search..."
    />
  </div>
</div>
```

```css
.form-input-wrapper {
  position: relative;
}

.form-input-icon {
  position: absolute;
  left: 0.75rem;
  top: 50%;
  transform: translateY(-50%);
  width: 1.25rem;
  height: 1.25rem;
  color: var(--color-text-secondary);
  pointer-events: none;
}

.form-input-with-icon {
  padding-left: 2.75rem;
}
```

#### Password Input with Toggle

```html
<div class="form-group">
  <label for="password" class="form-label">Password</label>
  <div class="form-input-wrapper">
    <input 
      type="password" 
      id="password"
      class="form-input form-input-with-action"
      autocomplete="current-password"
    />
    <button 
      type="button" 
      class="form-input-action"
      aria-label="Toggle password visibility"
      aria-pressed="false"
    >
      <svg aria-hidden="true"><!-- eye icon --></svg>
    </button>
  </div>
</div>
```

```css
.form-input-with-action {
  padding-right: 3rem;
}

.form-input-action {
  position: absolute;
  right: 0.5rem;
  top: 50%;
  transform: translateY(-50%);
  background: transparent;
  border: none;
  padding: 0.5rem;
  cursor: pointer;
  color: var(--color-text-secondary);
  border-radius: var(--radius-sm);
  transition: color var(--transition-base);
}

.form-input-action:hover {
  color: var(--color-text-primary);
}

.form-input-action:focus-visible {
  outline: 2px solid var(--color-primary-400);
  outline-offset: 2px;
}
```

#### Accessibility

- **Labels**: Always use `<label>` with `for` attribute
- **Required**: Use `required` attribute + visual indicator
- **Errors**: Use `aria-invalid` and `aria-describedby`
- **Hints**: Use `aria-describedby` to associate hints
- **Autocomplete**: Use appropriate `autocomplete` values
- **Type**: Use semantic input types (email, tel, url, etc.)

#### Usage Guidelines

✅ **Do:**
- Validate on blur, not on every keystroke
- Show success feedback for async validation
- Keep labels short and descriptive
- Use placeholder for examples, not instructions
- Provide clear error messages with solutions

❌ **Don't:**
- Hide labels (use `aria-label` only for icons)
- Use placeholder as label
- Validate too early (frustrates users)
- Use generic error messages like "Invalid input"

---

### 3. Card/Panel Component

#### Purpose
Container component for grouping related content with visual hierarchy.

#### Base Card

```html
<div class="card">
  <div class="card-header">
    <h3 class="card-title">Card Title</h3>
    <button class="btn btn-ghost btn-sm">Action</button>
  </div>
  <div class="card-body">
    <p>Card content goes here</p>
  </div>
  <div class="card-footer">
    <button class="btn btn-secondary">Cancel</button>
    <button class="btn btn-primary">Save</button>
  </div>
</div>
```

#### Visual Specs

```css
.card {
  background: var(--color-bg-primary);
  border-radius: var(--radius-lg);
  box-shadow: var(--shadow-md);
  overflow: hidden;
  transition: box-shadow var(--transition-base);
}

.card:hover {
  box-shadow: var(--shadow-lg);
}

.card-header {
  padding: var(--space-xl);
  border-bottom: 1px solid var(--color-border);
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: var(--space-lg);
}

.card-title {
  font-size: var(--font-size-xl);
  font-weight: var(--font-weight-semibold);
  color: var(--color-text-primary);
  margin: 0;
}

.card-body {
  padding: var(--space-xl);
}

.card-footer {
  padding: var(--space-xl);
  border-top: 1px solid var(--color-border);
  display: flex;
  align-items: center;
  justify-content: flex-end;
  gap: var(--space-md);
}
```

#### Variants

##### Compact Card

```html
<div class="card card-compact">
  <div class="card-body">
    <p>Compact card with no header/footer</p>
  </div>
</div>
```

```css
.card-compact .card-body {
  padding: var(--space-lg);
}
```

##### Interactive Card (Clickable)

```html
<article class="card card-interactive" tabindex="0" role="button">
  <div class="card-body">
    <h4>Notification Title</h4>
    <p>Notification message...</p>
  </div>
</article>
```

```css
.card-interactive {
  cursor: pointer;
  transition: all var(--transition-base);
}

.card-interactive:hover {
  transform: translateY(-2px);
  box-shadow: var(--shadow-xl);
}

.card-interactive:active {
  transform: translateY(0);
}

.card-interactive:focus-visible {
  outline: 2px solid var(--color-primary-400);
  outline-offset: 2px;
}
```

##### Status Card

```html
<div class="card card-status card-status-success">
  <div class="card-status-indicator"></div>
  <div class="card-body">
    <h4>Success</h4>
    <p>Operation completed successfully</p>
  </div>
</div>
```

```css
.card-status {
  position: relative;
  padding-left: calc(var(--space-xl) + 4px);
}

.card-status-indicator {
  position: absolute;
  left: 0;
  top: 0;
  bottom: 0;
  width: 4px;
}

.card-status-success .card-status-indicator {
  background: var(--color-success-500);
}

.card-status-danger .card-status-indicator {
  background: var(--color-danger-500);
}

.card-status-warning .card-status-indicator {
  background: var(--color-warning-500);
}

.card-status-info .card-status-indicator {
  background: var(--color-info-500);
}
```

#### Accessibility

- **Semantic**: Use `<article>` for independent content
- **Headings**: Use proper heading hierarchy in card-title
- **Interactive**: Add `role="button"` and `tabindex="0"` for clickable cards
- **Keyboard**: Implement Enter/Space handlers for interactive cards

#### Usage Guidelines

✅ **Do:**
- Use cards to group related information
- Keep card content focused on one topic
- Use consistent padding within cards
- Consider cards as building blocks

❌ **Don't:**
- Nest cards too deeply (max 2 levels)
- Make every element a card (overuse)
- Put too much content in one card

---

### 4. Toast/Alert Component

#### Purpose
Non-blocking notifications for system feedback and status messages.

#### Toast (Temporary Notification)

```html
<div class="toast toast-success" role="alert" aria-live="polite">
  <div class="toast-icon">
    <svg aria-hidden="true"><!-- success icon --></svg>
  </div>
  <div class="toast-content">
    <div class="toast-title">Success</div>
    <div class="toast-message">Your changes have been saved</div>
  </div>
  <button class="toast-close" aria-label="Close notification">
    <svg aria-hidden="true"><!-- close icon --></svg>
  </button>
</div>
```

#### Visual Specs

```css
.toast {
  display: flex;
  align-items: flex-start;
  gap: var(--space-md);
  min-width: 300px;
  max-width: 500px;
  padding: var(--space-lg);
  background: var(--color-bg-primary);
  border-radius: var(--radius-lg);
  box-shadow: var(--shadow-xl);
  border: 1px solid var(--color-border);
  animation: toast-slide-in var(--transition-base);
}

@keyframes toast-slide-in {
  from {
    transform: translateY(-1rem);
    opacity: 0;
  }
  to {
    transform: translateY(0);
    opacity: 1;
  }
}

.toast-icon {
  flex-shrink: 0;
  width: 1.5rem;
  height: 1.5rem;
}

.toast-content {
  flex: 1;
  min-width: 0;
}

.toast-title {
  font-weight: var(--font-weight-semibold);
  margin-bottom: var(--space-xs);
  color: var(--color-text-primary);
}

.toast-message {
  font-size: var(--font-size-sm);
  color: var(--color-text-secondary);
  line-height: var(--line-height-normal);
}

.toast-close {
  flex-shrink: 0;
  background: transparent;
  border: none;
  padding: var(--space-xs);
  cursor: pointer;
  color: var(--color-text-secondary);
  border-radius: var(--radius-sm);
  transition: color var(--transition-fast);
}

.toast-close:hover {
  color: var(--color-text-primary);
}

.toast-close:focus-visible {
  outline: 2px solid var(--color-primary-400);
  outline-offset: 2px;
}
```

#### Toast Variants

```css
/* Success */
.toast-success {
  border-left: 4px solid var(--color-success-500);
}

.toast-success .toast-icon {
  color: var(--color-success-500);
}

/* Error */
.toast-error {
  border-left: 4px solid var(--color-danger-500);
}

.toast-error .toast-icon {
  color: var(--color-danger-500);
}

/* Warning */
.toast-warning {
  border-left: 4px solid var(--color-warning-500);
}

.toast-warning .toast-icon {
  color: var(--color-warning-600);
}

/* Info */
.toast-info {
  border-left: 4px solid var(--color-info-500);
}

.toast-info .toast-icon {
  color: var(--color-info-500);
}
```

#### Toast Container

```html
<div class="toast-container">
  <!-- Toasts are inserted here -->
</div>
```

```css
.toast-container {
  position: fixed;
  top: var(--space-xl);
  right: var(--space-xl);
  z-index: 9999;
  display: flex;
  flex-direction: column;
  gap: var(--space-md);
  pointer-events: none;
}

.toast-container .toast {
  pointer-events: auto;
}

/* Mobile responsive */
@media (max-width: 640px) {
  .toast-container {
    top: var(--space-lg);
    right: var(--space-lg);
    left: var(--space-lg);
  }
  
  .toast {
    width: 100%;
    max-width: none;
  }
}
```

#### Alert (Persistent Banner)

```html
<div class="alert alert-info" role="alert">
  <div class="alert-icon">
    <svg aria-hidden="true"><!-- info icon --></svg>
  </div>
  <div class="alert-content">
    <div class="alert-title">System Maintenance</div>
    <div class="alert-message">
      The system will be undergoing maintenance on Sunday, 2AM-4AM EST.
    </div>
  </div>
  <button class="alert-close" aria-label="Dismiss alert">
    <svg aria-hidden="true"><!-- close icon --></svg>
  </button>
</div>
```

```css
.alert {
  display: flex;
  align-items: flex-start;
  gap: var(--space-md);
  padding: var(--space-lg);
  border-radius: var(--radius-md);
  margin-bottom: var(--space-lg);
}

.alert-icon {
  flex-shrink: 0;
  width: 1.25rem;
  height: 1.25rem;
}

.alert-content {
  flex: 1;
  min-width: 0;
}

.alert-title {
  font-weight: var(--font-weight-semibold);
  margin-bottom: var(--space-xs);
}

.alert-message {
  font-size: var(--font-size-sm);
  line-height: var(--line-height-normal);
}

.alert-close {
  flex-shrink: 0;
  background: transparent;
  border: none;
  padding: var(--space-xs);
  cursor: pointer;
  border-radius: var(--radius-sm);
  transition: background var(--transition-fast);
}

.alert-close:hover {
  background: rgba(0, 0, 0, 0.05);
}

.alert-close:focus-visible {
  outline: 2px solid currentColor;
  outline-offset: 2px;
}

/* Alert variants */
.alert-success {
  background: var(--color-success-50);
  color: var(--color-success-700);
  border: 1px solid var(--color-success-200);
}

.alert-error {
  background: var(--color-danger-50);
  color: var(--color-danger-700);
  border: 1px solid var(--color-danger-200);
}

.alert-warning {
  background: var(--color-warning-50);
  color: var(--color-warning-700);
  border: 1px solid var(--color-warning-200);
}

.alert-info {
  background: var(--color-info-50);
  color: var(--color-info-600);
  border: 1px solid var(--color-info-200);
}
```

#### Accessibility

- **Role**: Use `role="alert"` for urgent messages
- **Live Region**: Use `aria-live="polite"` for toasts, `aria-live="assertive"` for errors
- **Focus**: Don't steal focus unless critical
- **Timeout**: Auto-dismiss after 5-7 seconds (except errors)
- **Pause**: Pause timeout on hover/focus

#### Usage Guidelines

✅ **Do:**
- Use toasts for non-critical feedback (save, delete, etc.)
- Use alerts for important persistent information
- Keep messages concise (1-2 lines)
- Auto-dismiss success toasts after 5 seconds
- Keep errors visible until dismissed

❌ **Don't:**
- Show multiple toasts at once (queue them)
- Use toasts for critical errors (use modals instead)
- Auto-dismiss error messages
- Show toasts on page load (use alerts)

---

### 5. List/Table Component

#### Purpose
Display structured data in rows and columns with sorting, filtering, and actions.

#### Data Table

```html
<div class="table-wrapper">
  <table class="table">
    <thead>
      <tr>
        <th>
          <button class="table-sort" aria-label="Sort by username">
            Username
            <svg class="table-sort-icon" aria-hidden="true"><!-- sort icon --></svg>
          </button>
        </th>
        <th>Email</th>
        <th>Role</th>
        <th>Status</th>
        <th>Actions</th>
      </tr>
    </thead>
    <tbody>
      <tr>
        <td>john_doe</td>
        <td>john@example.com</td>
        <td><span class="badge badge-admin">Admin</span></td>
        <td><span class="badge badge-active">Active</span></td>
        <td>
          <div class="table-actions">
            <button class="btn btn-ghost btn-sm">Edit</button>
            <button class="btn btn-ghost btn-sm btn-danger">Delete</button>
          </div>
        </td>
      </tr>
      <!-- More rows -->
    </tbody>
  </table>
</div>
```

#### Visual Specs

```css
.table-wrapper {
  overflow-x: auto;
  border-radius: var(--radius-lg);
  border: 1px solid var(--color-border);
}

.table {
  width: 100%;
  border-collapse: collapse;
  background: var(--color-bg-primary);
}

.table th,
.table td {
  text-align: left;
  padding: var(--space-md);
  border-bottom: 1px solid var(--color-border);
}

.table thead th {
  background: var(--color-bg-secondary);
  font-weight: var(--font-weight-semibold);
  color: var(--color-text-secondary);
  font-size: var(--font-size-sm);
  text-transform: uppercase;
  letter-spacing: 0.05em;
  position: sticky;
  top: 0;
  z-index: 10;
}

.table tbody tr {
  transition: background var(--transition-fast);
}

.table tbody tr:hover {
  background: var(--color-bg-secondary);
}

.table tbody tr:last-child td {
  border-bottom: none;
}

/* Sortable headers */
.table-sort {
  background: transparent;
  border: none;
  padding: 0;
  cursor: pointer;
  display: inline-flex;
  align-items: center;
  gap: var(--space-xs);
  color: inherit;
  font: inherit;
  text-transform: inherit;
  letter-spacing: inherit;
}

.table-sort:hover {
  color: var(--color-primary-500);
}

.table-sort-icon {
  width: 1rem;
  height: 1rem;
  opacity: 0.5;
  transition: opacity var(--transition-fast);
}

.table-sort:hover .table-sort-icon,
.table-sort[aria-sort] .table-sort-icon {
  opacity: 1;
}

/* Action buttons in cells */
.table-actions {
  display: flex;
  gap: var(--space-sm);
  align-items: center;
}

/* Responsive */
@media (max-width: 768px) {
  .table th,
  .table td {
    padding: var(--space-sm);
    font-size: var(--font-size-sm);
  }
}
```

#### Simple List

```html
<ul class="list">
  <li class="list-item">
    <div class="list-item-content">
      <div class="list-item-title">Notification Title</div>
      <div class="list-item-subtitle">2 hours ago</div>
    </div>
    <button class="btn btn-ghost btn-sm">Mark Read</button>
  </li>
  <!-- More items -->
</ul>
```

```css
.list {
  list-style: none;
  padding: 0;
  margin: 0;
}

.list-item {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: var(--space-lg);
  padding: var(--space-lg);
  border-bottom: 1px solid var(--color-border);
  transition: background var(--transition-fast);
}

.list-item:hover {
  background: var(--color-bg-secondary);
}

.list-item:last-child {
  border-bottom: none;
}

.list-item-content {
  flex: 1;
  min-width: 0;
}

.list-item-title {
  font-weight: var(--font-weight-medium);
  color: var(--color-text-primary);
  margin-bottom: var(--space-xs);
}

.list-item-subtitle {
  font-size: var(--font-size-sm);
  color: var(--color-text-secondary);
}

/* Interactive list item */
.list-item-interactive {
  cursor: pointer;
}

.list-item-interactive:hover {
  background: var(--color-bg-secondary);
}

.list-item-interactive:focus-visible {
  outline: 2px solid var(--color-primary-400);
  outline-offset: -2px;
}
```

#### Badge Component (for status)

```html
<span class="badge badge-success">Active</span>
<span class="badge badge-danger">Inactive</span>
<span class="badge badge-warning">Pending</span>
<span class="badge badge-info">New</span>
```

```css
.badge {
  display: inline-flex;
  align-items: center;
  padding: 0.25rem 0.5rem;
  border-radius: var(--radius-full);
  font-size: var(--font-size-xs);
  font-weight: var(--font-weight-medium);
  line-height: 1;
  white-space: nowrap;
}

.badge-success {
  background: var(--color-success-500);
  color: white;
}

.badge-danger {
  background: var(--color-danger-500);
  color: white;
}

.badge-warning {
  background: var(--color-warning-500);
  color: white;
}

.badge-info {
  background: var(--color-info-500);
  color: white;
}

.badge-neutral {
  background: var(--color-neutral-400);
  color: white;
}

/* Subtle variants */
.badge-subtle {
  background: transparent;
  border: 1px solid currentColor;
}
```

#### Empty State

```html
<div class="table-empty">
  <svg class="table-empty-icon" aria-hidden="true"><!-- empty icon --></svg>
  <div class="table-empty-title">No users found</div>
  <div class="table-empty-message">Create your first user to get started</div>
  <button class="btn btn-primary">Create User</button>
</div>
```

```css
.table-empty {
  padding: var(--space-3xl);
  text-align: center;
}

.table-empty-icon {
  width: 4rem;
  height: 4rem;
  color: var(--color-text-secondary);
  opacity: 0.5;
  margin-bottom: var(--space-lg);
}

.table-empty-title {
  font-size: var(--font-size-lg);
  font-weight: var(--font-weight-semibold);
  color: var(--color-text-primary);
  margin-bottom: var(--space-sm);
}

.table-empty-message {
  color: var(--color-text-secondary);
  margin-bottom: var(--space-xl);
}
```

#### Accessibility

- **Semantic**: Use `<table>`, `<thead>`, `<tbody>` properly
- **Captions**: Use `<caption>` to describe table purpose
- **Sorting**: Use `aria-sort="ascending|descending|none"` on headers
- **Row actions**: Ensure buttons have descriptive labels
- **Keyboard**: Support Tab navigation through interactive elements

#### Usage Guidelines

✅ **Do:**
- Use tables for tabular data only
- Keep column count reasonable (5-7 max)
- Make tables responsive (horizontal scroll on mobile)
- Show empty states with helpful CTAs
- Paginate long lists (50+ items)

❌ **Don't:**
- Use tables for layout
- Hide important data on mobile
- Make entire rows clickable without indication
- Show too many actions per row (3 max)

---

### 6. Modal/Dialog Component

#### Purpose
Focused overlay for important actions requiring user attention.

#### Base Modal

```html
<div class="modal" role="dialog" aria-modal="true" aria-labelledby="modal-title">
  <div class="modal-overlay" data-close-modal></div>
  <div class="modal-container">
    <div class="modal-header">
      <h2 id="modal-title" class="modal-title">Confirm Action</h2>
      <button class="modal-close" aria-label="Close dialog" data-close-modal>
        <svg aria-hidden="true"><!-- close icon --></svg>
      </button>
    </div>
    <div class="modal-body">
      <p>Are you sure you want to proceed with this action?</p>
    </div>
    <div class="modal-footer">
      <button class="btn btn-secondary" data-close-modal>Cancel</button>
      <button class="btn btn-primary">Confirm</button>
    </div>
  </div>
</div>
```

#### Visual Specs

```css
.modal {
  position: fixed;
  inset: 0;
  z-index: 9999;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: var(--space-lg);
  
  /* Hidden by default */
  opacity: 0;
  pointer-events: none;
  transition: opacity var(--transition-base);
}

.modal.is-open {
  opacity: 1;
  pointer-events: auto;
}

.modal-overlay {
  position: fixed;
  inset: 0;
  background: rgba(0, 0, 0, 0.6);
  backdrop-filter: blur(4px);
  animation: modal-fade-in var(--transition-base);
}

@keyframes modal-fade-in {
  from { opacity: 0; }
  to { opacity: 1; }
}

.modal-container {
  position: relative;
  z-index: 1;
  background: var(--color-bg-primary);
  border-radius: var(--radius-xl);
  max-width: 500px;
  width: 100%;
  max-height: 90vh;
  overflow: hidden;
  display: flex;
  flex-direction: column;
  box-shadow: var(--shadow-2xl);
  animation: modal-scale-in var(--transition-base);
}

@keyframes modal-scale-in {
  from {
    transform: scale(0.95);
    opacity: 0;
  }
  to {
    transform: scale(1);
    opacity: 1;
  }
}

.modal-header {
  padding: var(--space-xl);
  border-bottom: 1px solid var(--color-border);
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: var(--space-lg);
}

.modal-title {
  font-size: var(--font-size-xl);
  font-weight: var(--font-weight-semibold);
  color: var(--color-text-primary);
  margin: 0;
}

.modal-close {
  flex-shrink: 0;
  background: transparent;
  border: none;
  padding: var(--space-sm);
  cursor: pointer;
  color: var(--color-text-secondary);
  border-radius: var(--radius-sm);
  transition: all var(--transition-fast);
}

.modal-close:hover {
  color: var(--color-text-primary);
  background: var(--color-bg-secondary);
}

.modal-close:focus-visible {
  outline: 2px solid var(--color-primary-400);
  outline-offset: 2px;
}

.modal-body {
  padding: var(--space-xl);
  overflow-y: auto;
  flex: 1;
}

.modal-footer {
  padding: var(--space-xl);
  border-top: 1px solid var(--color-border);
  display: flex;
  align-items: center;
  justify-content: flex-end;
  gap: var(--space-md);
}

/* Responsive */
@media (max-width: 640px) {
  .modal-container {
    max-width: 100%;
    max-height: 100%;
    border-radius: 0;
  }
}
```

#### Confirmation Modal (Danger)

```html
<div class="modal" role="dialog" aria-modal="true" aria-labelledby="confirm-title">
  <div class="modal-overlay" data-close-modal></div>
  <div class="modal-container">
    <div class="modal-header modal-header-danger">
      <h2 id="confirm-title" class="modal-title">Delete User?</h2>
      <button class="modal-close" aria-label="Close" data-close-modal>
        <svg aria-hidden="true"><!-- close --></svg>
      </button>
    </div>
    <div class="modal-body">
      <p>This action cannot be undone. This will permanently delete the user account and all associated data.</p>
    </div>
    <div class="modal-footer">
      <button class="btn btn-secondary" data-close-modal>Cancel</button>
      <button class="btn btn-danger">Delete User</button>
    </div>
  </div>
</div>
```

```css
.modal-header-danger {
  background: var(--color-danger-50);
  border-color: var(--color-danger-200);
}

.modal-header-danger .modal-title {
  color: var(--color-danger-700);
}
```

#### Form Modal

```html
<div class="modal modal-form" role="dialog" aria-modal="true" aria-labelledby="form-title">
  <div class="modal-overlay" data-close-modal></div>
  <div class="modal-container">
    <form>
      <div class="modal-header">
        <h2 id="form-title" class="modal-title">Create User</h2>
        <button type="button" class="modal-close" aria-label="Close" data-close-modal>
          <svg aria-hidden="true"><!-- close --></svg>
        </button>
      </div>
      <div class="modal-body">
        <div class="form-group">
          <label for="username" class="form-label">Username</label>
          <input type="text" id="username" class="form-input" required>
        </div>
        <div class="form-group">
          <label for="email" class="form-label">Email</label>
          <input type="email" id="email" class="form-input">
        </div>
      </div>
      <div class="modal-footer">
        <button type="button" class="btn btn-secondary" data-close-modal>Cancel</button>
        <button type="submit" class="btn btn-primary">Create</button>
      </div>
    </form>
  </div>
</div>
```

#### Accessibility

- **Role**: Use `role="dialog"` and `aria-modal="true"`
- **Label**: Use `aria-labelledby` pointing to title
- **Focus**: Trap focus within modal when open
- **Escape**: Close on Escape key
- **Return Focus**: Return focus to trigger element on close
- **Overlay**: Close on overlay click (optional for critical actions)

**JavaScript Requirements:**
```javascript
// Focus trap
const modal = document.querySelector('.modal');
const focusableElements = modal.querySelectorAll(
  'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])'
);
const firstFocusable = focusableElements[0];
const lastFocusable = focusableElements[focusableElements.length - 1];

// Trap focus within modal
modal.addEventListener('keydown', (e) => {
  if (e.key === 'Tab') {
    if (e.shiftKey && document.activeElement === firstFocusable) {
      e.preventDefault();
      lastFocusable.focus();
    } else if (!e.shiftKey && document.activeElement === lastFocusable) {
      e.preventDefault();
      firstFocusable.focus();
    }
  } else if (e.key === 'Escape') {
    closeModal();
  }
});

// Prevent body scroll when modal is open
document.body.style.overflow = 'hidden';
```

#### Usage Guidelines

✅ **Do:**
- Use for critical actions requiring confirmation
- Keep content focused and concise
- Provide clear primary and secondary actions
- Close on Escape key
- Return focus to trigger element

❌ **Don't:**
- Stack multiple modals
- Show modals on page load (use alerts)
- Make modals too large (use pages instead)
- Use for non-critical information (use toasts)
- Hide the close button on dangerous actions

---

### 7. Navigation Component

#### Purpose
Primary and secondary navigation patterns for wayfinding.

#### Header Navigation

```html
<header class="header">
  <div class="header-container">
    <div class="header-brand">
      <a href="/" class="header-logo" aria-label="Cortex home">
        <svg aria-hidden="true"><!-- logo --></svg>
        <span class="header-logo-text">Cortex</span>
      </a>
    </div>
    
    <nav class="header-nav" aria-label="Main navigation">
      <a href="/dashboard" class="header-nav-link">Dashboard</a>
      <a href="/notifications" class="header-nav-link">Notifications</a>
      <a href="/settings" class="header-nav-link">Settings</a>
    </nav>
    
    <div class="header-actions">
      <button class="btn btn-ghost" aria-label="Notifications">
        <svg aria-hidden="true"><!-- bell icon --></svg>
        <span class="badge badge-danger badge-dot">3</span>
      </button>
      <button class="btn btn-ghost" aria-label="User menu">
        <img src="/avatar.jpg" alt="" class="header-avatar" />
      </button>
    </div>
  </div>
</header>
```

#### Visual Specs

```css
.header {
  background: var(--color-bg-primary);
  border-bottom: 1px solid var(--color-border);
  position: sticky;
  top: 0;
  z-index: 100;
}

.header-container {
  max-width: 1280px;
  margin: 0 auto;
  padding: var(--space-lg) var(--space-xl);
  display: flex;
  align-items: center;
  gap: var(--space-xl);
}

.header-brand {
  flex-shrink: 0;
}

.header-logo {
  display: flex;
  align-items: center;
  gap: var(--space-md);
  text-decoration: none;
  color: var(--color-text-primary);
  font-weight: var(--font-weight-semibold);
  font-size: var(--font-size-xl);
}

.header-logo:focus-visible {
  outline: 2px solid var(--color-primary-400);
  outline-offset: 4px;
  border-radius: var(--radius-sm);
}

.header-nav {
  display: flex;
  align-items: center;
  gap: var(--space-sm);
  flex: 1;
}

.header-nav-link {
  padding: var(--space-sm) var(--space-md);
  color: var(--color-text-secondary);
  text-decoration: none;
  font-weight: var(--font-weight-medium);
  border-radius: var(--radius-md);
  transition: all var(--transition-fast);
}

.header-nav-link:hover {
  color: var(--color-text-primary);
  background: var(--color-bg-secondary);
}

.header-nav-link.is-active {
  color: var(--color-primary-500);
  background: var(--color-primary-50);
}

.header-nav-link:focus-visible {
  outline: 2px solid var(--color-primary-400);
  outline-offset: 2px;
}

.header-actions {
  display: flex;
  align-items: center;
  gap: var(--space-sm);
}

.header-avatar {
  width: 2rem;
  height: 2rem;
  border-radius: var(--radius-full);
  object-fit: cover;
}

/* Notification badge */
.badge-dot {
  position: absolute;
  top: -0.25rem;
  right: -0.25rem;
  min-width: 1.25rem;
  height: 1.25rem;
  padding: 0.125rem 0.25rem;
  display: flex;
  align-items: center;
  justify-content: center;
  border: 2px solid var(--color-bg-primary);
}

/* Mobile responsive */
@media (max-width: 768px) {
  .header-nav {
    display: none; /* Use mobile menu instead */
  }
}
```

#### Sidebar Navigation

```html
<aside class="sidebar" aria-label="Secondary navigation">
  <nav class="sidebar-nav">
    <a href="/admin/users" class="sidebar-link is-active">
      <svg class="sidebar-icon" aria-hidden="true"><!-- users icon --></svg>
      <span>Users</span>
    </a>
    <a href="/admin/api-keys" class="sidebar-link">
      <svg class="sidebar-icon" aria-hidden="true"><!-- key icon --></svg>
      <span>API Keys</span>
    </a>
    <a href="/admin/settings" class="sidebar-link">
      <svg class="sidebar-icon" aria-hidden="true"><!-- settings icon --></svg>
      <span>Settings</span>
    </a>
  </nav>
  
  <div class="sidebar-footer">
    <button class="sidebar-link sidebar-link-danger">
      <svg class="sidebar-icon" aria-hidden="true"><!-- logout icon --></svg>
      <span>Logout</span>
    </button>
  </div>
</aside>
```

```css
.sidebar {
  width: 250px;
  height: 100vh;
  background: var(--color-bg-primary);
  border-right: 1px solid var(--color-border);
  display: flex;
  flex-direction: column;
  position: sticky;
  top: 0;
}

.sidebar-nav {
  flex: 1;
  padding: var(--space-lg);
  display: flex;
  flex-direction: column;
  gap: var(--space-xs);
}

.sidebar-link {
  display: flex;
  align-items: center;
  gap: var(--space-md);
  padding: var(--space-md);
  color: var(--color-text-secondary);
  text-decoration: none;
  border-radius: var(--radius-md);
  font-weight: var(--font-weight-medium);
  transition: all var(--transition-fast);
  cursor: pointer;
  background: transparent;
  border: none;
  width: 100%;
  text-align: left;
}

.sidebar-link:hover {
  color: var(--color-text-primary);
  background: var(--color-bg-secondary);
}

.sidebar-link.is-active {
  color: var(--color-primary-500);
  background: var(--color-primary-50);
  font-weight: var(--font-weight-semibold);
}

.sidebar-link:focus-visible {
  outline: 2px solid var(--color-primary-400);
  outline-offset: -2px;
}

.sidebar-icon {
  width: 1.25rem;
  height: 1.25rem;
}

.sidebar-link-danger {
  color: var(--color-danger-500);
}

.sidebar-link-danger:hover {
  color: var(--color-danger-600);
  background: var(--color-danger-50);
}

.sidebar-footer {
  padding: var(--space-lg);
  border-top: 1px solid var(--color-border);
}

/* Mobile responsive */
@media (max-width: 768px) {
  .sidebar {
    position: fixed;
    left: -250px;
    transition: left var(--transition-base);
    z-index: 200;
  }
  
  .sidebar.is-open {
    left: 0;
  }
}
```

#### Breadcrumb Navigation

```html
<nav aria-label="Breadcrumb" class="breadcrumb">
  <ol class="breadcrumb-list">
    <li class="breadcrumb-item">
      <a href="/">Home</a>
    </li>
    <li class="breadcrumb-item">
      <a href="/admin">Admin</a>
    </li>
    <li class="breadcrumb-item" aria-current="page">
      Users
    </li>
  </ol>
</nav>
```

```css
.breadcrumb {
  padding: var(--space-md) 0;
}

.breadcrumb-list {
  display: flex;
  align-items: center;
  gap: var(--space-sm);
  list-style: none;
  padding: 0;
  margin: 0;
}

.breadcrumb-item {
  display: flex;
  align-items: center;
  gap: var(--space-sm);
  color: var(--color-text-secondary);
  font-size: var(--font-size-sm);
}

.breadcrumb-item:not(:last-child)::after {
  content: '/';
  color: var(--color-text-secondary);
  opacity: 0.5;
}

.breadcrumb-item a {
  color: var(--color-primary-500);
  text-decoration: none;
}

.breadcrumb-item a:hover {
  text-decoration: underline;
}

.breadcrumb-item[aria-current="page"] {
  color: var(--color-text-primary);
  font-weight: var(--font-weight-medium);
}
```

#### Accessibility

- **Landmarks**: Use `<nav>` with `aria-label`
- **Current**: Mark current page with `aria-current="page"`
- **Keyboard**: All links/buttons fully keyboard navigable
- **Skip Link**: Provide "Skip to main content" link
- **Mobile**: Ensure touch targets are 44x44px minimum

#### Usage Guidelines

✅ **Do:**
- Keep navigation items to 5-7 maximum
- Use clear, concise labels
- Indicate current page/section
- Provide mobile-friendly navigation
- Use semantic HTML (`<nav>`, `<header>`)

❌ **Don't:**
- Use generic labels like "Click here"
- Make navigation items too small on mobile
- Hide critical navigation behind hamburger menus
- Use inconsistent navigation across pages

---

### 8. Chat Message Component

#### Purpose
Display conversation messages with clear visual distinction between user and assistant.

#### User Message

```html
<div class="message message-user">
  <div class="message-avatar">
    <img src="/user-avatar.jpg" alt="" />
  </div>
  <div class="message-content">
    <div class="message-header">
      <span class="message-author">You</span>
      <span class="message-time">2:34 PM</span>
    </div>
    <div class="message-body">
      How do I reset my password?
    </div>
  </div>
</div>
```

#### Assistant Message

```html
<div class="message message-assistant">
  <div class="message-avatar">
    <svg class="message-avatar-icon" aria-hidden="true"><!-- Cortex icon --></svg>
  </div>
  <div class="message-content">
    <div class="message-header">
      <span class="message-author">Cortex</span>
      <span class="message-time">2:34 PM</span>
    </div>
    <div class="message-body">
      <p>To reset your password:</p>
      <ol>
        <li>Click on "Settings" in the sidebar</li>
        <li>Select "Security"</li>
        <li>Click "Change Password"</li>
      </ol>
    </div>
    <div class="message-actions">
      <button class="message-action" aria-label="Copy message">
        <svg aria-hidden="true"><!-- copy icon --></svg>
      </button>
      <button class="message-action" aria-label="Helpful">
        <svg aria-hidden="true"><!-- thumbs up --></svg>
      </button>
      <button class="message-action" aria-label="Not helpful">
        <svg aria-hidden="true"><!-- thumbs down --></svg>
      </button>
    </div>
  </div>
</div>
```

#### Visual Specs

```css
.message {
  display: flex;
  gap: var(--space-md);
  margin-bottom: var(--space-lg);
  max-width: 80%;
  animation: message-slide-in var(--transition-base);
}

@keyframes message-slide-in {
  from {
    opacity: 0;
    transform: translateY(0.5rem);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

.message-user {
  margin-left: auto;
  flex-direction: row-reverse;
}

.message-avatar {
  flex-shrink: 0;
  width: 2.5rem;
  height: 2.5rem;
  border-radius: var(--radius-full);
  overflow: hidden;
  background: var(--color-bg-secondary);
  display: flex;
  align-items: center;
  justify-content: center;
}

.message-avatar img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.message-avatar-icon {
  width: 1.5rem;
  height: 1.5rem;
  color: var(--color-primary-500);
}

.message-content {
  flex: 1;
  min-width: 0;
}

.message-header {
  display: flex;
  align-items: center;
  gap: var(--space-sm);
  margin-bottom: var(--space-xs);
}

.message-author {
  font-weight: var(--font-weight-semibold);
  font-size: var(--font-size-sm);
  color: var(--color-text-primary);
}

.message-time {
  font-size: var(--font-size-xs);
  color: var(--color-text-secondary);
}

.message-body {
  padding: var(--space-md);
  border-radius: var(--radius-lg);
  line-height: var(--line-height-relaxed);
}

.message-user .message-body {
  background: var(--color-primary-500);
  color: white;
  border-bottom-right-radius: var(--radius-sm);
}

.message-assistant .message-body {
  background: var(--color-bg-secondary);
  color: var(--color-text-primary);
  border-bottom-left-radius: var(--radius-sm);
}

/* Markdown content in messages */
.message-body h1,
.message-body h2,
.message-body h3 {
  margin-top: var(--space-lg);
  margin-bottom: var(--space-md);
  font-weight: var(--font-weight-semibold);
  line-height: var(--line-height-tight);
}

.message-body h1:first-child,
.message-body h2:first-child,
.message-body h3:first-child {
  margin-top: 0;
}

.message-body p {
  margin-bottom: var(--space-md);
}

.message-body p:last-child {
  margin-bottom: 0;
}

.message-body ul,
.message-body ol {
  margin: var(--space-md) 0;
  padding-left: var(--space-xl);
}

.message-body li {
  margin-bottom: var(--space-sm);
}

.message-body code {
  background: rgba(0, 0, 0, 0.1);
  padding: 0.125rem 0.375rem;
  border-radius: var(--radius-sm);
  font-family: var(--font-family-mono);
  font-size: 0.9em;
}

.message-user .message-body code {
  background: rgba(255, 255, 255, 0.2);
  color: white;
}

.message-body pre {
  background: var(--color-neutral-900);
  color: var(--color-neutral-100);
  padding: var(--space-lg);
  border-radius: var(--radius-md);
  overflow-x: auto;
  margin: var(--space-md) 0;
}

.message-body pre code {
  background: none;
  padding: 0;
  color: inherit;
}

.message-actions {
  display: flex;
  gap: var(--space-xs);
  margin-top: var(--space-sm);
  opacity: 0;
  transition: opacity var(--transition-fast);
}

.message:hover .message-actions,
.message:focus-within .message-actions {
  opacity: 1;
}

.message-action {
  background: transparent;
  border: none;
  padding: var(--space-xs);
  cursor: pointer;
  color: var(--color-text-secondary);
  border-radius: var(--radius-sm);
  transition: all var(--transition-fast);
  display: flex;
  align-items: center;
  justify-content: center;
}

.message-action:hover {
  color: var(--color-text-primary);
  background: var(--color-bg-tertiary);
}

.message-action:focus-visible {
  outline: 2px solid var(--color-primary-400);
  outline-offset: 2px;
}

.message-action svg {
  width: 1rem;
  height: 1rem;
}
```

#### System Message

```html
<div class="message message-system">
  <div class="message-body">
    Connected to Cortex Core
  </div>
</div>
```

```css
.message-system {
  justify-content: center;
  max-width: 100%;
  margin: var(--space-lg) 0;
}

.message-system .message-body {
  background: var(--color-bg-tertiary);
  color: var(--color-text-secondary);
  font-size: var(--font-size-sm);
  padding: var(--space-sm) var(--space-lg);
  border-radius: var(--radius-full);
  display: inline-block;
}
```

#### Typing Indicator

```html
<div class="message message-assistant">
  <div class="message-avatar">
    <svg class="message-avatar-icon" aria-hidden="true"><!-- icon --></svg>
  </div>
  <div class="message-content">
    <div class="message-body">
      <div class="typing-indicator" aria-label="Cortex is typing">
        <span></span>
        <span></span>
        <span></span>
      </div>
    </div>
  </div>
</div>
```

```css
.typing-indicator {
  display: flex;
  gap: 0.375rem;
  padding: 0.25rem 0;
}

.typing-indicator span {
  width: 0.5rem;
  height: 0.5rem;
  background: var(--color-text-secondary);
  border-radius: var(--radius-full);
  animation: typing-bounce 1.4s infinite;
}

.typing-indicator span:nth-child(2) {
  animation-delay: 0.2s;
}

.typing-indicator span:nth-child(3) {
  animation-delay: 0.4s;
}

@keyframes typing-bounce {
  0%, 60%, 100% {
    transform: translateY(0);
    opacity: 0.5;
  }
  30% {
    transform: translateY(-0.5rem);
    opacity: 1;
  }
}
```

#### Chat Input Area

```html
<div class="chat-input">
  <div class="chat-input-wrapper">
    <textarea 
      class="chat-input-field"
      placeholder="Chat with Cortex..."
      rows="1"
      aria-label="Message input"
    ></textarea>
    <button class="chat-input-submit" aria-label="Send message">
      <svg aria-hidden="true"><!-- send icon --></svg>
    </button>
  </div>
</div>
```

```css
.chat-input {
  padding: var(--space-lg);
  background: var(--color-bg-secondary);
  border-top: 1px solid var(--color-border);
}

.chat-input-wrapper {
  display: flex;
  gap: var(--space-md);
  align-items: flex-end;
  background: var(--color-bg-primary);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-lg);
  padding: var(--space-md);
  transition: border-color var(--transition-fast);
}

.chat-input-wrapper:focus-within {
  border-color: var(--color-primary-500);
}

.chat-input-field {
  flex: 1;
  min-height: 2.5rem;
  max-height: 12rem;
  border: none;
  background: transparent;
  color: var(--color-text-primary);
  font-family: var(--font-family-base);
  font-size: var(--font-size-base);
  resize: none;
  overflow-y: auto;
}

.chat-input-field:focus {
  outline: none;
}

.chat-input-field::placeholder {
  color: var(--color-text-secondary);
}

.chat-input-submit {
  flex-shrink: 0;
  width: 2.5rem;
  height: 2.5rem;
  background: var(--color-primary-500);
  color: white;
  border: none;
  border-radius: var(--radius-md);
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all var(--transition-base);
}

.chat-input-submit:hover {
  background: var(--color-primary-600);
  transform: scale(1.05);
}

.chat-input-submit:active {
  transform: scale(0.95);
}

.chat-input-submit:disabled {
  opacity: 0.5;
  cursor: not-allowed;
  transform: none;
}

.chat-input-submit:focus-visible {
  outline: 2px solid var(--color-primary-400);
  outline-offset: 2px;
}

.chat-input-submit svg {
  width: 1.25rem;
  height: 1.25rem;
}
```

#### Accessibility

- **Roles**: Use `role="log"` on chat container with `aria-live="polite"`
- **Labels**: Provide `aria-label` for avatar images and action buttons
- **Focus**: Ensure input is easily focusable
- **Keyboard**: Support Enter to send, Shift+Enter for newline
- **Screen Reader**: Announce new messages

#### Usage Guidelines

✅ **Do:**
- Clearly distinguish user vs assistant messages
- Show typing indicators for assistant responses
- Support markdown rendering in messages
- Auto-scroll to new messages
- Show timestamps for context

❌ **Don't:**
- Make messages too wide (max 80% of container)
- Hide message metadata (author, time)
- Show too many action buttons per message (3 max)
- Auto-scroll while user is reading previous messages

---

## Implementation Guidelines

### Framework Integration

#### Plain HTML/CSS
Components are designed as semantic HTML with CSS classes. Use BEM-style naming for scalability:

```css
/* Block */
.btn { }

/* Element */
.btn-icon { }

/* Modifier */
.btn-primary { }
.btn-sm { }
```

#### React/Vue Translation

Components map directly to framework components:

```jsx
// React example
<Button variant="primary" size="lg" disabled={loading}>
  {loading ? 'Loading...' : 'Submit'}
</Button>

// Rendered output
<button class="btn btn-primary btn-lg" disabled>
  Loading...
</button>
```

#### Mobile Native

Design tokens translate to native styling:

```swift
// iOS example
let primaryColor = UIColor(hex: "#667eea")
let buttonPadding = UIEdgeInsets(top: 12, left: 24, bottom: 12, right: 24)
let borderRadius: CGFloat = 6
```

### Progressive Enhancement

1. **Base HTML**: Works without CSS/JS
2. **CSS**: Visual enhancement
3. **JavaScript**: Interactive enhancement

Example:
```html
<!-- Works as standard link without JS -->
<a href="/notifications" class="nav-link">
  Notifications
</a>

<!-- Enhanced with JS for SPA navigation -->
<script>
  document.querySelectorAll('.nav-link').forEach(link => {
    link.addEventListener('click', (e) => {
      e.preventDefault();
      navigateTo(link.href);
    });
  });
</script>
```

### Theme Implementation

Use CSS custom properties for theming:

```css
/* Light theme (default) */
:root {
  --color-bg-primary: #ffffff;
  --color-text-primary: #333333;
}

/* Dark theme */
[data-theme="dark"] {
  --color-bg-primary: #1a1a1a;
  --color-text-primary: #e0e0e0;
}
```

Toggle theme with JavaScript:
```javascript
document.documentElement.setAttribute('data-theme', 'dark');
```

### Responsive Design

Use mobile-first approach:

```css
/* Mobile first (default) */
.header {
  flex-direction: column;
}

/* Desktop */
@media (min-width: 768px) {
  .header {
    flex-direction: row;
  }
}
```

### Accessibility Checklist

- [ ] All interactive elements keyboard accessible
- [ ] Focus indicators visible
- [ ] Color contrast ratio ≥ 4.5:1 for text
- [ ] Form inputs have labels
- [ ] Images have alt text
- [ ] ARIA attributes used correctly
- [ ] Semantic HTML elements used
- [ ] Touch targets ≥ 44x44px on mobile

### Performance Considerations

1. **CSS**: Keep selectors simple, avoid deep nesting
2. **Animations**: Use `transform` and `opacity` for GPU acceleration
3. **Images**: Use responsive images with `srcset`
4. **Fonts**: Subset fonts, use `font-display: swap`
5. **Critical CSS**: Inline above-the-fold styles

---

## Conclusion

This component design system provides a solid foundation for building consistent, accessible, and maintainable UIs across the Cortex platform. Components are designed to be:

- **Modular**: Independent, reusable pieces
- **Portable**: Framework-agnostic specifications
- **Accessible**: WCAG 2.1 AA compliant
- **Themeable**: Support multiple color schemes
- **Scalable**: From simple HTML to complex frameworks

### Next Steps

1. **Create Component Library**: Implement components in chosen framework
2. **Build Storybook/Documentation**: Visual component gallery
3. **Design Tokens Package**: NPM package with design tokens
4. **Component Testing**: Unit and integration tests
5. **Accessibility Audit**: Automated and manual testing

### References

- [WCAG 2.1 Guidelines](https://www.w3.org/WAI/WCAG21/quickref/)
- [ARIA Authoring Practices](https://www.w3.org/WAI/ARIA/apg/)
- [MDN Web Docs](https://developer.mozilla.org/)

---

**Document Maintainers**: Design Team, Engineering Team  
**Last Updated**: 2026-01-16  
**Next Review**: 2026-04-16
