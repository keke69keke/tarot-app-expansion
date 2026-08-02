import Foundation

/// Domain-level errors propagated through the app's use-case and repository layers.
///
/// ViewModels catch these and convert them to localised user-facing messages.
public enum TarotError: Error {

    /// The card content bundle (JSON / assets) could not be loaded.
    case contentLoadFailed(underlying: Error)

    /// A CoreData / CloudKit persistence operation failed.
    case persistenceFailed(operation: String, underlying: Error)

    /// A domain validation rule was violated (e.g. notes > 2 000 chars, invalid hour).
    case validationFailed(field: String, reason: String)

    /// The user denied notification permissions; scheduling is not possible.
    case notificationPermissionDenied
}

// MARK: - LocalizedError

extension TarotError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .contentLoadFailed(let underlying):
            return "No se pudo cargar el contenido de la app. \(underlying.localizedDescription)"
        case .persistenceFailed(let operation, let underlying):
            return "Error al \(operation): \(underlying.localizedDescription)"
        case .validationFailed(let field, let reason):
            return "El campo '\(field)' no es válido: \(reason)"
        case .notificationPermissionDenied:
            return "Los permisos de notificación han sido denegados. Actívalos en Ajustes del sistema."
        }
    }
}
