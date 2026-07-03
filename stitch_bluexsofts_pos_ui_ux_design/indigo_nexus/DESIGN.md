---
name: Indigo Nexus
colors:
  surface: '#131313'
  surface-dim: '#131313'
  surface-bright: '#393939'
  surface-container-lowest: '#0e0e0e'
  surface-container-low: '#1c1b1b'
  surface-container: '#201f1f'
  surface-container-high: '#2a2a2a'
  surface-container-highest: '#353534'
  on-surface: '#e5e2e1'
  on-surface-variant: '#c8c4d7'
  inverse-surface: '#e5e2e1'
  inverse-on-surface: '#313030'
  outline: '#928ea0'
  outline-variant: '#474554'
  surface-tint: '#c6bfff'
  primary: '#c6bfff'
  on-primary: '#2900a0'
  primary-container: '#6c5ce7'
  on-primary-container: '#faf6ff'
  inverse-primary: '#5847d2'
  secondary: '#4bddb7'
  on-secondary: '#00382b'
  secondary-container: '#02b894'
  on-secondary-container: '#004233'
  tertiary: '#f0bf63'
  on-tertiary: '#412d00'
  tertiary-container: '#926b15'
  on-tertiary-container: '#fff6ee'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#e4dfff'
  primary-fixed-dim: '#c6bfff'
  on-primary-fixed: '#160066'
  on-primary-fixed-variant: '#4029ba'
  secondary-fixed: '#6dfad2'
  secondary-fixed-dim: '#4bddb7'
  on-secondary-fixed: '#002018'
  on-secondary-fixed-variant: '#005140'
  tertiary-fixed: '#ffdea7'
  tertiary-fixed-dim: '#f0bf63'
  on-tertiary-fixed: '#271900'
  on-tertiary-fixed-variant: '#5e4200'
  background: '#131313'
  on-background: '#e5e2e1'
  surface-variant: '#353534'
typography:
  display-lg:
    fontFamily: Be Vietnam Pro
    fontSize: 48px
    fontWeight: '700'
    lineHeight: 56px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Be Vietnam Pro
    fontSize: 32px
    fontWeight: '600'
    lineHeight: 40px
    letterSpacing: -0.01em
  headline-lg-mobile:
    fontFamily: Be Vietnam Pro
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
  title-md:
    fontFamily: Be Vietnam Pro
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
  body-lg:
    fontFamily: Be Vietnam Pro
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-sm:
    fontFamily: Be Vietnam Pro
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  label-md:
    fontFamily: Be Vietnam Pro
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
    letterSpacing: 0.05em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  base: 8px
  xs: 4px
  sm: 12px
  md: 16px
  lg: 24px
  xl: 32px
  gutter: 20px
  margin-mobile: 16px
  margin-desktop: 40px
---

## Brand & Style
The design system is engineered for high-performance retail environments, prioritizing speed, clarity, and reliability. The aesthetic draws heavily from **Modern Minimalism** with a focus on functional elegance, similar to industry leaders like Square and Shopify. 

The primary emotional response should be one of "effortless control." By utilizing expansive whitespace and a structured information hierarchy, the interface reduces cognitive load for operators in fast-paced settings. The style employs subtle depth through layered surfaces rather than heavy ornamentation, ensuring that the focus remains entirely on the merchant's data and customer interactions.

## Colors
The color strategy utilizes a "Deep Night" palette for the primary dark mode, where the background sits at a near-black `#121212` and primary containers sit at `#1E1E2E` to provide soft contrast.

- **Primary Indigo (#6C5CE7):** Used for primary actions, active states, and brand identifiers.
- **Success Green (#00B894):** Reserved for completed transactions, positive growth trends, and "In Stock" statuses.
- **Warning Amber (#FDCB6E):** Denotes low stock, pending payments, or system alerts.
- **Error Red (#D63031):** Used for voided transactions, critical errors, and "Out of Stock" indicators.

For the light theme variant, the primary Indigo remains the core accent, while surfaces shift to high-grey neutrals (`#F8F9FD`) to maintain the professional, clinical feel.

## Typography
This design system utilizes **Be Vietnam Pro** (as a high-quality alternative to Poppins) to achieve a modern, geometric, and highly readable feel. 

Headlines are slightly tightened with negative letter spacing to feel more "industrial" and authoritative. Body text maintains generous line heights to ensure legibility during rapid scanning of inventory lists and customer receipts. Labels use a semi-bold weight and increased letter spacing to clearly differentiate metadata from primary content.

## Layout & Spacing
The design system employs a **Fluid-Fixed Hybrid Grid**. 

- **Desktop & Tablet:** A 12-column grid with a fixed sidebar (280px). Content spans the remaining fluid width. Side navigation is the primary anchor for administrative tasks.
- **Mobile:** A single-column layout with a fixed bottom navigation bar for quick thumb-reach access.
- **Spacing Rhythm:** Based on an 8px baseline. Use `16px (md)` for standard internal card padding and `24px (lg)` for spacing between distinct sections or widgets. 

Product grids should utilize an "Aspect Ratio" lock (1:1) for product imagery to maintain vertical alignment regardless of device width.

## Elevation & Depth
Depth is expressed through **Tonal Layering** and **Ambient Shadows**. 

In the dark theme, avoid pure black shadows. Instead, use shadows with a deep indigo tint (`#000000` at 40% opacity with a slight purple hue) to maintain vibrancy. 
- **Level 1 (Cards):** Resting on the background with a 1px border (`#FFFFFF10`) and no shadow.
- **Level 2 (Hover/Active):** 8px blur, 4px Y-offset shadow to simulate lifting.
- **Level 3 (Modals/Bottom Sheets):** 24px blur, 12px Y-offset shadow.

Backdrop blurs (12px) should be applied to modals and top-level navigation headers to maintain context of the underlying data while focusing the user's attention.

## Shapes
The shape language is characterized by **Generous Roundedness**. 

All primary containers, including stat cards and product tiles, use a minimum of `16px` (rounded-lg) corner radius. This creates a friendly, approachable tactile feel. Buttons and input fields follow suit at `8px` (rounded-md) to ensure they feel like distinct, interactive elements within the larger containers. Status badges and tags use a fully "Pill" shape (32px+) to distinguish them from actionable buttons.

## Components
- **Stat Cards:** Feature a large `display-lg` metric, a small line sparkline chart, and a color-coded percentage change label. 
- **Product Grid:** Images should have a `rounded-lg` clip. Price should be highlighted using the Primary Indigo text color.
- **Data Tables:** On mobile, these must transform into "Expandable Cards." Each row becomes a card header, with secondary details hidden behind a chevron-toggle.
- **Floating Action Buttons (FAB):** Used exclusively for "New Transaction" or "Add Product." These are large, circular, and use the Primary Indigo background with a high-elevation shadow.
- **Bottom Sheets:** Used on mobile for product modifiers or quick-filters. They must have a "grabber" handle at the top and `24px` top-corner rounding.
- **Input Fields:** Use a solid background (`#FFFFFF05`) with a 1px bottom-border highlight that glows Primary Indigo when focused.