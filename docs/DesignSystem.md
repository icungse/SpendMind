# DesignSystem.md

**Project:** SpendMind iOS  
**Phase:** 2 - Design System  
**Version:** 1.0

---

# Goal

Keep UI consistent with the smallest shared design system that exists today.

Use shared tokens and components before adding new styling or new components.

---

# Current Implementation

The current design system lives in:

```text
SpendMind/Shared/
├── DesignSystem/
│   ├── AppColor.swift
│   ├── AppSpacing.swift
│   ├── AppShadow.swift
│   ├── Radius.swift
│   └── Typography.swift
└── Components/
    ├── Card.swift
    ├── EmptyState.swift
    ├── LoadingView.swift
    ├── PrimaryButton.swift
    ├── SecondaryButton.swift
    └── SectionHeader.swift
```

---

# Tokens

Use these types directly:

```swift
AppColor.primary
AppSpacing.md
Radius.medium
Typography.headline
AppShadow.small
```

Prefer:

```swift
Text("Balance")
    .appFont(.headline)
    .foregroundStyle(AppColor.textPrimary)
    .padding(AppSpacing.md)
```

Avoid:

```swift
Text("Balance")
    .font(.system(size: 17))
    .foregroundStyle(.blue)
    .padding(16)
```

---

# Colors

`AppColor` provides:

- Brand colors: `brandBlue`, `brandLavender`, `brandCream`, `brandOrange`
- Semantic colors: `primary`, `secondary`, `background`, `surface`, `surfaceAlt`, `border`
- Text colors: `textPrimary`, `textSecondary`, `textInverse`, `disabled`, `placeholder`
- Feedback colors: `success`, `warning`, `error`, `info`

Dark mode is handled inside `AppColor` where needed.

---

# Spacing

`AppSpacing` provides:

```swift
none, xxs, xs, sm, base, md, relaxed, lg, xl, xxl, xxxl, huge
```

Use tokens instead of literal spacing values.

---

# Typography

Use `.appFont(_:)` with `Typography`:

```swift
.largeTitle, .title1, .title2, .title3, .headline, .body, .bodyBold,
.callout, .caption, .caption2, .footnote, .button, .label
```

The current implementation maps to native SwiftUI fonts.

---

# Radius And Shadow

Use `Radius` for corner radii:

```swift
none, small, medium, large, xl, pill
```

Use `.appShadow(_:)` with `AppShadow`:

```swift
small, medium, large, floating
```

---

# Components

Current reusable components:

- `PrimaryButton`: full-width primary action with loading and disabled states
- `SecondaryButton`: full-width outlined action with loading and disabled states
- `Card`: padded surface with border and small shadow
- `EmptyState`: title, optional message, optional primary action
- `LoadingView`: progress indicator with optional title
- `SectionHeader`: title with optional subtitle

All current components have SwiftUI previews.

---

# Localization

Component text APIs use `LocalizedStringKey` where applicable.

Feature screens should pass localized strings or localization-ready keys.

---

# Accessibility

Current components include basic accessibility labels or grouped accessibility where useful.

Every new interactive component must include an accessibility label.

---

# Future Components

These are not implemented yet and are not current acceptance criteria:

- Icon wrapper
- App text field
- List item
- Chips and tags
- Avatar
- Divider
- Toast and alert
- Bottom sheet
- Custom navigation bar
- Theme layer
- Animation tokens

Add them only when a real screen needs them.

---

# Rules

- Use existing tokens before adding new ones.
- Use existing components before creating new components.
- Add a new component when it is used twice or clearly needed by an accepted task.
- Keep component APIs small.
- Add a preview for every reusable component.
- Do not add theme or icon infrastructure until a screen needs it.

---

# Current Deliverables

Implemented:

- Color tokens
- Typography tokens
- Spacing tokens
- Radius tokens
- Shadow tokens
- Primary and secondary buttons
- Card
- Empty state
- Loading view
- Section header
- SwiftUI previews for current components
- Basic dark mode support through `AppColor`

Not implemented yet:

- Icon wrapper
- Text field
- List item
- Chips and tags
- Avatar
- Divider
- Toast and alert
- Bottom sheet
- Custom navigation bar
- Theme layer
- Animation tokens

<!-- ponytail: this document describes current code, not a wishlist. Add sections when matching code exists. -->
