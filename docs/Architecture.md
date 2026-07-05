# Phase 1: Foundation

## Goal

Build a clean, scalable, testable architecture that can support future AI features without requiring major refactoring.

The foundation phase focuses on establishing the application's core layers, dependency management, navigation, persistence, and development standards.

---

# Architecture Principles

SpendMind follows the following principles:

* Feature-first modular architecture
* Clean Architecture
* MVVM
* Protocol-oriented programming
* Dependency Injection
* Offline-first
* Local AI ready
* Testable by design
* Swift Concurrency first
* Minimal third-party dependencies

The architecture should make every feature independent, easy to test, and easy to extend.

---

# High-Level Architecture

```
┌────────────────────────────┐
│         SwiftUI App        │
└─────────────┬──────────────┘
              │
      App Coordinator
              │
     Navigation Router
              │
 ┌────────────┴────────────┐
 │        Features         │
 └────────────┬────────────┘
              │
         ViewModel
              │
          Use Cases
              │
         Repository
              │
      Local Data Source
              │
          SwiftData
```

Future AI services plug into the Use Case layer rather than interacting directly with UI or persistence.

```
UseCase
   │
   ├── Repository
   └── AIService
```

---

# Project Layers

## Presentation

Responsible for UI rendering.

Contains:

* SwiftUI Views
* ViewModels
* Navigation
* UI Components
* State management

Presentation should never directly access SwiftData.

Instead:

```
View
   ↓
ViewModel
   ↓
UseCase
```

---

## Domain

Contains business logic.

Includes:

* Use Cases
* Entities
* Repository Protocols
* Business Rules

Domain should have zero dependency on SwiftUI or SwiftData.

---

## Data

Responsible for persistence.

Contains:

* Repository implementations
* SwiftData models
* Local data sources
* Mapping layer

The Data layer converts between persistence models and domain models.

---

## Core

Reusable infrastructure shared across the application.

Examples:

* Dependency Injection
* Logging
* Error handling
* Analytics abstraction
* Utilities
* Extensions
* Constants
* Design Tokens

---

## Shared

Reusable UI and feature-independent components.

Examples:

* Buttons
* Cards
* Charts
* Empty states
* Loading indicators
* Currency formatter
* Date formatter

---

# Folder Structure

```
SpendMind/

├── App/
│   ├── SpendMindApp.swift
│   ├── AppCoordinator.swift
│   ├── AppEnvironment.swift
│   └── DependencyContainer.swift
│
├── Core/
│   ├── DependencyInjection/
│   ├── Networking/
│   ├── Persistence/
│   ├── Logging/
│   ├── Extensions/
│   ├── Utilities/
│   ├── Constants/
│   └── Errors/
│
├── Domain/
│   ├── Entities/
│   ├── UseCases/
│   ├── Repositories/
│   └── Services/
│
├── Data/
│   ├── Models/
│   ├── Repositories/
│   ├── DataSources/
│   ├── Mappers/
│   └── Persistence/
│
├── Features/
│   ├── Dashboard/
│   ├── Transactions/
│   ├── Categories/
│   ├── Budget/
│   ├── Analytics/
│   ├── AI/
│   └── Settings/
│
├── Shared/
│   ├── Components/
│   ├── Theme/
│   ├── Charts/
│   ├── Formatters/
│   └── Resources/
│
└── Tests/
```

Each feature is self-contained.

Example:

```
Transactions/

├── Views/
├── ViewModels/
├── Models/
├── Components/
├── Navigation/
└── Tests/
```

---

# Dependency Direction

Dependencies always point inward.

```
Presentation
      ↓
Domain
      ↓
Data
```

Never:

```
Data
 ↓
Presentation
```

The Domain layer must remain independent.

---

# MVVM Pattern

Each feature follows MVVM.

```
TransactionView

        ↓

TransactionViewModel

        ↓

GetTransactionsUseCase

        ↓

TransactionRepository

        ↓

SwiftData
```

