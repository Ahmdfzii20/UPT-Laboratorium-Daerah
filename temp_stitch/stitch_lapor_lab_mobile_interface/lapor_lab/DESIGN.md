---
name: Lapor Lab
colors:
  surface: '#f7fafc'
  surface-dim: '#d7dadc'
  surface-bright: '#f7fafc'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f1f4f6'
  surface-container: '#ebeef0'
  surface-container-high: '#e5e9eb'
  surface-container-highest: '#e0e3e5'
  on-surface: '#181c1e'
  on-surface-variant: '#3f484c'
  inverse-surface: '#2d3133'
  inverse-on-surface: '#eef1f3'
  outline: '#70787c'
  outline-variant: '#bfc8cc'
  surface-tint: '#19677b'
  primary: '#004251'
  on-primary: '#ffffff'
  primary-container: '#005b6f'
  on-primary-container: '#8ed1e8'
  inverse-primary: '#8dd0e7'
  secondary: '#555f71'
  on-secondary: '#ffffff'
  secondary-container: '#d6e0f6'
  on-secondary-container: '#596376'
  tertiary: '#5b3200'
  on-tertiary: '#ffffff'
  tertiary-container: '#774815'
  on-tertiary-container: '#fbba7c'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#b4ebff'
  primary-fixed-dim: '#8dd0e7'
  on-primary-fixed: '#001f27'
  on-primary-fixed-variant: '#004e5f'
  secondary-fixed: '#d9e3f9'
  secondary-fixed-dim: '#bdc7dc'
  on-secondary-fixed: '#121c2c'
  on-secondary-fixed-variant: '#3d4759'
  tertiary-fixed: '#ffdcc0'
  tertiary-fixed-dim: '#fbb97c'
  on-tertiary-fixed: '#2d1600'
  on-tertiary-fixed-variant: '#683c09'
  background: '#f7fafc'
  on-background: '#181c1e'
  surface-variant: '#e0e3e5'
typography:
  headline-lg:
    fontFamily: Inter
    fontSize: 24px
    fontWeight: '700'
    lineHeight: 32px
  headline-md:
    fontFamily: Inter
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
  title-sm:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '600'
    lineHeight: 24px
  body-md:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-sm:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  label-md:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
    letterSpacing: 0.5px
  status-badge:
    fontFamily: Inter
    fontSize: 11px
    fontWeight: '700'
    lineHeight: 12px
    letterSpacing: 0.2px
rounded:
  sm: 0.125rem
  DEFAULT: 0.25rem
  md: 0.375rem
  lg: 0.5rem
  xl: 0.75rem
  full: 9999px
spacing:
  base: 4px
  unit-1: 4px
  unit-2: 8px
  unit-3: 12px
  unit-4: 16px
  unit-6: 24px
  unit-8: 32px
  touch-target: 48px
  margin-mobile: 16px
  gutter: 12px
---

## Brand & Style
The design system is engineered for the Indonesian public health sector, specifically for laboratory staff within the Puskesmas network. The personality is **institutional, professional, and precise**, prioritizing utility over ornamentation. It avoids consumer-oriented "startup" trends in favor of a **Corporate Modern** aesthetic that aligns with Ministry of Health (Kemenkes) standards.

The interface evokes a sense of **responsibility and calm**, reducing cognitive load during the data entry process. The visual language is structured, using clear boundaries and a disciplined grid to signal reliability and data integrity.

## Colors
The palette is rooted in a **Deep Teal Primary (#005B6F)**, conveying institutional authority and medical professionalism. 

- **Background:** A clean off-white (#F7FAFC) to reduce screen glare during extended use.
- **Surface:** Pure white (#FFFFFF) for interactive cards and form containers to provide maximum contrast.
- **Functional States:** Status colors are strictly mapped to reporting phases:
    - **Gray (Draft):** Neutral, inactive.
    - **Red (Late):** High urgency.
    - **Green (Sent):** Success/Completion.
    - **Yellow (Revision):** Warning/Attention required.
    - **Dark Gray (Locked):** Finalized, read-only state.

## Typography
This design system utilizes **Inter** for its exceptional legibility in data-heavy environments. The scale is optimized for high-density information display and form input clarity.

- **Headlines:** Used for page titles and section headers to establish a clear information hierarchy.
- **Body:** Standardized at 16px for readability on mobile devices.
- **Labels:** Used for form field descriptors and metadata.
- **Status Badges:** Small-caps or bold condensed styling to ensure visibility without occupying excessive screen real estate.

## Layout & Spacing
The system follows a **strict 4px/8px grid**. All margins and paddings must be multiples of 4. 

- **Touch Targets:** All interactive elements (buttons, checkboxes, list items) must maintain a minimum height/width of **48px** to ensure accessibility in clinical environments where staff may be moving quickly.
- **Padding:** Standard container padding is 16px (unit-4). Internal card padding should be 12px (unit-3) to maximize content density while maintaining air.
- **Mobile Layout:** A single-column fluid layout with 16px side margins. Elements reflow vertically to accommodate longer Indonesian medical terminology.

## Elevation & Depth
The design system employs **Tonal Layers** and **Low-Contrast Outlines** to minimize visual noise.

- **Cards:** Use a 1px border (#E2E8F0) with a very subtle, diffused shadow (Blur 4px, Y 2px, 5% opacity) to lift content from the background without creating a "floating" effect.
- **Modals & Bottom Sheets:** These use a more pronounced elevation to signify temporary interruption and focus.
- **Depth Hierarchy:** The background is the lowest level, followed by cards/containers, and finally primary action buttons at the highest elevation.

## Shapes
The shape language is **Soft (0.25rem/4px)**. This provides a clean, professional appearance that feels structured rather than playful.

- **Standard Elements:** Input fields, buttons, and cards use a 4px corner radius.
- **Status Badges:** Use a slightly higher radius (8px) or a pill-shape to differentiate them from interactive elements.
- **Search Bars:** 8px radius to subtly distinguish them from data entry fields.

## Components
- **Status Badges:** Use a background color at 15% opacity of the status color, with the text color at 100% opacity for maximum accessibility and professional tone.
- **Form Fields:** Must include a clear label, a placeholder, and support for numeric-only keyboards where data entry is required. Active fields are highlighted with the Primary Deep Teal border.
- **Action Bars:** Primary actions (e.g., "Kirim Laporan") are placed in a fixed bottom bar with a solid Primary background. This ensures the main objective is always reachable.
- **Cards:** Dashboard items should clearly display the Reporting Month, Status Badge, and Completion Percentage.
- **Search Bars:** Minimalist design with a subtle 1px border and a standard search icon (20px).
- **Empty States:** Use simplified, grayscale icons with clear instructional text (e.g., "Belum ada laporan untuk bulan ini").
- **Lists:** High-density list items with 16px vertical padding and a clear divider line (#EDF2F7).