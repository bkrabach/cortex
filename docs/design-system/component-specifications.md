# Cortex Design System: Component Specifications

**Version:** 1.0.0  
**Last Updated:** 2026-01-16

## Overview

This document defines the component specifications for the Cortex Platform design system. All components are designed to be technology-agnostic and can be implemented in CSS, React, React Native, or other frameworks by consuming the design tokens defined in `design-tokens.json`.

## Design Principles

The Cortex design system embodies the platform's core values:

- **Intelligent**: Components adapt to context and user preferences
- **Seamless**: Smooth transitions and consistent interactions across all surfaces
- **Modular**: Independent, composable components that work together harmoniously
- **Accessible**: WCAG 2.1 AA compliant with keyboard navigation and screen reader support

---

## 1. Buttons

Buttons trigger actions and are one of the most frequently used interactive components.

### 1.1 Button Variants

#### Primary Button
- **Purpose**: Main call-to-action on a page or section
- **Visual Design**:
  - Background: `{cortex.color.semantic.light.primary.default}`
  - Text: `{cortex.color.semantic.light.text.inverse}`
  - Border: None
  - Border Radius: `{cortex.borderRadius.md}`
  - Shadow: `{cortex.shadow.sm}`
  - Padding: `{cortex.spacing.3}` vertical, `{cortex.spacing.6}` horizontal
  
- **States**:
  - **Hover**: Background `{cortex.color.semantic.light.primary.hover}`, Shadow `{cortex.shadow.md}`
  - **Active**: Background `{cortex.color.semantic.light.primary.active}`, Shadow `{cortex.shadow.xs}`
  - **Focus**: Add `{cortex.shadow.focus}` ring
  - **Disabled**: Background `{cortex.color.semantic.light.primary.disabled}`, Opacity `{cortex.opacity.50}`, Cursor not-allowed

- **Sizes**:
  - **Small**: Height `{cortex.sizing.buttonHeight.sm}`, Font Size `{cortex.typography.fontSize.sm}`
  - **Medium** (default): Height `{cortex.sizing.buttonHeight.md}`, Font Size `{cortex.typography.fontSize.base}`
  - **Large**: Height `{cortex.sizing.buttonHeight.lg}`, Font Size `{cortex.typography.fontSize.lg}`

#### Secondary Button
- **Purpose**: Secondary actions that are important but not primary
- **Visual Design**:
  - Background: `{cortex.color.semantic.light.surface.primary}`
  - Text: `{cortex.color.semantic.light.primary.default}`
  - Border: `{cortex.borderWidth.thin}` solid `{cortex.color.semantic.light.primary.default}`
  - Border Radius: `{cortex.borderRadius.md}`
  - Shadow: None
  - Padding: `{cortex.spacing.3}` vertical, `{cortex.spacing.6}` horizontal

- **States**:
  - **Hover**: Background `{cortex.color.semantic.light.primary.subtle}`, Border `{cortex.color.semantic.light.primary.hover}`
  - **Active**: Background `{cortex.color.semantic.light.primary.subtleBorder}`, Scale 0.98
  - **Focus**: Add `{cortex.shadow.focus}` ring
  - **Disabled**: Border/Text `{cortex.color.semantic.light.primary.disabled}`, Opacity `{cortex.opacity.50}`

#### Tertiary/Ghost Button
- **Purpose**: Low-emphasis actions or navigation
- **Visual Design**:
  - Background: Transparent
  - Text: `{cortex.color.semantic.light.text.secondary}`
  - Border: None
  - Border Radius: `{cortex.borderRadius.md}`
  - Padding: `{cortex.spacing.2}` vertical, `{cortex.spacing.4}` horizontal

- **States**:
  - **Hover**: Background `{cortex.color.semantic.light.background.secondary}`, Text `{cortex.color.semantic.light.text.primary}`
  - **Active**: Background `{cortex.color.semantic.light.background.tertiary}`
  - **Focus**: Add `{cortex.shadow.focus}` ring
  - **Disabled**: Text `{cortex.color.semantic.light.text.disabled}`

#### Danger Button
- **Purpose**: Destructive or high-risk actions
- **Visual Design**:
  - Background: `{cortex.color.semantic.light.error.default}`
  - Text: `{cortex.color.semantic.light.text.inverse}`
  - Border: None
  - Border Radius: `{cortex.borderRadius.md}`
  - Shadow: `{cortex.shadow.sm}`

