import Foundation

struct PaymentReceipt: Sendable {
    let reference: String
    let amountCents: Int
}

protocol PaymentGateway: Sendable {
    func chargeDeposit(amountCents: Int, description: String) async throws -> PaymentReceipt
}

/// Stands in for Stripe in the demo: it takes as long as a real charge and always succeeds.
struct SimulatedPaymentGateway: PaymentGateway {
    let latency: Duration

    func chargeDeposit(amountCents: Int, description: String) async throws -> PaymentReceipt {
        try await Task.sleep(for: latency)
        let reference = "pi_" + UUID().uuidString.replacingOccurrences(of: "-", with: "").prefix(14).lowercased()
        return PaymentReceipt(reference: reference, amountCents: amountCents)
    }
}
