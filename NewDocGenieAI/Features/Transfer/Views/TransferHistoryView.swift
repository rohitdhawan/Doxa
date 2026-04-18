import SwiftUI

struct TransferHistoryView: View {
    @Bindable var transferManager: TransferManager
    @Environment(\.dismiss) private var dismiss
    @State private var filterDirection: FilterDirection = .all
    @State private var showClearAlert = false

    enum FilterDirection: String, CaseIterable {
        case all = "All"
        case sent = "Sent"
        case received = "Received"
    }

    private var filteredHistory: [TransferItem] {
        switch filterDirection {
        case .all: return transferManager.transferHistory
        case .sent: return transferManager.transferHistory.filter { $0.direction == .sent }
        case .received: return transferManager.transferHistory.filter { $0.direction == .received }
        }
    }

    private var groupedHistory: [(String, [TransferItem])] {
        let grouped = Dictionary(grouping: filteredHistory) { item in
            dateGroupKey(for: item.timestamp)
        }
        return grouped.sorted { $0.key > $1.key }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filter Bar
                filterBar
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.vertical, AppSpacing.sm)

                // Stats Summary
                statsSummary
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.bottom, AppSpacing.sm)

                if filteredHistory.isEmpty {
                    emptyState
                } else {
                    historyList
                }
            }
            .background(Color.appBGDark)
            .navigationTitle("Transfer History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color.appPrimary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if !transferManager.transferHistory.isEmpty {
                        Button {
                            showClearAlert = true
                        } label: {
                            Image(systemName: "trash")
                                .foregroundStyle(Color.appDanger)
                        }
                    }
                }
            }
            .alert("Clear History", isPresented: $showClearAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Clear All", role: .destructive) {
                    withAnimation {
                        transferManager.clearHistory()
                    }
                }
            } message: {
                Text("This will permanently delete all transfer history.")
            }
        }
    }

    // MARK: - Filter Bar

    private var filterBar: some View {
        HStack(spacing: 0) {
            ForEach(FilterDirection.allCases, id: \.self) { direction in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        filterDirection = direction
                    }
                } label: {
                    Text(direction.rawValue)
                        .font(.appCaption.weight(.medium))
                        .foregroundStyle(filterDirection == direction ? .white : Color.appTextMuted)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.sm)
                        .background(filterDirection == direction ? Color.appPrimary : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.sm))
                }
            }
        }
        .padding(3)
        .background(Color.appBGElevated)
        .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.md))
    }

    // MARK: - Stats Summary

    private var statsSummary: some View {
        HStack(spacing: AppSpacing.sm) {
            statCard(
                title: "Total",
                value: "\(transferManager.transferHistory.count)",
                icon: "arrow.left.arrow.right",
                color: Color.appPrimary
            )

            statCard(
                title: "Sent",
                value: "\(transferManager.transferHistory.filter { $0.direction == .sent }.count)",
                icon: "arrow.up.right",
                color: Color.appAccent
            )

            statCard(
                title: "Received",
                value: "\(transferManager.transferHistory.filter { $0.direction == .received }.count)",
                icon: "arrow.down.left",
                color: Color.appSuccess
            )
        }
    }

    private func statCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: AppSpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(color)

            Text(value)
                .font(.appH3)
                .foregroundStyle(Color.appText)

            Text(title)
                .font(.appMicro)
                .foregroundStyle(Color.appTextMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.sm)
        .background(Color.appBGCard)
        .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.sm))
        .overlay(
            RoundedRectangle(cornerRadius: AppCornerRadius.sm)
                .stroke(Color.appBorder.opacity(0.2), lineWidth: 1)
        )
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: AppSpacing.md) {
            Spacer()

            Image(systemName: "arrow.left.arrow.right.circle")
                .font(.system(size: 56))
                .foregroundStyle(Color.appTextDim)

            Text("No Transfers Yet")
                .font(.appH2)
                .foregroundStyle(Color.appText)

            Text("Your transfer history will appear here\nonce you send or receive files.")
                .font(.appBody)
                .foregroundStyle(Color.appTextMuted)
                .multilineTextAlignment(.center)

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - History List

    private var historyList: some View {
        ScrollView {
            LazyVStack(spacing: AppSpacing.md) {
                ForEach(groupedHistory, id: \.0) { group in
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text(group.0)
                            .font(.appCaption.weight(.semibold))
                            .foregroundStyle(Color.appTextMuted)
                            .padding(.horizontal, AppSpacing.xs)

                        ForEach(group.1) { item in
                            TransferHistoryRow(item: item)
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        withAnimation {
                                            transferManager.removeHistoryItem(item)
                                        }
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                }
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm)
        }
    }

    // MARK: - Helpers

    private func dateGroupKey(for date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else if calendar.isDate(date, equalTo: Date(), toGranularity: .weekOfYear) {
            return "This Week"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM yyyy"
            return formatter.string(from: date)
        }
    }
}
