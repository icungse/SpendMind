# DataModel.md

# SpendMind v1.0 Data Model

Version: 1.0  
Platform: iOS 18+  
Persistence: SwiftData (Primary), UserDefaults (Settings), File System (Backup/Export)  
Architecture: Offline First

---

# Overview

SpendMind is designed to run **100% locally**.

There is:

- No backend
- No authentication
- No cloud database
- No analytics dependency
- No user account

All application data is stored using **SwiftData**.

---

# Entity Relationship Diagram

```
Category
    │
    │ 1
    │
    ├──────────────┐
    │              │
    │              │ N
    ▼              │
Expense ◄──────────┘

Expense
    │
    │ 1
    │
    ├──────────────┐
    │              │ N
    ▼              │
ExpenseAttachment

Expense
    │
    │ 1
    │
    ├──────────────┐
    │              │ N
    ▼              │
ExpenseTag

Expense
    │
    │
    └────────────► AIInsight
```

---

# Entity List

| Entity | Purpose |
|----------|---------|
| Expense | Main financial record |
| Category | Expense grouping |
| ExpenseAttachment | Receipt images |
| ExpenseTag | Optional labels |
| AIInsight | Cached AI analysis |
| AppSettings | User preferences |

---

# Expense

The most important entity.

```swift
@Model
final class Expense {

    @Attribute(.unique)
    var id: UUID

    var amount: Decimal

    var note: String

    var merchant: String?

    var createdAt: Date

    var updatedAt: Date

    var expenseDate: Date

    var paymentMethod: PaymentMethod

    var currency: CurrencyCode

    var locationName: String?

    var latitude: Double?

    var longitude: Double?

    var isDeleted: Bool

    @Relationship(deleteRule: .cascade)
    var attachments: [ExpenseAttachment]

    @Relationship
    var category: Category?

    @Relationship
    var tags: [ExpenseTag]

    @Relationship(deleteRule: .cascade)
    var aiInsight: AIInsight?
}
```

---

# Expense Fields

| Field | Type | Required |
|----------|------|----------|
| id | UUID | Yes |
| amount | Decimal | Yes |
| note | String | Yes |
| merchant | String | No |
| expenseDate | Date | Yes |
| createdAt | Date | Yes |
| updatedAt | Date | Yes |
| paymentMethod | Enum | Yes |
| currency | Enum | Yes |
| locationName | String | No |
| latitude | Double | No |
| longitude | Double | No |
| isDeleted | Bool | Yes |

---

# Category

```swift
@Model
final class Category {

    @Attribute(.unique)
    var id: UUID

    var name: String

    var icon: String

    var colorHex: String

    var isSystem: Bool

    var createdAt: Date

    @Relationship(inverse: \Expense.category)
    var expenses: [Expense]
}
```

---

# Category Fields

| Field | Type |
|----------|------|
| id | UUID |
| name | String |
| icon | SF Symbol |
| colorHex | String |
| isSystem | Bool |
| createdAt | Date |

---

# Default Categories

```
Food

Transportation

Shopping

Health

Bills

Entertainment

Travel

Education

Salary

Investment

Gift

Others
```

---

# ExpenseAttachment

Stores receipt images.

```swift
@Model
final class ExpenseAttachment {

    @Attribute(.unique)
    var id: UUID

    var filename: String

    var filePath: String

    var createdAt: Date
}
```

---

# Attachment Strategy

Images are NOT stored inside SwiftData.

Instead:

```
Documents/

    Receipts/

        UUID.jpg

        UUID.heic

        UUID.png
```

SwiftData only stores

```
filePath
```

---

# ExpenseTag

```swift
@Model
final class ExpenseTag {

    @Attribute(.unique)
    var id: UUID

    var name: String
}
```

Example:

```
Business

Vacation

Family

Tax

Office

Personal
```

---

# AIInsight

Cached AI analysis.

Generated locally.

