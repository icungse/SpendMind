# CodingGuidelines.md

> **Veyra v1.0**
> Phase 1 (Foundation)
> Target Platform: iOS 18+
> Language: Swift 6
> Architecture: MVVM + Clean Architecture
> UI: SwiftUI
> Persistence: SwiftData
> AI: Apple Foundation Models (On-device)

---

# Purpose

This document defines coding standards for the entire Veyra project.

The goal is to make every piece of code:

* Predictable
* Readable
* Testable
* Modular
* Easily reviewable
* AI-agent friendly (Codex/ChatGPT)

Whenever there is ambiguity, this document takes precedence.

---

# Core Principles

## 1. Simplicity First

Always prefer the simplest solution.

Avoid:

* clever code
* unnecessary abstraction
* premature optimization

Good:

```swift
if transaction.amount > budget {
    ...
}
```

Bad:

```swift
transaction
    .filter(...)
    .compactMap(...)
    .reduce(...)
```

when a simple loop is easier.

---

## 2. Single Responsibility

Every type should have exactly one responsibility.

Examples

✅ Good

```
TransactionRepository
```

stores transactions.

```
TransactionAnalyzer
```

analyzes transactions.

```
TransactionViewModel
```

prepares UI state.

❌ Bad

```
TransactionManager
```

that

* stores data
* calls AI
* validates
* formats
* navigates

---

## 3. Composition over Inheritance

Prefer protocols and composition.

Good

```swift
protocol ExpenseRepository { }
```

Bad

```swift
class BaseRepository
class ExpenseRepository : BaseRepository
```

---

## 4. Dependency Injection

Never instantiate dependencies inside business logic.

Bad

```swift
class DashboardViewModel {

    let repository = TransactionRepository()

}
```

Good

```swift
class DashboardViewModel {

    init(repository: ExpenseRepository) {

    }

}
```

---

## 5. Immutable by Default

Prefer

```swift
let
```

instead of

```swift
var
```

Use mutable state only when necessary.

---

# Swift Style Guide

---

## Naming

Types

```swift
ExpenseRepository
```

```swift
AIInsightGenerator
```

Use PascalCase.

---

Variables

```swift
totalExpense
```

```swift
monthlyBudget
```

camelCase only.

Avoid abbreviations.

Bad

```swift
expAmt
```

Good

```swift
expenseAmount
```

---

Functions

Function names should read like sentences.

Good

```swift
calculateMonthlyBudget()
```

```swift
loadTransactions()
```

Bad

```swift
doThing()
```

```swift
calc()
```

---

Boolean Naming

Always use

```swift
isPaid
```

```swift
hasReceipt
```

```swift
canDelete
```

Never

```swift
paidFlag
```

---

Enums

Good

```swift
enum TransactionType
```

Cases

```swift
case income
case expense
case transfer
```

---

Protocols

Protocols describe capability.

Good

```swift
ExpenseRepository
```

```swift
TransactionAnalyzer
```

Avoid

```swift
ExpenseRepositoryProtocol
```

---

# File Organization

One primary type per file.

Good

```
Expense.swift

DashboardView.swift

DashboardViewModel.swift

TransactionRepository.swift
```

Avoid

```
Helpers.swift

Utils.swift

Common.swift
```

These files grow uncontrollably.

---

# Folder Structure

```
Feature/

    Dashboard/

        Views/

        ViewModels/

        Components/

        Models/

        Services/

```

Shared code belongs inside

```
Shared/
```

Never duplicate reusable code.

---

# SwiftUI Guidelines

Views should be as dumb as possible.

Views display state.

ViewModels contain logic.

Never put business logic inside Views.

Bad

```swift
Button {

    repository.save()

}
```

Good

```swift
Button {

    viewModel.save()

}
```

---

Large Views

Split views once they exceed roughly 200 lines.

Example

```
DashboardView

↓

SummaryCard

↓

BudgetCard

↓

ExpenseChart

↓

RecentTransactions
```

---

Use Computed Properties

Instead of

```swift
Text(
    transactions.filter {
        ...
    }.count.description
)
```

Move logic

```swift
var expenseCount: Int {

}
```

---

Avoid Nested Ifs

Bad

```swift
if let budget {

    if budget.limit > 0 {

    }

}
```

Good

```swift
guard let budget else {

    return

}
```

---

# ViewModel Guidelines

ViewModels:

* own UI state
* call Use Cases
* expose observable data

Never:

* perform persistence directly
* build SQL/SwiftData queries
* perform AI prompt construction

---

Observable State

Only expose what UI needs.

Good

```swift
@Observable

final class DashboardViewModel {

    var summary: DashboardSummary

}
```

Avoid exposing repositories publicly.

---

# Repository Guidelines

Repositories only:

* fetch
* save
* delete
* update

Nothing else.

Repositories never:

* calculate analytics
* format strings
* generate charts
* call AI

---

# Use Case Guidelines

Every business action belongs inside a Use Case.

Examples

