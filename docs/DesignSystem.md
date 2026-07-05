# DesignSystem.md
**Project:** SpendMind iOS
**Phase:** 2 — Design System
**Version:** 1.0

---

# Goal

Phase 2 focuses on building a scalable, reusable, and fully native Design System before implementing any application features.

Everything in the app must use this design system.

No hardcoded colors.

No hardcoded fonts.

No hardcoded spacing.

No direct SF Symbols.

No inline styling.

Views only consume Design System components.

---

# Architecture

```
Presentation
│
├── DesignSystem
│     ├── Colors
│     ├── Typography
│     ├── Icons
│     ├── Spacing
│     ├── Radius
│     ├── Shadows
│     ├── Components
│     ├── Animations
│     ├── Extensions
│     └── Theme
│
├── Screens
│
└── Shared UI
```

---

# Folder Structure

```
Sources/

Presentation/

    DesignSystem/

        Colors/
            ColorPalette.swift
            SemanticColors.swift

        Typography/
            Typography.swift
            FontStyle.swift

        Icons/
            AppIcon.swift

        Spacing/
            Spacing.swift

        Radius/
            Radius.swift

        Shadow/
            Shadow.swift

        Components/

            Buttons/
                PrimaryButton.swift
                SecondaryButton.swift
                IconButton.swift

            TextField/
                AppTextField.swift

            Card/
                CardView.swift

            Chips/
                Chip.swift

            Avatar/
                Avatar.swift

            Divider/
                Divider.swift

            Loading/
                LoadingView.swift

            EmptyState/
                EmptyState.swift

            Tag/
                Tag.swift

            BottomSheet/
                BottomSheet.swift

            Navigation/
                NavigationBar.swift

        Animation/
            Animation.swift

        Theme/
            Theme.swift

        Preview/
```

---

# Design Tokens

Everything comes from Tokens.

Never use literal values.

Wrong

```swift
.padding(16)
.foregroundColor(.blue)
.cornerRadius(12)
```

Correct

```swift
.padding(.md)
.foregroundColor(.primary)
.cornerRadius(.medium)
```

---

# Color Palette

Only define raw colors once.

Example

```swift
enum Palette {

    static let blue500
    static let blue600

    static let green500

    static let red500

    static let gray50
    static let gray100
    static let gray900

}
```

No screen should ever access Palette directly.

---

# Semantic Colors

Views consume semantic colors only.

Example

```swift
Color.primary

Color.secondary

Color.background

Color.surface

Color.border

Color.success

Color.warning

Color.error

Color.info

Color.textPrimary

Color.textSecondary

Color.disabled

Color.placeholder
```

Dark Mode handled automatically.

---

# Typography

Only predefined typography styles.

```
LargeTitle

Title1

Title2

Title3

Headline

Body

BodyBold

Callout

Caption

Caption2

Footnote

Button

Label
```

Usage

```swift
Text("Balance")
    .appFont(.headline)
```

Never

```swift
.font(.system(size:17))
```

---

# Font Rules

Preferred

SF Pro

Future

Allow custom fonts through Theme.

---

# Spacing Scale

Use 8pt grid.

```
0

2

4

8

12

16

20

24

32

40

48

64
```

Expose as

```swift
Spacing.xs
Spacing.sm
Spacing.md
Spacing.lg
Spacing.xl
```

Usage

```swift
.padding(Spacing.md)
```

---

# Radius

```
None

Small

Medium

Large

XL

Pill
```

Example

```swift
.cornerRadius(Radius.medium)
```

---

# Shadow

Predefined shadows.

```
Small

Medium

Large

Floating
```

Never create inline shadows.

Wrong

```swift
.shadow(radius:8)
```

Correct

```swift
.shadow(.medium)
```

---

# Icons

Wrap every SF Symbol.

Never expose raw symbol names.

Wrong

```swift
Image(systemName:"plus")
```

Correct

```swift
AppIcon.plus
```

Benefits

- Easy replacement

- Consistency

- Future custom icons

---

# Button Components

## Primary Button

Used for

Main CTA

Supports

- loading
- disabled
- icon
- full width

API

```swift
PrimaryButton(
    title:
    action:
)
```

---

## Secondary Button

Outlined

---

## Text Button

No background.

---

