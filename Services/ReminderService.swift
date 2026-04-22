import Foundation
import EventKit

public class ReminderService {
    private let store = EKEventStore()

    public init() {}

    public func requestAccess(completion: @escaping (Bool, Error?) -> Void) {
        store.requestAccess(to: .reminder, completion: completion)
    }

    public func createReminders(listName: String, items: [String], completion: ((Result<Void, Error>) -> Void)? = nil) {
        requestAccess { granted, error in
            if let error = error {
                DispatchQueue.main.async { completion?(.failure(error)) }
                return
            }
            guard granted else {
                DispatchQueue.main.async { completion?(.failure(NSError(domain: "ReminderService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Access denied"]))) }
                return
            }

            // Find or create list
            let calendars = self.store.calendars(for: .reminder)
            if let list = calendars.first(where: { $0.title == listName }) {
                self.addItems(items, to: list, completion: completion)
            } else {
                // iOS does not allow creating reminder lists directly via EventKit in all cases; use default calendar
                if let defaultCal = self.store.defaultCalendarForNewReminders() {
                    self.addItems(items, to: defaultCal, completion: completion)
                } else if let anyCalendar = calendars.first {
                    self.addItems(items, to: anyCalendar, completion: completion)
                } else {
                    DispatchQueue.main.async {
                        completion?(.failure(NSError(domain: "ReminderService", code: 2, userInfo: [NSLocalizedDescriptionKey: "No reminders list available"])) )
                    }
                }
            }
        }
    }

    private func addItems(_ items: [String], to calendar: EKCalendar, completion: ((Result<Void, Error>) -> Void)?) {
        for title in items {
            let reminder = EKReminder(eventStore: store)
            reminder.title = title
            reminder.calendar = calendar
            do {
                try store.save(reminder, commit: true)
            } catch {
                DispatchQueue.main.async { completion?(.failure(error)) }
                return
            }
        }
        DispatchQueue.main.async { completion?(.success(())) }
    }
}
