import SwiftUI

struct PDFSearchView: View {
    @Bindable var viewModel: PDFViewerViewModel
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: AppSpacing.sm) {
                // Search field
                HStack(spacing: AppSpacing.sm) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(Color.appTextMuted)
                        .font(.appBody)

                    TextField("Search in PDF...", text: $viewModel.searchText)
                        .font(.appBody)
                        .foregroundStyle(Color.appText)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .focused($isSearchFocused)
                        .onSubmit {
                            viewModel.performSearch()
                        }

                    if !viewModel.searchText.isEmpty {
                        Button {
                            viewModel.clearSearch()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(Color.appTextMuted)
                        }
                    }
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.sm)
                .background(Color.appBGElevated, in: RoundedRectangle(cornerRadius: AppCornerRadius.md))

                // Search button
                Button {
                    HapticManager.light()
                    viewModel.performSearch()
                    isSearchFocused = false
                } label: {
                    Text("Search")
                        .font(.appBody)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.appPrimary)
                }
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm)

            // Results bar
            if !viewModel.searchResults.isEmpty || viewModel.isSearching {
                HStack(spacing: AppSpacing.md) {
                    Text(viewModel.searchStatusText)
                        .font(.appCaption)
                        .foregroundStyle(Color.appTextMuted)

                    Spacer()

                    Button {
                        HapticManager.selection()
                        viewModel.previousSearchResult()
                    } label: {
                        Image(systemName: "chevron.up")
                            .font(.appBody.weight(.semibold))
                            .foregroundStyle(Color.appPrimary)
                    }
                    .disabled(viewModel.searchResults.isEmpty)

                    Button {
                        HapticManager.selection()
                        viewModel.nextSearchResult()
                    } label: {
                        Image(systemName: "chevron.down")
                            .font(.appBody.weight(.semibold))
                            .foregroundStyle(Color.appPrimary)
                    }
                    .disabled(viewModel.searchResults.isEmpty)
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.xs)
            }

            Divider()
                .foregroundStyle(Color.appBorder)
        }
        .background(.ultraThinMaterial)
        .onAppear {
            isSearchFocused = true
        }
    }
}
