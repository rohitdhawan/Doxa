import Foundation
import StoreKit

@MainActor
@Observable
final class TipJarService {
    static let shared = TipJarService()

    enum PurchaseState {
        case loading
        case ready
        case purchasing
        case success
        case failed(String)
        case unavailable(String)
    }

    private(set) var purchaseState: PurchaseState = .loading
    private(set) var tipProduct: Product?

    private static let tipProductID = "com.newdocgenieai.app.tip.small"

    private init() {
        Task { await loadProduct() }
    }

    func loadProduct() async {
        purchaseState = .loading
        do {
            let products = try await Product.products(for: [Self.tipProductID])
            if let product = products.first {
                tipProduct = product
                purchaseState = .ready
            } else {
                purchaseState = .unavailable("Donation product is not available yet. Check the local StoreKit configuration or App Store Connect setup for \(Self.tipProductID).")
            }
        } catch {
            purchaseState = .unavailable("Unable to load donation options right now. Please try again later.")
        }
    }

    func purchase() async {
        guard let product = tipProduct else { return }
        purchaseState = .purchasing
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    await transaction.finish()
                    purchaseState = .success
                    // Reset after 3 seconds
                    Task { @MainActor in
                        try? await Task.sleep(for: .seconds(3))
                        purchaseState = .ready
                    }
                case .unverified:
                    purchaseState = .failed("Purchase could not be verified.")
                }
            case .userCancelled:
                purchaseState = .ready
            case .pending:
                purchaseState = .ready
            @unknown default:
                purchaseState = .ready
            }
        } catch {
            purchaseState = .failed("Purchase failed. Please try again.")
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(3))
                purchaseState = .ready
            }
        }
    }
}