- **States**:
  - **Hover**: Background `{cortex.color.semantic.light.error.hover}`, Shadow `{cortex.shadow.md}`
  - **Active**: Background `{cortex.color.semantic.light.error.active}`
  - **Focus**: Add error-colored focus ring (0 0 0 3px rgba(239, 68, 68, 0.3))
  - **Disabled**: Background `{cortex.color.semantic.light.error.subtle}`, Opacity `{cortex.opacity.50}`

### 1.2 Icon Buttons
- Circular or square buttons containing only an icon
- Minimum touch target: 44x44px (WCAG 2.1 Level AAA)
- Size: `{cortex.sizing.buttonHeight.md}` × `{cortex.sizing.buttonHeight.md}`
- Icon: `{cortex.sizing.iconSize.md}`
- Must include `aria-label` for accessibility

### 1.3 Button Groups
- Multiple buttons grouped together
- Spacing: `{cortex.spacing.2}` between buttons
- First button: Border radius left, none right
- Middle buttons: No border radius
- Last button: Border radius right, none left

### 1.4 Animations
- Transition: `all {cortex.animation.duration.fast} {cortex.animation.easing.easeOut}`
- Active state: Scale transform 0.98 for tactile feedback

---

## 2. Input Fields

Input fields allow users to enter text and data.

### 2.1 Text Input

#### Default State
- **Visual Design**:
  - Background: `{cortex.color.semantic.light.surface.primary}`
  - Border: `{cortex.borderWidth.thin}` solid `{cortex.color.semantic.light.border.default}`
  - Border Radius: `{cortex.borderRadius.md}`
  - Padding: `{cortex.spacing.3}` vertical, `{cortex.spacing.4}` horizontal
  - Font Size: `{cortex.typography.fontSize.base}`
  - Text Color: `{cortex.color.semantic.light.text.primary}`
  - Placeholder Color: `{cortex.color.semantic.light.text.tertiary}`

- **States**:
  - **Hover**: Border `{cortex.color.semantic.light.border.strong}`
  - **Focus**: Border `{cortex.color.semantic.light.border.focus}`, Add `{cortex.shadow.focus}` ring
  - **Error**: Border `{cortex.color.semantic.light.error.default}`, Add error focus ring
  - **Success**: Border `{cortex.color.semantic.light.success.default}`
  - **Disabled**: Background `{cortex.color.semantic.light.background.secondary}`, Cursor not-allowed, Opacity `{cortex.opacity.60}`

- **Sizes**:
  - **Small**: Height `{cortex.sizing.inputHeight.sm}`, Font Size `{cortex.typography.fontSize.sm}`
  - **Medium** (default): Height `{cortex.sizing.inputHeight.md}`, Font Size `{cortex.typography.fontSize.base}`
  - **Large**: Height `{cortex.sizing.inputHeight.lg}`, Font Size `{cortex.typography.fontSize.lg}`

### 2.2 Input with Label

```
[Label]
[Input Field]
[Helper Text / Error Message]
```

- **Label**:
  - Font Size: `{cortex.typography.fontSize.sm}`
  - Font Weight: `{cortex.typography.fontWeight.medium}`
  - Color: `{cortex.color.semantic.light.text.primary}`
  - Margin Bottom: `{cortex.spacing.2}`
  - Required indicator: Red asterisk if required

- **Helper Text**:
  - Font Size: `{cortex.typography.fontSize.sm}`
  - Color: `{cortex.color.semantic.light.text.secondary}`
  - Margin Top: `{cortex.spacing.2}`

- **Error Message**:
  - Font Size: `{cortex.typography.fontSize.sm}`
  - Color: `{cortex.color.semantic.light.error.default}`
  - Margin Top: `{cortex.spacing.2}`
  - Icon: Alert/Warning icon

### 2.3 Textarea
- Same styling as text input
- Min Height: `{cortex.spacing.24}` (96px)
- Resize: Vertical only
- Line Height: `{cortex.typography.lineHeight.relaxed}`

### 2.4 Input with Icons
- **Leading Icon**: Icon positioned at the start, Padding Left `{cortex.spacing.10}` on input
- **Trailing Icon**: Icon positioned at the end, Padding Right `{cortex.spacing.10}` on input
- Icon Size: `{cortex.sizing.iconSize.md}`
- Icon Color: `{cortex.color.semantic.light.text.tertiary}`