Responsibilities:

### View

* UI rendering
* User interaction
* Bind to ViewModel
* No business logic

### ViewModel

* UI state
* User actions
* Async operations
* Calls Use Cases

### Use Case

* Business rules
* Validation
* Workflow orchestration

### Repository

* Abstract persistence
* Hide SwiftData implementation

---

# Dependency Injection

All dependencies are injected through protocols.

Example:

```
TransactionRepositoryProtocol

↓

TransactionRepository
```

ViewModels depend only on protocols.

Example:

```
final class DashboardViewModel {

    init(
        loadDashboardUseCase: LoadDashboardUseCase
    )
}
```

Benefits:

* Easier testing
* Mocking
* Decoupling
* Scalability

---

# Navigation

Use a centralized router.

```
AppCoordinator

↓

NavigationStack

↓

Router

↓

Destination
```

Each feature owns its destinations.

Avoid:

* Hardcoded navigation
* Global navigation state
* Nested NavigationStacks

---

# State Management

Rules:

* `@State` for local UI state.
* `@StateObject` for root-owned ObservableObjects (if still required).
* `@Observable` (Observation framework) for new observable models.
* `@Bindable` for editable observable bindings.
* `@Environment` for shared app services.
* `@EnvironmentObject` only when truly global and unavoidable.

Business state should live in the ViewModel.

Views should remain lightweight.

---

# Concurrency

Use Swift Concurrency exclusively.

Preferred APIs:

* async/await
* Task
* TaskGroup
* AsyncSequence
* Actors

Avoid introducing new code based on:

* Completion handlers
* Delegate chains for async work
* Combine unless required by a framework

---

# Error Handling

Create a unified application error type.

Example:

```
enum AppError: Error {

    case validation

    case database

    case ai

    case network

    case unknown
}
```

Errors are translated into user-friendly messages within the Presentation layer.

---

# Logging

Centralize logging.

Example:

```
Logger.shared.debug()

Logger.shared.error()

Logger.shared.info()
```

Support:

* Debug builds
* Release builds
* Future analytics integration

---

# Configuration

Environment values should be injected.

Examples:

* App version
* Build configuration
* Feature flags
* AI configuration
* Debug options

Never scatter configuration constants across the project.

---

# Persistence

Version 1 uses SwiftData exclusively.

Responsibilities:

* Local storage
* Offline-first support
* Automatic migrations where possible
* Repository abstraction
* Model mapping

Views and ViewModels must never interact directly with SwiftData.

---

# Coding Standards

Use the following conventions throughout the project:

* One primary type per file.
* Feature-first organization.
* Protocol-first abstractions.
* Prefer immutable (`let`) over mutable (`var`) properties.
* Favor value types (`struct`) unless reference semantics are required.
* Keep functions short and focused.
* Avoid force unwrapping (`!`) except where proven safe.
* Use descriptive names instead of abbreviations.
* Mark types and members with the narrowest appropriate access level.
* Document public APIs with Swift documentation comments.

---

# Testing Strategy

Architecture must support testing from the start.

Target coverage:

* Domain: High
* Data: Medium
* Presentation: Medium

Recommended tests:

* Unit Tests
* Repository Tests
* ViewModel Tests
* Mapper Tests

Use protocol-based mocking to isolate dependencies.

---

# Phase 1 Deliverables

At the completion of Phase 1, the project should include:

* Tuist-based project generation
* Modular folder structure
* Clean Architecture layers
* MVVM implementation
* Dependency Injection container
* SwiftData persistence setup
* Centralized navigation
* Unified error handling
* Logging infrastructure
* Shared UI component library
* Base theme and design tokens
* Unit testing foundation
* CI-ready project structure

This foundation establishes a maintainable architecture that supports rapid feature development while remaining ready for future AI capabilities, additional modules, and long-term scalability.
