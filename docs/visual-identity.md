# Cortex Platform: Visual Identity & Design System

_Date: 2026-01-16_  
_Version: 1.0_

## Executive Summary

This document establishes the visual identity and design system for the Cortex Platform—a personal AI assistant that orchestrates attention, tasks, and automation across devices. The visual direction emphasizes **calm intelligence**, **professional trust**, and **seamless orchestration** while avoiding overly technical or distracting aesthetics.

**Key Decision:** Replace the brain emoji (🧠) with a more sophisticated identity that conveys distributed intelligence and orchestration rather than literal brain/cognition metaphors.

---

## 1. Core Visual Principles

### 1.1 Design Philosophy

The Cortex visual identity is guided by these core principles:

1. **Calm Intelligence**  
   - Cortex manages attention and works in the background—visuals should be calming, not attention-grabbing
   - Avoid bright, energetic colors that create visual noise
   - Use subtle sophistication over bold statements

2. **Trustworthy Orchestration**  
   - Acting on the user's behalf requires deep trust
   - Professional, reliable aesthetic
   - Clear hierarchy and purposeful design decisions

3. **Adaptive Sophistication**  
   - Multi-surface platform (desktop, mobile, notifications, voice)
   - Visual system must work across contexts without losing coherence
   - Sophistication that scales from system tray icons to full dashboard displays

4. **Human-Centered, Not Machine-Centered**  
   - Avoid stereotypical "AI" aesthetics (circuit boards, matrix effects, glowing neon)
   - Focus on human outcomes: clarity, focus, flow state
   - Technology in service of people, not technology for its own sake

---

## 2. Icon & Logo System

### 2.1 Primary Mark: "The Nexus"

**Concept:** A refined geometric mark representing the central orchestration point—the nexus where all inputs, contexts, and actions converge.

**Visual Description:**
- **Form:** Concentric geometric shapes suggesting layers of context and awareness
- **Structure:** Three elements:
  - **Outer ring:** Represents the ecosystem of inputs/outputs (chat, voice, apps, notifications)
  - **Middle connection points:** 6-8 subtle nodes representing domain experts and integrations
  - **Central focal point:** The core—a calm, centered presence

**Why This Works:**
- Conveys distributed intelligence without literal brain imagery
- Suggests orchestration, connectivity, and flow
- Scales beautifully from 16px (system tray) to large format
- Abstract enough to avoid dated tech clichés
- Professional and memorable

**Alternate Approach: Wordmark Only**
- For contexts where iconography feels forced, use a refined "CORTEX" wordmark
- Custom letterforms with subtle connection details in the "C" and "X"
- Allows flexibility: icon alone, wordmark alone, or combined lockup

### 2.2 Usage Guidelines

**Primary Lockup:**
```
[Icon]  CORTEX
        Intelligent Orchestration
```

**Compact Usage:**
- Icon only for: system tray, mobile app icon, notification badges
- Wordmark only for: document headers, email signatures, admin interfaces

**Never:**
- Don't add gradients to the icon
- Don't rotate or skew
- Don't use emoji as brand marks (🧠 ❌)

---

## 3. Color Palette

### 3.1 Foundation Colors

The Cortex palette moves away from vibrant purple gradients toward a sophisticated, calming foundation with intelligent accent usage.

#### Primary Palette

**Slate Foundation** (Neutral base for all surfaces)
```
Slate 950:  #0f172a  — Primary text, highest emphasis
Slate 900:  #1e293b  — UI elements, cards, elevated surfaces
Slate 800:  #334155  — Borders, dividers
Slate 700:  #475569  — Secondary text
Slate 600:  #64748b  — Tertiary text, placeholders
Slate 500:  #94a3b8  — Disabled states
Slate 400:  #cbd5e1  — Subtle borders
Slate 300:  #e2e8f0  — Hover states, backgrounds
Slate 200:  #f1f5f9  — Canvas, page backgrounds
Slate 100:  #f8fafc  — Bright backgrounds
Slate 50:   #fafbfc  — Lightest surface
```

