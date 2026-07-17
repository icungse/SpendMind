# AIEngine.md

# Veyra AI Engine
**Version:** 1.0  
**Platform:** iOS (Swift 6+)  
**Architecture:** On-Device AI Only  
**Status:** Phase 4

---

# 1. Purpose

The AI Engine is responsible for transforming raw financial data into meaningful insights while ensuring:

- 100% local processing
- No internet connection required
- No cloud inference
- No user account
- Privacy-first architecture
- Explainable AI

The AI system should feel like a financial advisor rather than a chatbot.

---

# 2. Design Principles

## Local First

Everything happens on device.

```
Receipt
      ↓
OCR
      ↓
Transaction
      ↓
AI Analysis
      ↓
Insight
```

Nothing leaves the phone.

---

## Explainability

Every suggestion must explain WHY.

Example:

Good:

> Food spending increased 18% compared to last week because you visited restaurants 6 times instead of 3.

Bad:

> Spend less.

---

## No Hallucination

AI only speaks using existing transaction data.

Never invent numbers.

Never guess merchant names.

Never estimate balances.

---

## Deterministic

Same data

↓

Same output

Every time.

---

# 3. AI Modules

Veyra AI is divided into multiple engines.

```
AIEngine

├── CategorizationEngine
├── InsightEngine
├── BudgetEngine
├── PatternEngine
├── AnomalyEngine
├── ForecastEngine
├── GoalEngine
├── RecommendationEngine
├── SearchEngine
└── SummaryEngine
```

---

# 4. AI Pipeline

```
Transactions

      │
      ▼

Feature Extraction

      │
      ▼

Pattern Detection

      │
      ▼

Insight Generation

      │
      ▼

Recommendation Ranking

      │
      ▼

Natural Language Generation

      │
      ▼

UI
```

---

# 5. Categorization Engine

Responsible for assigning categories.

Input:

```
Starbucks
Rp 58.000
```

Output

```
Food & Drink
Coffee
Cafe
```

Sources used

- Merchant dictionary
- Previous user behavior
- Amount pattern
- Keywords
- User correction history

Priority

```
User Override
↓

Merchant History
↓

Dictionary

↓

ML Prediction
```

---

# 6. Merchant Recognition

Recognizes merchants even if names differ.

Example

```
STARBUCKS
```

```
Starbucks Coffee
```

```
SBX
```

↓

All become

```
Starbucks
```

Normalization includes

- Uppercase removal
- Symbols
- Duplicate spaces
- OCR typo correction

---

# 7. Feature Extraction

Each transaction becomes a feature vector.

Example

```
Amount

Category

Merchant

Time

Weekday

Weekend

Month

Hour

Location (optional)

Payment Method

Recurring

Frequency

Average Spending
```

---

# 8. Pattern Engine

Detects user habits.

Examples

Coffee every weekday

Netflix every month

Salary every 25th

Grab every Friday

Weekend shopping

Late-night food

Impulse purchases

Recurring subscriptions

---

Algorithm

```
Frequency Analysis

+

Moving Average

+

Time Series

+

Rule Engine
```

---

# 9. Budget Engine

Monitors budget usage.

Calculates

Current usage

Remaining budget

Daily allowance

Burn rate

Expected end-of-month balance

Overspending probability

---

Example

```
Food Budget

2.000.000

Spent

1.650.000

Remaining

350.000

Projected

2.450.000

Status

Likely Overspend
```

---

# 10. Forecast Engine

Predicts future spending.

Methods

Rolling Average

Weighted Average

Seasonality

Monthly trend

Moving window

---

Prediction examples

End of month expenses

Subscription costs

Cash flow

Savings

Category spending

---

# 11. Anomaly Detection

Detects unusual transactions.

Examples

Largest purchase ever

Restaurant spending doubled

Shopping spike

Unexpected subscription

Duplicate payment

Very late payment

Abnormal cash withdrawal

---

Simple algorithm

```
Current

>

Average × Threshold
```

or

```
Z-score

>

Threshold
```

---

