import Foundation

final class OnboardingStore {
    private let completedKey = "JellyTranslate.onboardingCompleted"

    var isCompleted: Bool {
        get { UserDefaults.standard.bool(forKey: completedKey) }
        set { UserDefaults.standard.set(newValue, forKey: completedKey) }
    }

    func markCompleted() {
        isCompleted = true
    }
}
