import Foundation

/// Staleness of a piece of fetched data, as a value the view layer can
/// render (per the delegated brief: "expose staleness as data on the model
/// so the UI can render it — do not render anything yourself"). Nothing in
/// `Data/` decides how this looks on screen; it only decides the facts.
public enum DataFreshness: Sendable, Equatable {
    /// Served from a successful fetch that is still inside its validity
    /// window (or was never given one), timestamped when it was fetched.
    case fresh(asOf: Date)
    /// Served from disk cache because a fresh fetch was not attempted or did
    /// not succeed; still the last verdict we can stand behind, timestamped
    /// when *that* data was originally fetched.
    case stale(asOf: Date)
    /// No cached data exists yet and no fetch has succeeded — nothing to
    /// show, not even an old verdict.
    case unavailable

    /// The timestamp callers care about, if any.
    public var asOf: Date? {
        switch self {
        case .fresh(let date), .stale(let date): return date
        case .unavailable: return nil
        }
    }

    public var isStale: Bool {
        if case .stale = self { return true }
        return false
    }
}
