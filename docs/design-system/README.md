# Cortex Design System

**Version:** 1.0.0  
**Last Updated:** 2026-01-16

## Overview

The Cortex Design System is a comprehensive, technology-agnostic design framework that embodies the platform's vision of intelligent, seamless, and adaptive user experiences. This system provides the foundation for building consistent, accessible, and beautiful interfaces across all Cortex surfaces—web, desktop, mobile, and native integrations.

## Philosophy

The Cortex design system is built on the same principles that guide the platform itself:

### 🧠 Intelligent
Our design adapts to context, user preferences, and environmental factors. Components are built to be smart about when and how they present information.

### 🔄 Seamless
Smooth transitions, consistent patterns, and predictable behaviors create an experience that feels fluid and natural across all modalities—chat, voice, canvas, dashboards, and native applications.

### 🧩 Modular
Like the Cortex platform architecture, our design system is composed of independent, reusable components that work together harmoniously. Each component can be used standalone or composed with others to create complex interfaces.

### ♿ Accessible
WCAG 2.1 AA compliance is not an afterthought—it's built into every component. Keyboard navigation, screen reader support, and appropriate color contrast are fundamental requirements.

## What's Included

```
docs/design-system/
├── README.md                      # This file - overview and getting started
├── design-tokens.json             # Complete design token definitions
└── component-specifications.md    # Detailed component specs
```

### 1. Design Tokens (`design-tokens.json`)

