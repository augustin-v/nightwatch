import Foundation
import AuroraCore

extension VisibilityBand {
    var localizedLabel: String {
        switch self {
        case .none: return String(localized: "tonight.band.none")
        case .slim: return String(localized: "tonight.band.slim")
        case .worthWatching: return String(localized: "tonight.band.worthWatching")
        case .strong: return String(localized: "tonight.band.strong")
        case .rare: return String(localized: "tonight.band.rare")
        }
    }
}

extension LimitingFactor {
    /// The one-sentence explanation shown under the verdict, per spec §1/§4
    /// ("Clouds are the problem tonight."). Complete localized sentences,
    /// never assembled from fragments.
    var localizedSentence: String {
        switch self {
        case .darkness: return String(localized: "tonight.limitingFactor.darkness")
        case .clouds: return String(localized: "tonight.limitingFactor.clouds")
        case .activity: return String(localized: "tonight.limitingFactor.activity")
        case .moon: return String(localized: "tonight.limitingFactor.moon")
        case .none: return String(localized: "tonight.limitingFactor.none")
        }
    }
}