## Icon Button

Square

Circle

Filled

Outlined

---

# TextField

Reusable.

Supports

- placeholder

- secure

- currency

- number

- multiline

- validation

- prefix

- suffix

- error

- helper text

- focus state

---

# Card

Reusable Card component.

Supports

```
padding

shadow

border

radius

tap
```

---

# List Item

Reusable.

Supports

Leading

Title

Subtitle

Trailing

Disclosure

Badge

Icon

---

# Chips

Variants

```
Selected

Unselected

Disabled
```

---

# Tags

Variants

```
Income

Expense

AI

Budget

Warning

Success
```

---

# Avatar

Supports

```
Image

Placeholder

Initials

Size
```

---

# Divider

Horizontal

Vertical

Inset

---

# Empty State

Reusable.

Contains

```
Illustration

Title

Subtitle

Button
```

---

# Loading

Variants

```
Spinner

Skeleton

Shimmer
```

---

# Bottom Sheet

Reusable.

Supports

```
Height

Drag

Dismiss

Actions

Scrollable
```

---

# Navigation Bar

Custom wrapper.

Supports

```
Title

Large Title

Leading

Trailing

Search
```

---

# Toast

Reusable.

Variants

```
Success

Error

Info

Warning
```

---

# Alert

Custom Alert.

Never use UIKit alert directly unless necessary.

---

# Animations

Centralized.

```
Fast

Normal

Slow

Spring

Bounce
```

Usage

```swift
.withAnimation(.appSpring)
```

---

# Accessibility

Every component must support

VoiceOver

Dynamic Type

High Contrast

Reduce Motion

Minimum touch area

44x44

Accessibility labels

Accessibility hints

---

# Dark Mode

Mandatory.

Every component must support

```
Light

Dark
```

No exceptions.

---

# Localization

No hardcoded strings.

Wrong

```swift
Text("Add Expense")
```

Correct

```swift
L10n.addExpense
```

---

# Preview

Every reusable component must include Preview.

Example

```
#Preview {

    PrimaryButton()

}
```

---

# Component States

Each reusable component must preview

Default

Pressed

Disabled

Loading

Error

Selected

Dark Mode

Dynamic Type

RTL (future)

---

# Performance

Views should be lightweight.

Avoid nested GeometryReader.

Avoid AnyView.

Avoid unnecessary redraws.

---

# Naming Convention

Good

```
PrimaryButton

ExpenseCard

BalanceView

EmptyTransactionView
```

Bad

```
Button1

Card2

NewView

CustomView
```

---

# Reusability Rules

A component should become reusable when

- used twice

OR

- expected to be reused

Never duplicate UI.

---

# Theme Support

Future support

```
Default Theme

Dark Theme

Premium Theme

Seasonal Theme
```

No screen should know theme implementation.

---

# Acceptance Criteria

- No hardcoded colors.
- No hardcoded spacing.
- No hardcoded fonts.
- No direct SF Symbols.
- All UI uses semantic tokens.
- Every component supports Dark Mode.
- Every component has SwiftUI Preview.
- Components are reusable and documented.
- Accessibility requirements are satisfied.
- Localization-ready architecture is in place.
- Theme layer can evolve without changing feature screens.

---

# Deliverables

At the end of Phase 2, the following should exist:

- ✅ Color Palette
- ✅ Semantic Colors
- ✅ Typography System
- ✅ Spacing Tokens
- ✅ Radius Tokens
- ✅ Shadow Tokens
- ✅ Icon Wrapper
- ✅ Primary/Secondary/Icon Buttons
- ✅ AppTextField
- ✅ Card Component
- ✅ List Item Component
- ✅ Chip & Tag Components
- ✅ Avatar Component
- ✅ Divider Component
- ✅ Empty State Component
- ✅ Loading Components
- ✅ Toast & Alert Components
- ✅ Bottom Sheet Component
- ✅ Custom Navigation Bar
- ✅ Theme Infrastructure
- ✅ Animation Tokens
- ✅ SwiftUI Preview Coverage
- ✅ Accessibility Compliance
- ✅ Dark Mode Support
- ✅ Localization-ready Components

Phase 2 is complete only when every new screen can be assembled exclusively from these reusable components, with no ad hoc styling or duplicated UI code.