A comprehensive JSON file containing all design tokens following the [Design Tokens Community Group](https://tr.designtokens.org/format/) specification:

- **Colors**: Primitive palette + semantic color mappings for light/dark modes
- **Typography**: Font families, sizes, weights, line heights, letter spacing
- **Spacing**: 4px-based spacing scale (0-32)
- **Sizing**: Standardized dimensions for buttons, inputs, icons, avatars
- **Border Radius**: None to full (pill/circular)
- **Shadows**: Elevation system from xs to 2xl + focus rings
- **Opacity**: 0-100 scale
- **Animation**: Duration and easing functions
- **Breakpoints**: Responsive design breakpoints (xs to 2xl)
- **Z-Index**: Layering system for overlays, modals, toasts, etc.

### 2. Component Specifications (`component-specifications.md`)

Detailed specifications for all core components including:

- **Buttons**: Primary, secondary, tertiary, danger, icon buttons
- **Input Fields**: Text, textarea, search, select, with labels and validation
- **Cards & Panels**: Basic cards, notification cards with variants
- **Notifications & Toasts**: Toast notifications, desktop notifications, toast stacks
- **Navigation**: Top nav, side nav, breadcrumbs, tabs, pagination
- **Additional Components**: Avatars, badges, modals, tooltips, loading states, progress bars

Each component includes:
- Visual design specifications
- All interactive states (hover, active, focus, disabled)
- Size variants
- Accessibility requirements
- Animation guidelines
- Implementation notes

## Getting Started

### For Designers

1. **Review the Design Tokens**: Familiarize yourself with the color palette, typography scale, and spacing system in `design-tokens.json`

2. **Use Semantic Colors**: Always use semantic color tokens (e.g., `primary.default`, `text.secondary`) rather than primitive colors (e.g., `blue.600`)

3. **Follow Component Specs**: When designing new screens, use the components defined in `component-specifications.md` as your building blocks

4. **Design for Both Themes**: Consider both light and dark modes from the start

5. **Think Responsive**: Plan layouts for mobile, tablet, and desktop breakpoints

### For Developers

#### Web (CSS/CSS-in-JS)

Convert the design tokens to CSS custom properties:

```css
/* tokens.css */
:root.light-theme {
  /* Colors */
  --color-primary-default: #5155e6;
  --color-primary-hover: #4446cc;
  --color-background-primary: #ffffff;
  --color-text-primary: #0f172a;
  
  /* Typography */
  --font-family-sans: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
  --font-size-base: 1rem;
  --font-weight-medium: 500;
  
  /* Spacing */
  --spacing-4: 1rem;
  --spacing-6: 1.5rem;
  
  /* Shadows */
  --shadow-md: 0 4px 6px -1px rgba(0, 0, 0, 0.1);
  
  /* Border Radius */
  --border-radius-md: 0.375rem;
  
  /* Animation */
  --duration-fast: 150ms;
  --easing-ease-out: cubic-bezier(0, 0, 0.2, 1);
}

:root.dark-theme {
  --color-primary-default: #8b5cf6;
  --color-background-primary: #020617;
  --color-text-primary: #f8fafc;
  /* ... other dark mode tokens ... */
}
```

Then use in your components:

```css
.button-primary {
  background-color: var(--color-primary-default);
  color: white;
  padding: var(--spacing-3) var(--spacing-6);
  border-radius: var(--border-radius-md);
  box-shadow: var(--shadow-sm);
  transition: all var(--duration-fast) var(--easing-ease-out);
}

.button-primary:hover {
  background-color: var(--color-primary-hover);
  box-shadow: var(--shadow-md);
}
```

#### React/TypeScript

Create a theme provider and styled components:

```typescript
// theme.ts
import designTokens from './design-tokens.json';

export const theme = {
  colors: designTokens.cortex.color.semantic.light,
  typography: designTokens.cortex.typography,
  spacing: designTokens.cortex.spacing,
  // ... other tokens
};

export type Theme = typeof theme;

// Button.tsx
import styled from 'styled-components';

export const Button = styled.button<{ variant?: 'primary' | 'secondary' }>`
  font-family: ${({ theme }) => theme.typography.fontFamily.sans.value};
  font-size: ${({ theme }) => theme.typography.fontSize.base.value};
  padding: ${({ theme }) => `${theme.spacing['3'].value} ${theme.spacing['6'].value}`};
  border-radius: ${({ theme }) => theme.borderRadius.md.value};
  transition: all ${({ theme }) => theme.animation.duration.fast.value} 
              ${({ theme }) => theme.animation.easing.easeOut.value};
  
  ${({ variant = 'primary', theme }) => {
    if (variant === 'primary') {
      return `
        background-color: ${theme.colors.primary.default.value};
        color: ${theme.colors.text.inverse.value};
        box-shadow: ${theme.shadow.sm.value};
        
        &:hover {
          background-color: ${theme.colors.primary.hover.value};
          box-shadow: ${theme.shadow.md.value};
        }
      `;
    }
    // ... other variants
  }}
`;
```

#### React Native

```typescript
// tokens.ts
import designTokens from './design-tokens.json';

// Convert rem to pixels for React Native (assuming 16px base)
const remToPx = (rem: string) => {
  const value = parseFloat(rem);
  return value * 16;
};

export const tokens = {
  colors: {
    primary: designTokens.cortex.color.semantic.light.primary.default.value,
    background: designTokens.cortex.color.semantic.light.background.primary.value,
    // ... other colors
  },
  spacing: {
    4: remToPx(designTokens.cortex.spacing['4'].value),
    6: remToPx(designTokens.cortex.spacing['6'].value),
    // ... other spacing
  },
  typography: {
    fontSize: {
      base: remToPx(designTokens.cortex.typography.fontSize.base.value),
      // ... other sizes
    },
  },
};

// Button.tsx
import { StyleSheet, TouchableOpacity, Text } from 'react-native';
import { tokens } from './tokens';

const Button = ({ title, onPress, variant = 'primary' }) => (
  <TouchableOpacity 
    style={[styles.button, variant === 'primary' && styles.buttonPrimary]}
    onPress={onPress}
  >
    <Text style={styles.buttonText}>{title}</Text>
  </TouchableOpacity>
);

const styles = StyleSheet.create({
  button: {
    paddingVertical: tokens.spacing[3],
    paddingHorizontal: tokens.spacing[6],
    borderRadius: 6,
    alignItems: 'center',
    justifyContent: 'center',
  },
  buttonPrimary: {
    backgroundColor: tokens.colors.primary,
  },
  buttonText: {
    color: '#ffffff',
    fontSize: tokens.typography.fontSize.base,
    fontWeight: '500',
  },
});
```

### Using Style Dictionary (Recommended)

For automated token transformation, use [Style Dictionary](https://amzn.github.io/style-dictionary/):

```javascript
// build-tokens.js
const StyleDictionary = require('style-dictionary');

const sd = StyleDictionary.extend({
  source: ['design-tokens.json'],
  platforms: {
    css: {
      transformGroup: 'css',
      buildPath: 'dist/css/',
      files: [{
        destination: 'tokens.css',
        format: 'css/variables'
      }]
    },
    js: {
      transformGroup: 'js',
      buildPath: 'dist/js/',
      files: [{
        destination: 'tokens.js',
        format: 'javascript/es6'
      }]
    },
    reactNative: {
      transformGroup: 'react-native',
      buildPath: 'dist/rn/',
      files: [{
        destination: 'tokens.js',
        format: 'javascript/es6'
      }]
    }
  }
});

sd.buildAllPlatforms();
```

## Design Patterns

### Color Usage

**Do:**
- ✅ Use semantic tokens: `{cortex.color.semantic.light.primary.default}`
- ✅ Provide both light and dark mode colors
- ✅ Ensure 4.5:1 contrast ratio for text
- ✅ Use subtle backgrounds for secondary surfaces

**Don't:**
- ❌ Use primitive colors directly in components
- ❌ Hard-code hex values
- ❌ Rely solely on color to convey meaning
- ❌ Use too many colors on a single screen

### Typography

**Hierarchy:**
1. Display text: `3xl-6xl`, `bold-extrabold` (hero sections, landing pages)
2. Headings: `xl-2xl`, `semibold-bold` (page/section titles)
3. Body text: `base-lg`, `normal` (main content)
4. Secondary text: `sm`, `normal` (captions, helper text)
5. Fine print: `xs`, `normal` (legal, metadata)

**Line Length:**
- Optimal: 45-75 characters per line
- Maximum: 90 characters for readability

### Spacing

Follow the 4px base grid:
- Use spacing scale consistently (1, 2, 3, 4, 5, 6, 8, 10, 12, 16, 20, 24, 32)
- Component internal padding: Usually 4 or 6 (16px or 24px)
- Between components: 4-8 (16-32px)
- Section spacing: 12-16 (48-64px)

### Responsive Design

**Mobile First Approach:**
1. Design for mobile (< 640px) first
2. Add complexity at larger breakpoints
3. Use relative units (rem, %, vw) over fixed pixels
4. Stack components vertically on small screens
5. Utilize horizontal space on larger screens

**Breakpoint Guidelines:**
- `xs` (0px): Single column, full-width components
- `sm` (640px): May introduce 2-column layouts
- `md` (768px): Tablet-optimized, side nav may appear
- `lg` (1024px): Full desktop layout
- `xl` (1280px): Maximum content width, side padding
- `2xl` (1536px): Wide screens, centered content

## Accessibility Checklist

Every component implementation should verify:

- [ ] **Keyboard Navigation**: All interactive elements are keyboard accessible
- [ ] **Focus Indicators**: Visible focus states using `{cortex.shadow.focus}`
- [ ] **Color Contrast**: Text meets 4.5:1 ratio minimum
- [ ] **Screen Readers**: Semantic HTML and ARIA labels where needed
- [ ] **Touch Targets**: Minimum 44×44px tap targets
- [ ] **Motion**: Respects `prefers-reduced-motion` user preference
- [ ] **Text Scaling**: Supports browser zoom up to 200%
- [ ] **Error States**: Clear, descriptive error messages associated with fields

## Dark Mode Implementation

### CSS Approach

```css
/* Auto-detect system preference */
@media (prefers-color-scheme: dark) {
  :root {
    /* Apply dark theme tokens */
  }
}

/* Manual toggle */
:root.dark-theme {
  /* Dark theme tokens */
}
```

### React Approach

```typescript
import { createContext, useContext, useState, useEffect } from 'react';

type Theme = 'light' | 'dark' | 'system';

const ThemeContext = createContext<{
  theme: Theme;
  setTheme: (theme: Theme) => void;
}>({ theme: 'system', setTheme: () => {} });

export const ThemeProvider = ({ children }) => {
  const [theme, setTheme] = useState<Theme>('system');
  
  useEffect(() => {
    const root = document.documentElement;
    const systemTheme = window.matchMedia('(prefers-color-scheme: dark)').matches 
      ? 'dark' 
      : 'light';
    
    const activeTheme = theme === 'system' ? systemTheme : theme;
    
    root.classList.remove('light-theme', 'dark-theme');
    root.classList.add(`${activeTheme}-theme`);
  }, [theme]);
  
  return (
    <ThemeContext.Provider value={{ theme, setTheme }}>
      {children}
    </ThemeContext.Provider>
  );
};

export const useTheme = () => useContext(ThemeContext);
```

## Animation Guidelines

### Durations
- **Instant** (0ms): Immediate state changes
- **Fast** (150ms): Hover effects, button presses
- **Normal** (250ms): Most transitions, slide-ins
- **Slow** (350ms): Complex state changes
- **Slower** (500ms): Loading spinners, page transitions

### Easing Functions
- **easeOut**: Element entering the screen
- **easeIn**: Element leaving the screen
- **easeInOut**: Element moving within the screen
- **spring**: Playful, bouncy interactions (use sparingly)

### Reduced Motion

Always respect user preferences:

```css
@media (prefers-reduced-motion: reduce) {
  * {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
  }
}
```

## Contributing

### Adding New Tokens

1. Edit `design-tokens.json` following the existing structure
2. Update this README if adding new categories
3. Update `component-specifications.md` to reference new tokens
4. Submit PR with examples of usage

### Adding New Components

1. Define component spec in `component-specifications.md`
2. Include all states, sizes, and variants
3. Document accessibility requirements
4. Provide implementation examples
5. Include visual examples (Figma, screenshots, or code sandbox)

## Tools & Resources

### Design Tools
- **Figma**: Import tokens using [Tokens Studio](https://tokens.studio/)
- **Sketch**: Use [Style Dictionary Sketch plugin](https://github.com/amzn/style-dictionary)
- **Adobe XD**: Manual import or use [Design Tokens plugin](https://adobexdplatform.com/plugin-docs/)

### Development Tools
- **Style Dictionary**: Automated token transformation
- **Tailwind CSS**: Can be configured to use Cortex tokens
- **Styled Components**: Theme provider integration
- **CSS Modules**: Import tokens as JavaScript objects

### Testing Tools
- **axe DevTools**: Accessibility testing
- **WAVE**: Web accessibility evaluation
- **Lighthouse**: Performance and accessibility audits
- **VoiceOver/NVDA**: Screen reader testing

## Examples

See the `/examples` directory (coming soon) for:
- Sample page layouts
- Component composition patterns
- Integration examples
- Design-to-code workflows

## Support

For questions, issues, or contributions:
- **Documentation**: This README and linked specifications
- **Design Questions**: Consult component specifications
- **Implementation Help**: See framework-specific examples above
- **Issues**: Submit via your project's issue tracker

## Version History

**1.0.0** (2026-01-16)
- Initial release of Cortex Design System
- Complete design tokens JSON following Community Group spec
- Comprehensive component specifications
- Implementation guides for web, React, and React Native
- Accessibility and dark mode guidelines

---

## Quick Reference

### Most Used Tokens

**Colors:**
- Primary: `cortex.color.semantic.light.primary.default`
- Background: `cortex.color.semantic.light.background.primary`
- Text: `cortex.color.semantic.light.text.primary`
- Border: `cortex.color.semantic.light.border.default`

**Spacing:**
- Small: `cortex.spacing.2` (8px)
- Medium: `cortex.spacing.4` (16px)
- Large: `cortex.spacing.6` (24px)

**Typography:**
- Body: `cortex.typography.fontSize.base` (16px)
- Heading: `cortex.typography.fontSize.xl` (20px)
- Weight: `cortex.typography.fontWeight.medium` (500)

**Shadows:**
- Subtle: `cortex.shadow.sm`
- Elevated: `cortex.shadow.md`
- Floating: `cortex.shadow.lg`
- Focus: `cortex.shadow.focus`

**Border Radius:**
- Default: `cortex.borderRadius.md` (6px)
- Large: `cortex.borderRadius.lg` (8px)
- Pill: `cortex.borderRadius.full` (9999px)

---

Built with ❤️ for the Cortex Platform