### 2.5 Search Input
- Leading search icon
- Trailing clear button (appears when text is entered)
- Border Radius: `{cortex.borderRadius.full}` for pill shape
- Placeholder: "Search..." or context-specific

### 2.6 Select Dropdown
- Same base styling as text input
- Trailing chevron-down icon
- Dropdown panel:
  - Background: `{cortex.color.semantic.light.surface.raised}`
  - Border: `{cortex.borderWidth.thin}` solid `{cortex.color.semantic.light.border.default}`
  - Border Radius: `{cortex.borderRadius.md}`
  - Shadow: `{cortex.shadow.lg}`
  - Max Height: 300px with scroll
  - Z-Index: `{cortex.zIndex.dropdown}`

- **Option Item**:
  - Padding: `{cortex.spacing.3}` vertical, `{cortex.spacing.4}` horizontal
  - Hover: Background `{cortex.color.semantic.light.background.secondary}`
  - Selected: Background `{cortex.color.semantic.light.primary.subtle}`, Font Weight `{cortex.typography.fontWeight.medium}`

---

## 3. Cards & Panels

Cards are containers for grouping related content and actions.

### 3.1 Basic Card

- **Visual Design**:
  - Background: `{cortex.color.semantic.light.surface.raised}`
  - Border: `{cortex.borderWidth.thin}` solid `{cortex.color.semantic.light.border.default}`
  - Border Radius: `{cortex.borderRadius.lg}`
  - Shadow: `{cortex.shadow.sm}`
  - Padding: `{cortex.spacing.6}`

- **States**:
  - **Hover** (if interactive): Shadow `{cortex.shadow.md}`, Translate Y -2px
  - **Active** (if clickable): Shadow `{cortex.shadow.xs}`, Translate Y 0px

### 3.2 Card Anatomy

```
┌─────────────────────────────┐
│ [Header]                    │
│ ─────────────────────────── │
│ [Content]                   │
│                             │
│ ─────────────────────────── │
│ [Footer / Actions]          │
└─────────────────────────────┘
```

- **Header**:
  - Padding: `{cortex.spacing.6}`
  - Border Bottom: `{cortex.borderWidth.thin}` solid `{cortex.color.semantic.light.border.subtle}`
  - Title Font Size: `{cortex.typography.fontSize.lg}`
  - Title Font Weight: `{cortex.typography.fontWeight.semibold}`
  - Optional subtitle or action buttons

- **Content**:
  - Padding: `{cortex.spacing.6}`
  - Font Size: `{cortex.typography.fontSize.base}`
  - Line Height: `{cortex.typography.lineHeight.relaxed}`

- **Footer**:
  - Padding: `{cortex.spacing.6}`
  - Border Top: `{cortex.borderWidth.thin}` solid `{cortex.color.semantic.light.border.subtle}`
  - Flex layout for action buttons
  - Justify Content: space-between or flex-end

### 3.3 Notification Card

Used for displaying system notifications and alerts.

- Same base as card but with color variations:
  - **Info**: Left border `{cortex.borderWidth.thick}` `{cortex.color.semantic.light.info.default}`, Background tint `{cortex.color.semantic.light.info.subtle}`
  - **Success**: Left border `{cortex.color.semantic.light.success.default}`, Background tint `{cortex.color.semantic.light.success.subtle}`
  - **Warning**: Left border `{cortex.color.semantic.light.warning.default}`, Background tint `{cortex.color.semantic.light.warning.subtle}`
  - **Error**: Left border `{cortex.color.semantic.light.error.default}`, Background tint `{cortex.color.semantic.light.error.subtle}`

- **Anatomy**:
  - Leading icon (colored to match notification type)
  - Title (Font Weight: `{cortex.typography.fontWeight.semibold}`)
  - Message/Description
  - Optional action buttons
  - Close button (top-right corner)

---

## 4. Notifications & Toasts

Temporary messages that appear to provide feedback or important information.

### 4.1 Toast Notification

- **Visual Design**:
  - Background: `{cortex.color.semantic.light.surface.raised}`
  - Border: `{cortex.borderWidth.thin}` solid `{cortex.color.semantic.light.border.default}`
  - Border Radius: `{cortex.borderRadius.lg}`
  - Shadow: `{cortex.shadow.xl}`
  - Padding: `{cortex.spacing.4}`
  - Min Width: 320px
  - Max Width: 480px

