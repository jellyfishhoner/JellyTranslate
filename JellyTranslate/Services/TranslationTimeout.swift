import Foundation

enum TranslationRuntimeError: LocalizedError {
    case timeout(seconds: Int)

    var errorDescription: String? {
        switch self {
        case .timeout(let seconds):
            return "The translation provider did not respond within \(seconds) seconds. Check your connection or try again."
        }
    }
}

func withTimeout<T>(seconds: Int, operation: @escaping @Sendable () async throws -> T) async throws -> T {
    try await withThrowingTaskGroup(of: T.self) { group in
        group.addTask {
            try await operation()
        }
        group.addTask {
            try await Task.sleep(nanoseconds: UInt64(seconds) * 1_000_000_000)
            throw TranslationRuntimeError.timeout(seconds: seconds)
        }

        guard let result = try await group.next() else {
            throw TranslationRuntimeError.timeout(seconds: seconds)
        }
        group.cancelAll()
        return result
    }
}