```
CreateExpenseUseCase

DeleteExpenseUseCase

AnalyzeMonthlySpendingUseCase

GenerateAIInsightUseCase
```

Each Use Case should expose a single public entry point.

```swift
execute()
```

---

# AI Coding Rules

AI code lives only inside

```
Core/AI
```

Never scatter AI code.

Prompt construction belongs inside dedicated prompt builders.

Example

```
InsightPromptBuilder
```

Model interaction belongs inside

```
AIInsightService
```

ViewModels never create prompts.

---

# Error Handling

Avoid force unwraps.

Never

```swift
!
```

unless impossible to fail.

Prefer

```swift
guard
```

or

```swift
if let
```

---

Use Typed Errors

```swift
enum RepositoryError: Error {

    case saveFailed

    case notFound

}
```

Never

```swift
throw NSError(...)
```

---

# Async/Await Rules

Always use Swift Concurrency.

Avoid callbacks.

Bad

```swift
repository.load {

}
```

Good

```swift
let expenses = try await repository.load()
```

---

Never block MainActor.

Heavy work should execute in background.

UI updates happen on MainActor.

---

# Extensions

Only create extensions when they improve readability.

Good

```swift
extension Date
```

Bad

```
String+Everything.swift
```

---

# Constants

Avoid magic numbers.

Bad

```swift
if amount > 500000
```

Good

```swift
Constants.expenseWarningThreshold
```

---

# Comments

Code should explain itself.

Do not comment obvious code.

Bad

```swift
// Increment count

count += 1
```

Good

Explain WHY.

```swift
// Prevent duplicate AI analysis for the same month.
```

---

# Logging

Never use

```swift
print()
```

Use

```swift
Logger
```

Example

```swift
logger.info("Expense imported.")
```

Sensitive financial data must never be logged.

---

# Formatting

Indentation

* 4 spaces

Maximum line length

* 120 characters

One blank line between logical sections.

---

# Access Control

Always use the most restrictive access level.

Prefer

```swift
private
```

then

```swift
fileprivate
```

then

```swift
internal
```

Only expose APIs intentionally.

---

# Testing Rules

Every Use Case must have unit tests.

Repositories require tests.

Utility classes require tests.

Views do not require snapshot tests in Phase 1.

Target coverage

```
80%+
```

Business logic

```
95%+
```

---

# Performance

Avoid unnecessary allocations.

Avoid duplicate filtering.

Cache expensive calculations.

Use lazy loading when appropriate.

Measure before optimizing.

---

# Security

Financial information is sensitive.

Rules:

* Never log transactions
* Never expose AI prompts in logs
* Never store secrets in code
* Never hardcode API keys
* Prefer Secure Enclave or Keychain when secrets are required in future versions

---

# SwiftData Rules

Models belong only inside

```
Core/Persistence
```

Never expose SwiftData models directly to Views.

Map them into Domain Models.

---

# Preview Rules

Every SwiftUI View should include a Preview.

Use mock data.

Never access live persistence from previews.

---

# File Header

Every source file should begin with:

```swift
//
//  FileName.swift
//  Veyra
//
//  Created by <Developer>
//
```

No copyright banner.

---

# Pull Request Checklist

Before opening a Pull Request, ensure:

* Code builds without warnings.
* SwiftLint passes.
* SwiftFormat passes.
* Unit tests pass.
* GitHub Actions CI pipeline passes successfully.
* No TODOs remain unless tracked by an issue.
* No force unwraps.
* No duplicated code.
* Public APIs are documented.
* New features include tests.
* Preview builds successfully.

---

# Definition of Done

A task is considered complete only when:

* Feature is implemented.
* Architecture rules are followed.
* Code is formatted.
* Unit tests pass.
* CI pipeline (Build, Test, Lint) passes successfully on GitHub Actions.
* Documentation is updated if required.
* No compiler warnings remain.
* No runtime crashes are introduced.
* Feature is reviewed and approved.

---

# Rules for AI Agents (Codex / ChatGPT)

When generating code for Veyra, always follow these rules:

1. Never violate Clean Architecture boundaries.
2. Never place business logic inside SwiftUI Views.
3. Never directly access SwiftData from Views.
4. Prefer protocol-based dependency injection.
5. Keep files focused on a single responsibility.
6. Use async/await for asynchronous work.
7. Avoid force unwraps.
8. Avoid singleton patterns unless explicitly approved.
9. Generate production-ready code with no placeholders.
10. Match existing project naming conventions and folder structure.
11. Add unit tests for all new business logic.
12. Refactor duplicated logic instead of copying code.
13. Favor readability over cleverness.
14. Keep functions short (ideally under 30 lines).
15. Keep types cohesive and easy to reason about.

---

# Phase 1 Scope

This Coding Guidelines document establishes the baseline engineering standards for Veyra. All future phases, including AI insights, analytics, budgeting, widgets, Siri integration, and additional features, must comply with these conventions unless an Architecture Decision Record (ADR) explicitly approves an exception.