- **Position**:
  - Default: Top-right corner
  - Distance from edge: `{cortex.spacing.6}`
  - Z-Index: `{cortex.zIndex.toast}`

- **Anatomy**:
  ```
  [Icon] [Title]           [×]
         [Message]
         [Action Button (optional)]
  ```

- **Types** (same color variations as Notification Card):
  - Info (blue)
  - Success (green)
  - Warning (amber)
  - Error (red)

### 4.2 Toast Animations

- **Entry**: Slide in from right + fade in
  - Duration: `{cortex.animation.duration.normal}`
  - Easing: `{cortex.animation.easing.spring}`
  
- **Exit**: Slide out to right + fade out
  - Duration: `{cortex.animation.duration.fast}`
  - Easing: `{cortex.animation.easing.easeIn}`

- **Auto-dismiss**: 
  - Default: 5 seconds for info/success
  - Warning: 7 seconds
  - Error: Must be manually dismissed (no auto-dismiss)

### 4.3 Toast Stack
- Multiple toasts stack vertically
- Spacing between toasts: `{cortex.spacing.3}`
- Maximum visible toasts: 3 (older ones fade out)

### 4.4 Desktop Notification
For native system notifications (outside the browser):

- Use platform-native notification APIs
- Include:
  - App icon
  - Title (max 50 characters)
  - Body (max 150 characters)
  - Optional action buttons (max 2)
  - Optional image/thumbnail

---

## 5. Navigation

### 5.1 Top Navigation Bar

- **Visual Design**:
  - Background: `{cortex.color.semantic.light.surface.raised}`
  - Border Bottom: `{cortex.borderWidth.thin}` solid `{cortex.color.semantic.light.border.default}`
  - Height: 64px
  - Padding: `{cortex.spacing.4}` horizontal
  - Position: Fixed or sticky at top
  - Z-Index: `{cortex.zIndex.sticky}`

- **Layout**:
  ```
  [Logo] [Nav Items]          [Search] [Notifications] [Profile]
  ```

- **Nav Items**:
  - Padding: `{cortex.spacing.3}` vertical, `{cortex.spacing.4}` horizontal
  - Font Size: `{cortex.typography.fontSize.base}`
  - Font Weight: `{cortex.typography.fontWeight.medium}`
  - Color: `{cortex.color.semantic.light.text.secondary}`
  - Hover: Color `{cortex.color.semantic.light.text.primary}`, Background `{cortex.color.semantic.light.background.secondary}`
  - Active: Color `{cortex.color.semantic.light.primary.default}`, Border Bottom `{cortex.borderWidth.medium}` solid `{cortex.color.semantic.light.primary.default}`

### 5.2 Side Navigation

- **Visual Design**:
  - Background: `{cortex.color.semantic.light.surface.secondary}`
  - Border Right: `{cortex.borderWidth.thin}` solid `{cortex.color.semantic.light.border.default}`
  - Width: 
    - Expanded: 280px
    - Collapsed: 64px
  - Height: 100vh (full height)
  - Position: Fixed
  - Z-Index: `{cortex.zIndex.sticky}`

- **Nav Item**:
  - Padding: `{cortex.spacing.3}` vertical, `{cortex.spacing.4}` horizontal
  - Border Radius: `{cortex.borderRadius.md}`
  - Margin: `{cortex.spacing.1}` horizontal, `{cortex.spacing.1}` vertical
  - Icon + Label (label hidden when collapsed)
  - Hover: Background `{cortex.color.semantic.light.background.tertiary}`
  - Active: Background `{cortex.color.semantic.light.primary.subtle}`, Color `{cortex.color.semantic.light.primary.default}`, Font Weight `{cortex.typography.fontWeight.semibold}`

- **Sections**:
  - Section Header: Font Size `{cortex.typography.fontSize.xs}`, Font Weight `{cortex.typography.fontWeight.semibold}`, Color `{cortex.color.semantic.light.text.tertiary}`, Padding `{cortex.spacing.4}` horizontal
  - Divider: `{cortex.borderWidth.thin}` solid `{cortex.color.semantic.light.border.subtle}`, Margin `{cortex.spacing.4}` vertical

### 5.3 Breadcrumbs

- **Visual Design**:
  - Font Size: `{cortex.typography.fontSize.sm}`
  - Color: `{cortex.color.semantic.light.text.secondary}`
  - Separator: "/" or "›" with color `{cortex.color.semantic.light.text.tertiary}`
  - Spacing: `{cortex.spacing.2}` between items

