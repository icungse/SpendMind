//
//  BudgetProgressCardView.swift
//  SpendMind
//
//  Created by Icung on 15/07/26.
//

import SwiftUI

struct BudgetProgressCardView: View {
    let progress: BudgetProgress
    let viewModel: BudgetListViewModel
    let isTotal: Bool

    var body: some View {
        Card {
            BudgetCardBodyView(
                title: progress.budget.name,
                subtitle: viewModel.typeLabel(for: progress),
                icon: viewModel.categoryIcon(for: progress),
                iconColor: isTotal ? AppColor.primary : Color(hexString: viewModel.categoryColorHex(for: progress)),
                amount: viewModel.formattedAmount(progress.budget.amount),
                spent: viewModel.formattedAmount(progress.spentAmount),
                remaining: viewModel.formattedAmount(progress.remainingAmount),
                progress: progress.progress,
                status: progress.status,
                warningMessage: viewModel.warningMessage(for: progress),
                isTotal: isTotal
            )
        }
    }
}
