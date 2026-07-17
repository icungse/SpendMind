# FolderStructure.md

# Veyra iOS Folder Structure

> Version: 1.0
> Architecture: MVVM + Clean Architecture + Modular Feature Structure
> Language: Swift 6
> Framework: SwiftUI
> Target: iOS 18+

---

# Goals

This folder structure is designed to:

- Highly scalable
- Easy for AI agents (Codex/ChatGPT) to navigate
- Feature-first organization
- Strict separation of concerns
- Easy unit testing
- Easy future modularization into Swift Packages

---

# Root

```
Veyra/
│
├── App/
├── Core/
├── Features/
├── Shared/
├── Resources/
├── Config/
├── SupportingFiles/
├── Tests/
└── UITests/
```

---

# App

Contains application lifecycle.

```
App/

├── VeyraApp.swift
├── AppRouter.swift
├── AppEnvironment.swift
├── DependencyContainer.swift
├── SceneDelegate.swift (if needed)
└── AppState.swift
```

Responsibilities

- App Entry
- Global Environment
- Dependency Injection
- Navigation Root
- Global State

Must NOT contain business logic.

---

# Core

Contains reusable application infrastructure.

```
Core/

├── AI/
│
├── Database/
│
├── Networking/
│
├── Storage/
│
├── Analytics/
│
├── Logging/
│
├── OCR/
│
├── Security/
│
├── Extensions/
│
├── Utilities/
│
└── Constants/
```

---

## AI

```
AI/

├── AIAnalyzer.swift
├── AIEngine.swift
├── PromptBuilder.swift
├── LocalModelManager.swift
├── InsightGenerator.swift
└── Categorizer.swift
```

Responsible for

- Expense categorization
- Spending insights
- AI prompts
- Local LLM integration

No UI.

---

## Database

```
Database/

├── Models/
├── Repository/
├── Persistence.swift
├── Migration.swift
└── DatabaseManager.swift
```

Responsible for

- SwiftData
- CoreData migration
- CRUD

---

## OCR

```
OCR/

├── OCRService.swift
├── ReceiptParser.swift
├── ReceiptScanner.swift
└── VisionProcessor.swift
```

---

## Security

```
Security/

├── KeychainManager.swift
├── Encryption.swift
├── Biometrics.swift
└── SecureStorage.swift
```

---

## Logging

```
Logging/

├── Logger.swift
├── LogLevel.swift
└── CrashReporter.swift
```

---

# Features

Every business feature owns everything it needs.

```
Features/

├── Dashboard/
├── Transactions/
├── Categories/
├── Budget/
├── Insights/
├── AIChat/
├── ReceiptScanner/
├── Settings/
└── Onboarding/
```

Each feature follows the exact same structure.

Example:

```
Transactions/

├── Presentation/
│
├── Domain/
│
├── Data/
│
├── Components/
│
└── Resources/
```

---

# Presentation

```
Presentation/

├── Views/
├── ViewModels/
├── Navigation/
├── States/
├── Components/
└── Preview/
```

Example

```
Views/

├── TransactionListView.swift
├── TransactionDetailView.swift
├── AddTransactionView.swift
└── EditTransactionView.swift
```

```
ViewModels/

├── TransactionListViewModel.swift
├── AddTransactionViewModel.swift
└── TransactionDetailViewModel.swift
```

---

# Domain

Pure business logic.

```
Domain/

├── Models/
├── UseCases/
├── Repository/
└── Validators/
```

Example

```
UseCases/

├── AddTransactionUseCase.swift
├── DeleteTransactionUseCase.swift
├── UpdateTransactionUseCase.swift
├── FetchTransactionsUseCase.swift
└── CalculateExpenseUseCase.swift
```

No SwiftUI.

No Database.

No Network.

---

# Data

Implementation layer.

```
Data/

├── DTO/
├── Mapper/
├── Repository/
└── DataSource/
```

Example

```
Repository/

TransactionRepositoryImpl.swift
```

---

# Components

Reusable UI specific to this feature.

```
Components/

├── TransactionCard.swift
├── TransactionRow.swift
├── EmptyTransactionView.swift
└── CategoryBadge.swift
```

---

# Resources

Assets belonging only to this feature.

```
Resources/

├── Images/
├── Strings/
└── Icons/
```

---

# Shared