- **Item States**:
  - Default: Color `{cortex.color.semantic.light.text.secondary}`
  - Hover: Color `{cortex.color.semantic.light.text.primary}`, Text decoration underline
  - Current (last item): Color `{cortex.color.semantic.light.text.primary}`, Font Weight `{cortex.typography.fontWeight.medium}`, Not clickable

### 5.4 Tabs

- **Visual Design**:
  - Border Bottom: `{cortex.borderWidth.thin}` solid `{cortex.color.semantic.light.border.default}`
  - Tab Item Padding: `{cortex.spacing.3}` vertical, `{cortex.spacing.6}` horizontal
  - Font Size: `{cortex.typography.fontSize.base}`

- **Tab States**:
  - Default: Color `{cortex.color.semantic.light.text.secondary}`
  - Hover: Color `{cortex.color.semantic.light.text.primary}`, Background `{cortex.color.semantic.light.background.secondary}`
  - Active: Color `{cortex.color.semantic.light.primary.default}`, Border Bottom `{cortex.borderWidth.medium}` solid `{cortex.color.semantic.light.primary.default}`, Font Weight `{cortex.typography.fontWeight.semibold}`
  - Disabled: Color `{cortex.color.semantic.light.text.disabled}`, Cursor not-allowed

### 5.5 Pagination

- **Visual Design**:
  - Display: Flex, Align center
  - Gap: `{cortex.spacing.2}`

- **Page Button**:
  - Size: `{cortex.sizing.buttonHeight.sm}` × `{cortex.sizing.buttonHeight.sm}`
  - Border Radius: `{cortex.borderRadius.md}`
  - Font Size: `{cortex.typography.fontSize.sm}`
  - Border: `{cortex.borderWidth.thin}` solid `{cortex.color.semantic.light.border.default}`
  - Hover: Background `{cortex.color.semantic.light.background.secondary}`
  - Active (current page): Background `{cortex.color.semantic.light.primary.default}`, Color `{cortex.color.semantic.light.text.inverse}`, Font Weight `{cortex.typography.fontWeight.semibold}`

- **Prev/Next Buttons**:
  - Text: "Previous" / "Next" or "‹" / "›" icons
  - Same styling as page buttons

---

## 6. Additional Components

### 6.1 Avatar

- **Sizes**: Use `{cortex.sizing.avatarSize.*}`
- Border Radius: `{cortex.borderRadius.full}` (circular)
- Border: `{cortex.borderWidth.thin}` solid `{cortex.color.semantic.light.border.default}`
- Fallback: User initials on colored background or placeholder icon

### 6.2 Badge

- **Visual Design**:
  - Padding: `{cortex.spacing.1}` vertical, `{cortex.spacing.2}` horizontal
  - Border Radius: `{cortex.borderRadius.full}`
  - Font Size: `{cortex.typography.fontSize.xs}`
  - Font Weight: `{cortex.typography.fontWeight.semibold}`
  - Line Height: 1

- **Variants**: Primary, Success, Warning, Error, Info (using semantic colors)

### 6.3 Modal/Dialog

- **Overlay**:
  - Background: `{cortex.color.semantic.light.background.overlay}`
  - Z-Index: `{cortex.zIndex.overlay}`
  - Position: Fixed, Full viewport

- **Modal Container**:
  - Background: `{cortex.color.semantic.light.surface.raised}`
  - Border Radius: `{cortex.borderRadius.xl}`
  - Shadow: `{cortex.shadow.2xl}`
  - Max Width: 600px (adjustable)
  - Padding: `{cortex.spacing.8}`
  - Z-Index: `{cortex.zIndex.modal}`
  - Position: Centered in viewport

- **Animation**:
  - Overlay: Fade in `{cortex.animation.duration.normal}`
  - Modal: Scale from 0.95 to 1.0 + fade in `{cortex.animation.duration.normal}` `{cortex.animation.easing.spring}`

### 6.4 Tooltip

- **Visual Design**:
  - Background: `{cortex.color.semantic.light.text.primary}`
  - Color: `{cortex.color.semantic.light.text.inverse}`
  - Padding: `{cortex.spacing.2}` vertical, `{cortex.spacing.3}` horizontal
  - Border Radius: `{cortex.borderRadius.md}`
  - Font Size: `{cortex.typography.fontSize.sm}`
  - Max Width: 200px
  - Z-Index: `{cortex.zIndex.tooltip}`
  - Arrow: 8px triangle pointing to trigger element