```swift
@Model
final class AIInsight {

    @Attribute(.unique)
    var id: UUID

    var summary: String

    var confidence: Double

    var generatedAt: Date

    var modelVersion: String

    var recommendation: String

    var detectedCategory: String?

    var sentiment: ExpenseSentiment
}
```

---

# Why Cache AI?

Local LLM inference is expensive.

Instead of regenerating every time:

```
Expense

↓

Run AI once

↓

Save result

↓

Reuse later
```

This dramatically improves battery life.

---

# AppSettings

Not stored in SwiftData.

Stored in UserDefaults.

```swift
struct AppSettings {

    var currency: CurrencyCode

    var darkMode: Appearance

    var biometricEnabled: Bool

    var aiEnabled: Bool

    var defaultCategory: UUID?

    var firstLaunchCompleted: Bool
}
```

---

# PaymentMethod

```swift
enum PaymentMethod: String, Codable {

    case cash

    case debitCard

    case creditCard

    case eWallet

    case bankTransfer

    case crypto

    case other
}
```

---

# CurrencyCode

Initially only one currency is active.

```swift
enum CurrencyCode: String, Codable {

    case IDR

    case USD

    case SGD

    case MYR

    case EUR

    case GBP
}
```

---

# ExpenseSentiment

Used by AI.

```swift
enum ExpenseSentiment: String, Codable {

    case positive

    case neutral

    case negative
}
```

Example:

Positive

```
Investment
```

Negative

```
Impulse purchase
```

Neutral

```
Groceries
```

---

# Data Validation Rules

## Expense

Amount

```
> 0
```

Maximum

```
999,999,999
```

---

Note

```
Maximum 500 characters
```

---

Merchant

```
Maximum 100 characters
```

---

Category

Must exist.

---

Receipt

Maximum

```
10 MB
```

Supported

```
HEIC

JPEG

PNG
```

---

# Index Strategy

Frequently queried fields.

```
expenseDate

category

createdAt

merchant

amount
```

---

# Soft Delete

Expenses are never immediately deleted.

```
Expense

↓

isDeleted = true

↓

Hidden from UI

↓

Permanently removed during cleanup
```

Benefits:

- Undo support
- Recovery
- Safer deletion

---

# Backup Structure

Export format:

```
SpendMind Backup/

    database.json

    receipts/

        UUID.jpg

        UUID.heic
```

JSON contains:

```
Expenses

Categories

Tags

AI Cache

Settings
```

---

# Data Flow

```
User

↓

Create Expense

↓

Validation

↓

Save SwiftData

↓

Store Receipt

↓

Run AI

↓

Cache AI Result

↓

Refresh Dashboard
```

---

# Migration Strategy

SpendMind uses SwiftData migrations for persisted app data.

Rules:

- Use SwiftData `VersionedSchema` once real `@Model` types exist.
- Prefer lightweight migrations.
- Prefer additive changes: optional fields, new models, and safe defaults.
- Never remove or rename persisted fields without an explicit migration plan.
- Keep receipt files outside SwiftData and migrate file paths separately if needed.
- Keep sample stores from shipped versions.
- Test every schema-changing release against previous-version sample stores.

---

# Estimated Storage
  
| Data | Approximate Size |
|------|------------------:|
| Expense record | ~0.5 KB |
| AI Insight | ~1 KB |
| Category | ~0.2 KB |
| Receipt metadata | ~0.2 KB |
| Receipt image | 0.5–5 MB |

Example:

- 10,000 expenses (without images): ~15–20 MB
- 10,000 expenses (with average 2 MB receipts): ~20 GB

---

# Design Principles

- Offline-first
- SwiftData as the single source of truth
- Immutable IDs (UUID)
- Receipt files stored separately from the database
- Cached AI insights to minimize repeated inference
- Lightweight, migration-friendly schema
- Privacy by design with all user data remaining on-device