Reusable across every feature.

```
Shared/

├── Components/
├── ViewModifiers/
├── DesignSystem/
├── Theme/
├── Fonts/
├── Icons/
├── Models/
├── Protocols/
└── Helpers/
```

---

## Components

```
Components/

├── PrimaryButton.swift
├── SecondaryButton.swift
├── AppTextField.swift
├── LoadingView.swift
├── EmptyStateView.swift
├── ErrorView.swift
└── AppNavigationBar.swift
```

---

## DesignSystem

```
DesignSystem/

├── Colors.swift
├── Typography.swift
├── Spacing.swift
├── Radius.swift
├── Shadows.swift
└── Animation.swift
```

Single source of truth for UI.

---

# Resources

Global assets.

```
Resources/

├── Assets.xcassets
├── Localizable.xcstrings
├── LaunchScreen.storyboard
└── PreviewAssets/
```

---

# Config

Environment configuration.

```
Config/

├── Development.xcconfig
├── Production.xcconfig
├── Debug.xcconfig
└── BuildConfiguration.swift
```

---

# SupportingFiles

```
SupportingFiles/

├── Info.plist
├── PrivacyInfo.xcprivacy
└── Entitlements.plist
```

---

# Tests

Mirror production folder.

```
Tests/

├── Core/
├── Features/
├── Shared/
└── Mocks/
```

Example

```
Tests/

└── Features/

    └── Transactions/

        ├── ViewModelTests/
        ├── UseCaseTests/
        ├── RepositoryTests/
        └── Mock/
```

---

# UITests

```
UITests/

├── LaunchTests.swift
├── DashboardTests.swift
├── TransactionTests.swift
├── BudgetTests.swift
└── SnapshotTests.swift
```

---

# Example Complete Feature

```
Transactions/

├── Presentation/
│
│   ├── Views/
│   │
│   ├── ViewModels/
│   │
│   ├── Components/
│   │
│   ├── Navigation/
│   │
│   └── Preview/
│
├── Domain/
│
│   ├── Models/
│   │
│   ├── UseCases/
│   │
│   ├── Repository/
│   │
│   └── Validators/
│
├── Data/
│
│   ├── DTO/
│   ├── Mapper/
│   ├── Repository/
│   └── DataSource/
│
├── Components/
│
└── Resources/
```

---

# Naming Convention

## Views

```
DashboardView
BudgetView
SettingsView
```

---

## ViewModels

```
DashboardViewModel
BudgetViewModel
```

---

## UseCases

```
CreateBudgetUseCase
DeleteTransactionUseCase
GenerateInsightUseCase
```

---

## Repository

```
TransactionRepository
TransactionRepositoryImpl
```

---

## Protocols

Use clear capability names without a `Protocol` suffix unless an existing Apple or project API requires disambiguation.

Example

```
ExpenseRepository
AIAnalyzer
Storage
```

---

## Models

Singular.

```
Transaction
Budget
Category
Insight
```

---

# Dependency Direction

```
Presentation
      ↓
Domain
      ↓
Repository Protocol
      ↓
Data
      ↓
Database
```

Never reverse dependencies.

---

# Import Rules

Feature modules should not import other Features directly.

Allowed:

```
Feature
    ↓
Core

Feature
    ↓
Shared
```

Not allowed:

```
Transactions
      ↓
Budget
```

Communication should happen via

- Repository
- Coordinator
- Shared Models
- App Environment

---

# Asset Ownership

Global assets:

```
Resources/
```

Feature-specific assets:

```
Feature/Resources/
```

---

# Scalability

When the application grows, each feature can become an independent Swift Package with minimal refactoring because all dependencies are already isolated.

Example future structure:

```
Packages/

├── VeyraCore
├── VeyraAI
├── VeyraDesignSystem
├── VeyraTransactions
├── VeyraBudget
├── VeyraInsights
├── VeyraOCR
└── VeyraShared
```

---

# Folder Structure Principles

1. Feature-first organization.
2. Business logic is isolated from UI.
3. Shared code lives only in `Core` or `Shared`.
4. Every feature owns its Presentation, Domain, Data, Resources, and Components.
5. Dependencies flow inward only.
6. No circular imports.
7. Every folder has a single responsibility.
8. The structure should remain AI-friendly, testable, and scalable to support future Swift Package modularization.
