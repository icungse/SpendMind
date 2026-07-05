# AGENTS.md

# SpendMind AI Coding Agent Guide

Version: 1.0

---

# Purpose

This document defines how AI coding agents should contribute to SpendMind.

The primary goal is consistency.

Every generated code must:

- follow Apple's best practices
- compile successfully
- be production ready
- be testable
- be modular
- never introduce unnecessary complexity

If multiple implementations exist, always choose the simplest architecture that satisfies the requirements.

---

# About SpendMind

SpendMind is an AI-powered personal expense tracker for iOS.

Core principles:

- Local First
- Privacy First
- Offline First
- No Login
- No Cloud
- AI runs on-device whenever possible
- Beautiful native experience

Target:

- iOS 18+
- Swift 6
- SwiftUI
- Observation framework
- SwiftData
- Foundation Models (Apple Intelligence)
- TipKit
- WidgetKit
- App Intents

---

# Project Documents

Before implementing anything, always read these documents.

Priority order:

1. PRD.md
2. Architecture.md
3. DataModel.md
4. CodingGuidelines.md
5. FolderStructure.md
6. DesignSystem.md
7. AIEngine.md

Never contradict these documents.

If conflict exists:

Architecture.md takes priority.

---

# Development Philosophy

Every feature should be:

Small.

Composable.

Reusable.

Independent.

Avoid giant files.

Avoid giant ViewModels.

Avoid giant Managers.

---

# Preferred Architecture

MVVM

UI

↓

ViewModel

↓

UseCase

↓

Repository

↓

Persistence

↓

SwiftData

Never allow View to directly communicate with repositories.

Never allow repositories to contain business logic.

---

# SOLID Principles

Always follow SOLID.

Especially:

Single Responsibility

Dependency Inversion

Interface Segregation

Prefer protocols.

Avoid singleton abuse.

---

# Dependency Injection

Always inject dependencies.

Never instantiate services directly inside Views.

Good:

```
ExpenseViewModel(
    repository: repository
)
```

Bad:

```
ExpenseViewModel()
```

---

# Swift Guidelines

Always use:

async/await

actors where appropriate

Sendable

Observation

structured concurrency

Never use:

DispatchQueue unless absolutely necessary.

Completion handlers unless required.

NSObject inheritance unless required.

UIKit unless impossible with SwiftUI.

---

# SwiftUI Rules

Views should remain lightweight.

Views should never:

- load data
- parse JSON
- perform AI work
- perform database work

Views only display state.

---

# ViewModel Rules

ViewModels:

Own UI state

Trigger use cases

Handle loading state

Handle navigation state

Never:

Access database directly.

---

# Repository Rules

Repositories:

Load

Save

Delete

Fetch

Nothing else.

No calculations.

No business rules.

---

# Business Logic

Business logic belongs inside UseCases.

Example:

Good

```
CategorizeExpenseUseCase
```

Bad

```
ExpenseRepository.categorize()
```

---

# AI Rules

All AI logic belongs inside:

AIEngine/

Never call Foundation Models directly from ViewModels.

Instead:

ViewModel

↓

UseCase

↓

AIEngine

↓

Foundation Models

---

# Error Handling

Never ignore errors.

Prefer:

```
do {

} catch {

}
```

Avoid:

```
try!
```

Avoid:

```
try?
```

unless intentionally discarding.

---

# Logging

Use Logger.

Never use print().

Example:

```
private let logger = Logger(
    subsystem: "SpendMind",
    category: "Expense"
)
```

---

# File Size

Preferred maximum:

View

250 lines

ViewModel

250 lines

Repository

250 lines

UseCase

200 lines

Split when necessary.

---

# Naming

Use clear names.

Good

```
ExpenseListView
```

Bad

```
ListView
```

Good

```
ExpenseAnalyzer
```

Bad

```
Manager
```

Avoid vague names.

---

# Folder Rules

Every feature contains:

Feature/

Views/

ViewModels/

Models/

UseCases/

Components/

Repositories/

Extensions/

Tests/

Never place everything in one folder.

---

# SwiftData Rules

Always:

Use ModelContext injection.

Avoid global context.

Keep fetch descriptors simple.

Never perform expensive queries repeatedly.

---

# UI Rules

Always support:

Dark Mode

Dynamic Type

Localization

Accessibility

Reduced Motion

VoiceOver

---

# Accessibility

Every button:

accessibilityLabel

Every image:

decorative OR labeled

Support:

Dynamic Type

High Contrast

VoiceOver

---

# Animation

Prefer:

.contentTransition

.symbolEffect

.phaseAnimator

.matchedGeometryEffect

Avoid excessive animations.

Performance first.

---

# Design Rules

Follow:

DesignSystem.md

Never hardcode:

Colors

Fonts

Spacing

Radius

Shadow

Instead use:

AppColor

AppSpacing

Typography

Radius

---

# Performance

Avoid:

Nested GeometryReader

Heavy ViewBuilders

Repeated calculations

Large body properties

Repeated AI requests

Cache expensive work.

---

# Testing

Every UseCase requires tests.

Repository requires tests.

AI parsers require tests.

Utilities require tests.

UI snapshot tests optional.

---

# AI Generated Code

AI should never:

invent APIs

invent Apple frameworks

guess model names

guess Foundation Model APIs

If unsure:

Create protocol first.

Leave TODO.

---

# Documentation

Public types require documentation.

Complex algorithms require comments.

Do not comment obvious code.

Good:

```
/// Predicts recurring expenses using historical transactions.
```

Bad:

```
/// Increment i by one.
```

---

# Git

Small commits.

One feature per PR.

Never modify unrelated files.

---

# Before Writing Code

Always ask:

Is this already implemented?

Can this be reused?

Can this be simplified?

---

# Code Review Checklist

Before finishing:

✅ Compiles

✅ No warnings

✅ SwiftLint clean

✅ Tests pass

✅ Accessibility checked

✅ Localization ready

✅ Dark Mode works

✅ Offline works

✅ No duplicated code

✅ Documentation updated

---

# When Requirements Are Missing

Do not invent functionality.

Instead:

1. Leave TODO

2. Explain assumptions

3. Follow PRD

---

# AI Agent Behavior

When implementing a task:

1. Read relevant documentation.

2. Identify affected modules.

3. Minimize changes.

4. Preserve architecture.

5. Write tests.

6. Verify compilation.

7. Update documentation if necessary.

Never refactor unrelated code unless explicitly requested.

---

# Coding Priority

Always prioritize:

1. Correctness
2. Simplicity
3. Readability
4. Testability
5. Performance
6. Maintainability
7. Extensibility

Never sacrifice readability for cleverness.

---

# Definition of Done

A task is complete only if:

- Feature works as specified.
- Architecture remains consistent.
- Tests are added or updated.
- Documentation is updated.
- No compiler warnings.
- No known regressions.
- Code is production ready.

---

# Final Rule

Write code as if another engineer will maintain it for the next five years.

Optimize for clarity over cleverness.
