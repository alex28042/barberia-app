import EventKit
import EventKitUI
import SwiftUI

/// The system's own "new event" sheet, pre-filled. It needs no calendar permission.
struct AddToCalendarView: UIViewControllerRepresentable {
    let appointment: Appointment
    let shop: Shop
    let onFinish: (_ didSave: Bool) -> Void

    func makeUIViewController(context: Context) -> EKEventEditViewController {
        let store = EKEventStore()
        let event = EKEvent(eventStore: store)
        event.title = "\(appointment.service.name) en \(shop.name)"
        event.startDate = appointment.start
        event.endDate = appointment.end
        event.location = shop.address

        let controller = EKEventEditViewController()
        controller.eventStore = store
        controller.event = event
        controller.editViewDelegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ controller: EKEventEditViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onFinish: onFinish)
    }

    @MainActor
    final class Coordinator: NSObject, @MainActor EKEventEditViewDelegate {
        private let onFinish: (Bool) -> Void

        init(onFinish: @escaping (Bool) -> Void) {
            self.onFinish = onFinish
        }

        func eventEditViewController(_ controller: EKEventEditViewController, didCompleteWith action: EKEventEditViewAction) {
            onFinish(action == .saved)
        }
    }
}
