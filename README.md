# SpendMind

[![CI](https://github.com/icungse/SpendMind/actions/workflows/ci.yml/badge.svg)](https://github.com/icungse/SpendMind/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

SpendMind is a privacy-first iOS expense tracker built with SwiftUI, SwiftData, and an on-device AI-ready architecture. It is local-first: no login, no backend, no cloud sync, and no analytics collection.

## Setup

Requirements:

- macOS with Xcode and the iOS 18 SDK
- `mise`
- Tuist `4.200.5` and SwiftLint `0.65.0` from `.tool-versions`

```sh
mise install
tuist install
tuist generate
```

## Build

```sh
tuist build SpendMind
tuist test SpendMind
swiftlint lint
```

CI runs install, lint, build, and tests for pull requests targeting `main` and `develop`.

## Architecture

- Platform: iOS 18+, Swift 6, SwiftUI, Observation, SwiftData.
- Pattern: MVVM with Clean Architecture boundaries.
- Dependency flow: `View -> ViewModel -> UseCase -> Repository -> SwiftData`.
- `App/` owns app startup, dependency injection, routing, and navigation shell.
- `Core/` owns reusable infrastructure: persistence, settings, errors, logging, utilities, constants, and extensions.
- `Features/` owns feature UI and state. Current features are `Splash` and `Dashboard`.
- `Shared/` owns design tokens and reusable SwiftUI components.
- AI work must stay local and plug in behind use cases/services, not directly into views.

## Folder Structure

```text
SpendMind/
|-- Project.swift
|-- Tuist/
|-- SpendMind/
|   |-- App/
|   |-- Core/
|   |-- Features/
|   |   |-- Dashboard/
|   |   |-- Splash/
|   |-- Resources/
|   |-- Shared/
|-- SpendMindTests/
|-- SpendMindUITests/
|-- docs/
|-- .github/workflows/ci.yml
```

## Docs

- `docs/Architecture.md`: app architecture and boundaries.
- `docs/DataModel.md`: local data model and persistence rules.
- `docs/CodingGuidelines.md`: Swift and project coding standards.
- `docs/FolderStructure.md`: expected project layout.
- `docs/DesignSystem.md`: current design tokens and components.
- `docs/AIEngine.md`: on-device AI direction.

## License

SpendMind is available under the MIT License. See `LICENSE`.
