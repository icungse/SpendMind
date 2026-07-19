//
//  GenerateBudgetInsightsUseCase.swift
//  Veyra
//
//  Created by Icung on 17/07/26.
//

import Foundation

struct BudgetInsight: Identifiable, Equatable, Sendable {
    let id: String
    let message: String
}

struct DefaultGenerateBudgetInsightsUseCase {
    static let approachingLimitProgress = Decimal(string: "0.8") ?? 0.8
    // three stable rules for v0.3.0; add ranking only when more insight types exist.
    static let maximumInsightCount = 3

    private let calendar: Calendar

    init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    func execute(progress: [BudgetProgress], referenceDate: Date) -> [BudgetInsight] {
        guard !progress.isEmpty else { return [] }

        var insights: [BudgetInsight] = []

        if let overallInsight = overallProgressInsight(progress: progress, referenceDate: referenceDate) {
            insights.append(overallInsight)
        }

        if let warningInsight = categoryApproachingLimitInsight(progress: progress) {
            insights.append(warningInsight)
        }

        if let exceededInsight = categoryBudgetsExceededInsight(progress: progress) {
            insights.append(exceededInsight)
        }

        return Array(insights.prefix(Self.maximumInsightCount))
    }

    private func overallProgressInsight(progress: [BudgetProgress], referenceDate: Date) -> BudgetInsight? {
        let overall = progress.first { $0.budget.isTotalBudget } ?? aggregateCategoryProgress(progress)
        guard let overall, overall.budget.amount > 0 else { return nil }

        let percent = NSDecimalNumber(decimal: overall.progress * 100).doubleValue.rounded()
        let daysRemaining = daysRemaining(from: referenceDate, to: overall.budget.endDate)

        return BudgetInsight(
            id: "overallMonthlyProgress",
            message: String.localizedStringWithFormat(
                String(localized: "budget.insight.overall_monthly_progress"),
                Int(percent),
                daysRemaining
            )
        )
    }

    private func categoryApproachingLimitInsight(progress: [BudgetProgress]) -> BudgetInsight? {
        let category = progress
            .filter { $0.budget.isCategoryBudget && $0.status == .warning }
            .sorted { $0.budget.name.localizedCaseInsensitiveCompare($1.budget.name) == .orderedAscending }
            .first

        guard let category else { return nil }

        return BudgetInsight(
            id: "categoryApproachingLimit",
            message: String.localizedStringWithFormat(
                String(localized: "budget.insight.category_approaching_limit"),
                category.budget.name
            )
        )
    }

    private func categoryBudgetsExceededInsight(progress: [BudgetProgress]) -> BudgetInsight? {
        let count = progress.filter { $0.budget.isCategoryBudget && $0.status == .exceeded }.count
        guard count > 0 else { return nil }

        let message = String.localizedStringWithFormat(
            String(localized: "budget.insight.category_budgets_exceeded"),
            count
        )

        return BudgetInsight(id: "categoryBudgetsExceeded", message: message)
    }

    private func aggregateCategoryProgress(_ progress: [BudgetProgress]) -> BudgetProgress? {
        let categoryProgress = progress.filter(\.budget.isCategoryBudget)
        guard !categoryProgress.isEmpty else { return nil }

        let totalLimit = categoryProgress.reduce(Decimal.zero) { $0 + $1.budget.amount }
        guard totalLimit > 0, let firstBudget = categoryProgress.first?.budget else { return nil }

        let totalSpent = categoryProgress.reduce(Decimal.zero) { $0 + $1.spentAmount }
        let aggregateBudget = try? Budget(
            id: firstBudget.id,
            name: String(localized: "budget.monthly"),
            amount: totalLimit,
            period: firstBudget.period,
            startDate: firstBudget.startDate,
            endDate: firstBudget.endDate,
            alertThreshold: Self.approachingLimitProgress,
            calendar: calendar
        )

        guard let aggregateBudget else { return nil }
        return BudgetProgress(budget: aggregateBudget, spentAmount: totalSpent)
    }

    private func daysRemaining(from referenceDate: Date, to endDate: Date) -> Int {
        guard let dayAfterEnd = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: endDate)) else {
            return 0
        }

        let start = calendar.startOfDay(for: referenceDate)
        let days = calendar.dateComponents([.day], from: start, to: dayAfterEnd).day ?? 0
        return max(days, 0)
    }
}