# 12. Goal Engine

Tracks savings goals.

Example

Goal

```
MacBook

25.000.000
```

Current

```
13.500.000
```

Progress

```
54%
```

Forecast

```
Complete in 4.2 months
```

---

# 13. Recommendation Engine

Produces actionable suggestions.

Ranking criteria

Impact

Confidence

Frequency

Urgency

User preference

---

Example recommendations

Reduce coffee purchases

Cancel unused subscription

Increase savings

Avoid weekend overspending

Review shopping category

---

# 14. Insight Engine

Generates high-level financial observations.

Examples

"You spent 23% more this week."

"Food is your biggest category."

"Subscriptions increased."

"You saved more than last month."

"Shopping peaked on weekends."

Insights must be:

Short

Human

Actionable

Supported by data

---

# 15. Search Engine

Natural language transaction search.

Examples

```
coffee last month
```

```
grab this week
```

```
shopping over 500k
```

```
subscriptions
```

Pipeline

```
Text

↓

Intent

↓

Filters

↓

SQLite Query

↓

Result
```

No LLM required.

---

# 16. Summary Engine

Creates financial summaries.

Daily

Weekly

Monthly

Yearly

Example

```
This month:

Spent Rp 6.2M

Saved Rp 2.1M

Largest category:
Food

Highest merchant:
Tokopedia

Top increase:
Shopping

Budget health:
Good
```

---

# 17. Confidence Score

Every AI output includes confidence.

Example

```
Category

Food

Confidence

98%
```

```
Recommendation

Reduce coffee spending

Confidence

83%
```

UI decides whether to display low-confidence outputs.

---

# 18. AI Data Sources

Uses only

Transactions

Budgets

Categories

Goals

Merchant database

User corrections

Recurring payments

Never uses

Contacts

Photos

Messages

Location history (unless user explicitly enables)

Cloud data

---

# 19. Privacy Model

```
Internet

×

Disabled
```

```
Server

×

None
```

```
Analytics

×

None
```

```
Cloud AI

×

Never
```

Everything stays inside the device.

---

# 20. AI Technologies

Recommended Apple frameworks

Core ML

NaturalLanguage

Create ML

Vision

FoundationModels (future)

Accelerate

BNNS

Swift Algorithms

SQLite FTS

---

# 21. AI Service Layer

```
AIEngine

├── analyzeTransactions()

├── categorize()

├── detectPatterns()

├── detectRecurring()

├── detectAnomalies()

├── generateInsights()

├── recommend()

├── summarize()

├── search()

├── forecast()

└── calculateConfidence()
```

---

# 22. Performance Requirements

Cold launch analysis

< 500 ms

Monthly summary

< 1 second

Categorization

< 50 ms

Search

< 100 ms

Pattern analysis

< 300 ms

Recommendation generation

< 500 ms

Memory usage

< 150 MB

---

# 23. Error Handling

If AI cannot determine a result:

Do not fabricate.

Instead

```
Unknown Merchant

Confidence 22%

Please choose a category.
```

If insufficient data

```
Not enough transaction history
to generate an insight yet.
```

---

# 24. Future AI Roadmap

## Version 1.5

- Better merchant clustering
- Smarter recurring detection
- Improved spending forecasts
- Personalized recommendation ranking

---

## Version 2.0

- Apple Foundation Models integration
- Offline conversational finance assistant
- Voice financial summaries
- Intelligent receipt understanding
- Automatic financial health scoring

---

## Version 3.0

- Personalized budgeting strategies
- Local fine-tuned spending model
- Predictive cash flow simulation
- AI-generated saving plans
- Financial habit coaching

---

# 25. Non-Goals (v1.0)

The following are intentionally out of scope:

- Cloud AI
- OpenAI API integration
- Google Gemini
- Anthropic Claude
- Server-side inference
- Multi-user collaboration
- Investment advice
- Tax filing assistance
- Bank account synchronization
- Cryptocurrency portfolio analysis
- Credit score prediction

These features may be evaluated in future versions but are excluded from the initial privacy-first release.