**Indigo Accent** (Intelligence, focus, primary actions)
```
Indigo 600: #4f46e5  — Primary CTA, links, focus states
Indigo 500: #6366f1  — Hover states
Indigo 400: #818cf8  — Selected states
Indigo 50:  #eef2ff  — Subtle highlights, info backgrounds
```

#### Semantic Colors

**Success** (Task completion, positive feedback)
```
Emerald 600: #059669  — Success text, icons
Emerald 50:  #ecfdf5  — Success backgrounds
```

**Warning** (Attention needed, non-critical)
```
Amber 600:  #d97706  — Warning text
Amber 50:   #fffbeb  — Warning backgrounds
```

**Error** (Critical issues, destructive actions)
```
Red 600:    #dc2626  — Error text
Red 50:     #fef2f2  — Error backgrounds
```

**Info** (System messages, helpful hints)
```
Blue 600:   #2563eb  — Info text
Blue 50:    #eff6ff  — Info backgrounds
```

### 3.2 Color Usage Philosophy

**Background Strategy:**
- **Light Mode:** Slate 50 for canvas, White (#ffffff) for cards
- **Dark Mode:** Slate 950 for canvas, Slate 900 for cards
- Prioritize dark mode as primary (attention management benefits from reduced eye strain)

**Accent Usage:**
- Indigo 600 sparingly—only for primary actions and focus
- Never use gradients as primary UI elements (gradients add visual noise)
- Allow one accent per view to guide attention clearly

**Context-Aware Color:**
- Notifications: Minimal color, rely on typography hierarchy
- Chat: Clean, document-like (no colorful chat bubbles)
- Dashboard: Strategic data visualization colors, not decorative colors
- Admin: Professional, table-focused layout

---

## 4. Typography

### 4.1 Font Family

**Primary Typeface: Inter**
- Modern, highly legible at all sizes
- Excellent for UI and data-heavy interfaces
- Open source, self-hostable
- Great variable font support

**Fallback Stack:**
```css
font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', 
             Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
```

**Monospace (for code, technical data):**
```css
font-family: 'JetBrains Mono', 'SF Mono', Monaco, 'Cascadia Code', 
             'Courier New', monospace;
```

### 4.2 Type Scale

**Desktop/Web:**
```
Display:    48px / 1.2 line-height, -0.02 letter-spacing, weight 700
Heading 1:  36px / 1.2, -0.01, 700
Heading 2:  30px / 1.3, -0.01, 600
Heading 3:  24px / 1.4, 0, 600
Heading 4:  20px / 1.5, 0, 600
Body Large: 18px / 1.6, 0, 400
Body:       16px / 1.6, 0, 400
Body Small: 14px / 1.5, 0, 400
Caption:    12px / 1.4, 0.01, 500
Label:      11px / 1.4, 0.02, 600 uppercase
```

**Mobile (scale down 10-15%):**
```
Display:    40px / 1.2, -0.02, 700
Heading 1:  32px / 1.2, -0.01, 700
Heading 2:  26px / 1.3, -0.01, 600
Heading 3:  22px / 1.4, 0, 600
[etc.]
```

### 4.3 Typography Principles

1. **Hierarchy Through Weight, Not Size Alone**  
   - Use font weight (400, 500, 600, 700) to create clear hierarchy
   - Avoid overusing large sizes—Cortex is about calm focus

2. **Generous Line Height**  
   - Body text at 1.6 line-height for comfortable reading
   - Allows breathing room, reduces visual tension

3. **Consistent Spacing**  
   - Vertical rhythm: multiples of 4px (4, 8, 12, 16, 24, 32, 48, 64)
   - Paragraph spacing: 1.5× line height

4. **Selective Emphasis**  
   - Bold for emphasis, not decoration
   - Italics sparingly (avoid in UI, acceptable in content)
   - Never use color alone to convey meaning (accessibility)

---

## 5. Overall Aesthetic & Mood

### 5.1 Aesthetic Keywords

**What Cortex IS:**
- Calm
- Sophisticated
- Trustworthy
- Orchestrated
- Intelligent
- Adaptive
- Professional
- Purposeful
- Clear
- Human-centered

**What Cortex IS NOT:**
- Flashy
- Playful
- Cluttered
- Corporate-sterile
- Overly technical
- Sci-fi themed
- Neon/glowing
- Gradient-heavy

### 5.2 Visual Metaphors

**Primary Metaphor: Orchestration**
- Not a "brain" that thinks for you
- Not a "robot" that executes commands
- An **orchestrator** that coordinates multiple instruments (domain experts, apps, inputs) into a harmonious experience

**Supporting Metaphors:**
- **Flow:** Seamless transitions between contexts, like water finding its path
- **Signal clarity:** Cutting through noise to surface what matters
- **Distributed intelligence:** Network of specialized experts, not monolithic AI
- **Attentive presence:** Always aware, never intrusive

### 5.3 Design Mood Board Reference

**Visual Inspiration (concepts, not literal designs):**
- **Linear (linear.app):** Calm, purposeful product design
- **Arc Browser:** Sophisticated without being sterile
- **Stripe Dashboard:** Data density with clarity
- **Notion:** Flexible, human-friendly interfaces
- **Raycast:** Keyboard-first, efficiency-focused

**Avoid:**
- Overly animated "AI" interfaces
- Chatbot aesthetics (colorful bubbles, bot avatars)
- Dark mode with neon accents
- Skeuomorphic or illustrative styles

---

## 6. Component Patterns & UI Guidelines

### 6.1 Layout Principles

**Information Hierarchy:**
1. Primary action/content: Most prominent, Indigo accent
2. Secondary information: Slate text, normal weight
3. Tertiary/metadata: Slate 600, small size

**Spacing System:**
```
xs:  4px   — Tight groupings (icon + label)
sm:  8px   — Related elements
md:  16px  — Standard component spacing
lg:  24px  — Section separation
xl:  32px  — Major section breaks
2xl: 48px  — Page-level spacing
3xl: 64px  — Hero sections
```

**Container Widths:**
- **Chat/Content:** Max 680px (optimal reading line length)
- **Dashboard:** Max 1400px (data density)
- **Settings/Forms:** Max 560px (focused input)

### 6.2 Elevation & Depth

**Avoid heavy shadows**—use subtle elevation:
```css
Card:         0 1px 3px rgba(15, 23, 42, 0.08)
Elevated:     0 4px 12px rgba(15, 23, 42, 0.10)
Modal:        0 20px 40px rgba(15, 23, 42, 0.15)
Dropdown:     0 8px 16px rgba(15, 23, 42, 0.12)
```

**In dark mode, use lighter borders instead of shadows:**
```css
Card border:  1px solid rgba(255, 255, 255, 0.08)
```

### 6.3 Interactive States

**Buttons:**
```
Primary (Indigo):
  Default:     bg-indigo-600 text-white
  Hover:       bg-indigo-500
  Active:      bg-indigo-700
  Disabled:    bg-slate-300 text-slate-500

Secondary (Ghost):
  Default:     text-slate-700 border border-slate-300
  Hover:       bg-slate-100 border-slate-400
  Active:      bg-slate-200
```

**Links:**
```
Default:       text-indigo-600 no-underline
Hover:         text-indigo-500 underline
Visited:       Same as default (avoid purple visited links)
```

**Focus States:**
- Always visible, never hide outlines
- Use ring offset for clarity: `ring-2 ring-indigo-500 ring-offset-2`

### 6.4 Iconography

**Style:**
- 24px default size (scales to 16px, 20px, 28px as needed)
- 1.5px stroke weight
- Rounded corners (consistent with overall geometric softness)
- **Source:** Lucide Icons (open source, React-friendly)

**Usage:**
- Icons support text, never replace it in primary navigation
- Use consistent icon set throughout (don't mix Lucide + Font Awesome)
- Color: Inherit from parent text color

---

## 7. Multi-Surface Adaptation

### 7.1 Web Admin Interface

**Primary Use:** Dashboard, settings, workspace management, admin controls

**Design Focus:**
- Data density with clarity (tables, metrics, logs)
- Keyboard navigation first, mouse second
- Professional, no-nonsense aesthetic
- Dark mode primary

**Layout:**
```
[Sidebar Navigation]  [Main Content Area]  [Context Panel]
      200px                  flexible              280px
```

### 7.2 Chat UI

**Primary Use:** Conversational interaction with Cortex Core

**Design Focus:**
- Clean, distraction-free reading experience
- Document-like formatting, not "chat bubbles"
- Clear attribution (user vs. Cortex vs. domain experts)
- Code syntax highlighting for technical responses

**Message Format:**
```
[Avatar] [Name] [Timestamp]
         Message content with comfortable line length
         and generous spacing between messages
```

**Avoid:**
- Colorful chat bubbles (blue for user, gray for AI)
- Overly conversational "bot personality" in UI
- Animations/typing indicators (unless explicitly needed for context)

### 7.3 Login & Onboarding

**Current Issue:** Vibrant purple gradient background feels dated

**Recommendation:**
```
Background:  Slate 950 (dark) or Slate 50 (light)
Card:        White elevated card with subtle shadow
Accent:      Indigo 600 for primary button
Logo:        Centered, wordmark + icon lockup
Tagline:     "Intelligent Orchestration" or "Your AI orchestrator"
```

**Minimal, focused:**
- No decorative gradients
- No background patterns
- Pure focus on credentials input

### 7.4 Windows Desktop Notifications

**Constraints:**
- System-level notifications, limited visual control
- Must be readable at a glance
- Icon must be recognizable at 16px × 16px

**Guidelines:**
- **Icon:** Simple, high-contrast version of Cortex mark
- **Title:** Clear, action-oriented (not "Cortex says...")
- **Body:** One sentence, direct
- **Priority:** Use system notification priority levels, don't over-notify

**Example:**
```
[Cortex Icon] Task Complete
Vendor analysis ready for review
```

### 7.5 Mobile Apps (Future)

**Adaptation Strategy:**
- Bottom navigation (thumb-friendly)
- Larger tap targets (48px minimum)
- Simplified layouts (less information density than desktop)
- Pull-to-refresh, swipe gestures
- Same color palette, adjusted contrast for outdoor visibility

### 7.6 Voice Interfaces (Future)

**Visual Component:**
- Minimal UI during voice interaction
- Waveform visualization (subtle, not distracting)
- Indigo accent for active listening state
- Large, readable text for voice responses

**Design Principle:** Visual UI supports voice, doesn't compete with it

---

## 8. Implementation Guidelines

### 8.1 Design Tokens

Establish a design token system (JSON/CSS variables) for consistency:

```json
{
  "color": {
    "brand": {
      "primary": "#4f46e5",
      "primary-hover": "#6366f1"
    },
    "neutral": {
      "50": "#fafbfc",
      "950": "#0f172a"
    }
  },
  "spacing": {
    "xs": "4px",
    "sm": "8px",
    "md": "16px"
  },
  "typography": {
    "font-family-base": "Inter, system-ui, sans-serif",
    "font-size-body": "16px"
  }
}
```

### 8.2 Component Library

**Build reusable components:**
- Button (primary, secondary, ghost, danger)
- Input (text, password, search)
- Card, Modal, Dropdown
- Table (sortable, filterable)
- Toast/Notification
- Badge, Avatar, Icon

**Framework-agnostic where possible:**
- Can start with React
- Design tokens allow porting to other frameworks

### 8.3 Accessibility Requirements

**WCAG 2.1 AA Minimum:**
- Color contrast: 4.5:1 for body text, 3:1 for large text
- Focus indicators: Always visible
- Keyboard navigation: Full functionality without mouse
- Screen reader support: Semantic HTML, ARIA labels
- Motion: Respect `prefers-reduced-motion`

**Testing:**
- Lighthouse accessibility score: 95+
- Keyboard-only navigation audit
- Screen reader testing (NVDA/JAWS)

### 8.4 Dark Mode

**Dark Mode as Primary:**
- Attention management benefits from reduced eye strain
- Professional users often work in low-light environments
- OLED-friendly (true blacks for mobile)

**Implementation:**
- Use CSS custom properties for theme switching
- Test all components in both modes
- Avoid pure black (#000000), use Slate 950 (#0f172a)

---

## 9. Brand Voice & Messaging

### 9.1 Tone of Voice

**Cortex speaks like:**
- A trusted advisor, not a servant or overlord
- Professional but not corporate
- Intelligent but not condescending
- Direct and clear, not verbose
- Helpful without being overeager

**Examples:**

✅ **Good:**  
"Your vendor analysis is ready. Three timing adjustments recommended."

❌ **Bad:**  
"Hey there! 👋 I've finished crunching the numbers on your vendor stuff! Want to take a peek? 😊"

### 9.2 Terminology

**Use:**
- "Workspace" (not "project" or "folder")
- "Conversation" (not "chat" or "thread")
- "Domain expert" (not "agent" or "bot")
- "Orchestrate" / "Coordinate" (not "manage" or "control")

**Avoid:**
- Anthropomorphic language ("Cortex thinks...")
- Overly technical jargon when speaking to users
- Marketing speak ("revolutionary," "game-changing")

### 9.3 Tagline Options

**Primary:**  
"Intelligent Orchestration"

**Alternatives:**
- "Your AI Orchestrator"
- "Orchestrating Intelligence"
- "Attention. Orchestrated."

**Avoid:**
- "AI-Powered Attention Management" (too generic)
- "Your Digital Brain" (conflicts with dropping brain metaphor)

---

## 10. Migration Path

### 10.1 Phase 1: Foundation (Immediate)

**Update login.html:**
- Replace purple gradient with Slate 50/950 background
- Update color scheme to Indigo primary
- Replace 🧠 emoji with "CORTEX" wordmark (temporary)
- Implement new typography scale

**Create design tokens file:**
- `styles/tokens.css` with CSS custom properties
- Document all colors, spacing, typography

### 10.2 Phase 2: Icon Development (Week 2-3)

**Commission or design primary icon:**
- Work with designer or design in-house
- Test at multiple sizes (16px, 24px, 32px, 128px)
- Export as SVG
- Create favicon, app icons, notification icons

**Implement icon across all touchpoints**

### 10.3 Phase 3: Component System (Month 2)

**Build component library:**
- Start with most-used components (Button, Input, Card)
- Document in Storybook or similar
- Implement dark mode toggle

**Refactor existing UI:**
- Apply new components to admin interface
- Update chat UI with new aesthetic
- Ensure accessibility compliance

### 10.4 Phase 4: Refinement (Ongoing)

**User testing:**
- Gather feedback on visual clarity
- Test notification readability
- Validate color contrast in real environments

**Iterate:**
- Adjust based on usage patterns
- Expand component library as needed
- Maintain consistency across new features

---

## 11. Summary: Key Decisions

### Replace Brain Emoji ✅
**With:** Geometric "Nexus" icon representing distributed intelligence and orchestration

### Color Palette ✅
- **Foundation:** Slate neutrals (calm, professional)
- **Accent:** Indigo 600 (intelligent, focused)
- **Avoid:** Vibrant gradients, multiple competing colors

### Typography ✅
- **Font:** Inter (legible, modern, open source)
- **Hierarchy:** Through weight and spacing, not size alone
- **Line height:** Generous (1.6 for body)

### Aesthetic ✅
- **Mood:** Calm intelligence, trustworthy orchestration
- **Metaphor:** Orchestra conductor, not brain/robot
- **References:** Linear, Arc, Stripe—purposeful, sophisticated product design

### Multi-Surface ✅
- **Dark mode primary** for attention management
- **Minimal notifications** (respect user attention)
- **Consistent identity** across web, desktop, future mobile/voice

---

## Appendix: Quick Reference

### Color Palette (Hex Codes)
```
Slate 950:  #0f172a
Slate 900:  #1e293b
Slate 50:   #fafbfc
Indigo 600: #4f46e5
Emerald 600:#059669
Amber 600:  #d97706
Red 600:    #dc2626
```

### Typography Scale (Desktop)
```
Display:  48px / 700
H1:       36px / 700
H2:       30px / 600
Body:     16px / 400
Caption:  12px / 500
```

### Spacing Scale
```
4px, 8px, 16px, 24px, 32px, 48px, 64px
```

### Component Examples
See implementation in `/amplifier-app-server/static/` for live examples.

---

**Document Ownership:** Design team, reviewed by product and engineering  
**Next Review:** After Phase 2 completion (icon development)  
**Questions?** Reference Cortex Platform Vision & Values document for strategic alignment