- **Animation**:
  - Delay: 500ms before showing
  - Fade in: `{cortex.animation.duration.fast}` `{cortex.animation.easing.easeOut}`
  - Fade out: `{cortex.animation.duration.fast}` `{cortex.animation.easing.easeIn}`

### 6.5 Loading Spinner

- **Visual Design**:
  - Size: `{cortex.sizing.iconSize.md}` (adjustable)
  - Color: `{cortex.color.semantic.light.primary.default}` or current text color
  - Animation: Rotate 360deg, Duration `{cortex.animation.duration.slower}`, Easing `{cortex.animation.easing.linear}`, Infinite

### 6.6 Progress Bar

- **Visual Design**:
  - Background: `{cortex.color.semantic.light.background.tertiary}`
  - Height: 8px
  - Border Radius: `{cortex.borderRadius.full}`
  - Fill: `{cortex.color.semantic.light.primary.default}`
  - Animation: Smooth transition `{cortex.animation.duration.normal}` `{cortex.animation.easing.easeOut}`

---

## 7. Responsive Behavior

All components should adapt to different screen sizes using the defined breakpoints:

- **Mobile (< sm)**: Single column layouts, full-width components, touch-friendly sizes
- **Tablet (md)**: Hybrid layouts, side navigation may collapse to icon-only
- **Desktop (lg+)**: Full layouts with side navigation expanded

### Touch Targets
- Minimum: 44×44px (WCAG 2.1 Level AAA)
- Recommended: 48×48px for primary interactive elements

---

## 8. Accessibility Requirements

All components must meet WCAG 2.1 Level AA standards:

### Keyboard Navigation
- All interactive elements must be keyboard accessible
- Tab order must be logical
- Focus indicators must be visible (`{cortex.shadow.focus}`)
- Escape key closes modals/dropdowns
- Enter/Space activates buttons

### Screen Readers
- Use semantic HTML elements
- Provide `aria-label` for icon-only buttons
- Use `aria-describedby` for form errors and helper text
- Use `role` attributes where semantic HTML is insufficient
- Announce dynamic content changes with `aria-live`

### Color Contrast
- Text on backgrounds must meet 4.5:1 ratio (7:1 for AAA)
- Interactive elements must meet 3:1 ratio against adjacent colors
- Do not rely on color alone to convey information

---

## 9. Dark Mode

All components have dark mode variants defined in the design tokens under `{cortex.color.semantic.dark.*}`. 

**Implementation**:
- Use CSS custom properties or theme context
- Toggle between `.light-theme` and `.dark-theme` classes on root element
- All color references should use semantic tokens, not primitive colors directly

**Transition**:
- Color transitions: `{cortex.animation.duration.fast}` `{cortex.animation.easing.easeOut}`

---

## 10. Motion & Animation Guidelines

### When to Animate
- State changes (hover, active, focus)
- Component entrances and exits
- Loading states
- Feedback for user actions

### When NOT to Animate
- Page loads (initial render)
- Respect `prefers-reduced-motion` user preference
- Static content updates

### Animation Principles
- **Purposeful**: Every animation should have a clear purpose
- **Subtle**: Animations should enhance, not distract
- **Fast**: Keep durations short (150-350ms for most interactions)
- **Smooth**: Use appropriate easing functions
- **Respectful**: Honor accessibility preferences

---

## Implementation Notes

### CSS Custom Properties Example
```css
:root.light-theme {
  --color-primary: #5155e6;
  --color-background: #ffffff;
  --shadow-md: 0 4px 6px -1px rgba(0, 0, 0, 0.1);
}

:root.dark-theme {
  --color-primary: #8b5cf6;
  --color-background: #020617;
  --shadow-md: 0 4px 6px -1px rgba(0, 0, 0, 0.3);
}
```

### React/Component Library
- Use the design tokens as source of truth
- Build theme provider for context-based theming
- Create compound components for complex patterns
- Expose style variants as props
- Support className overrides for customization

### Native Mobile
- Scale tokens appropriately for mobile density
- Use platform-specific components where appropriate
- Maintain semantic consistency across platforms
- Test on various screen sizes and densities

---

## Version History

**1.0.0** (2026-01-16)
- Initial component specifications
- Defined buttons, inputs, cards, notifications, and navigation
- Established accessibility and responsive guidelines
