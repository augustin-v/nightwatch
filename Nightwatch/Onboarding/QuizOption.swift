import Foundation

/// Answer option for `SingleChoiceQuizStepView`. That shell displays
/// `option.rawValue` directly, so `rawValue` is populated with the already
/// -localized display string (never a hardcoded literal) at construction
/// time; `id` is a stable, non-localized key used for equality/identity and
/// for downstream logic (e.g. the reflection screen reading which latitude
/// band was picked). `init(rawValue:)` only exists to satisfy
/// `RawRepresentable`'s protocol requirement — the shell never calls it, so
/// it is not a real reconstruction path.
struct QuizOption: Identifiable, RawRepresentable, Hashable {
    let id: String
    let rawValue: String

    init(id: String, rawValue: String) {
        self.id = id
        self.rawValue = rawValue
    }

    init?(rawValue: String) {
        self.id = rawValue
        self.rawValue = rawValue
    }
}

enum QuizOptions {
    static let wound: [QuizOption] = [
        QuizOption(id: "missedOne", rawValue: String(localized: "onboarding.quiz.wound.option.missedOne")),
        QuizOption(id: "neverSeen", rawValue: String(localized: "onboarding.quiz.wound.option.neverSeen")),
        QuizOption(id: "chaseRegularly", rawValue: String(localized: "onboarding.quiz.wound.option.chaseRegularly"))
    ]

    static let latitudeBand: [QuizOption] = [
        QuizOption(id: "farNorth", rawValue: String(localized: "onboarding.quiz.latitude.option.farNorth")),
        QuizOption(id: "midLatitude", rawValue: String(localized: "onboarding.quiz.latitude.option.midLatitude")),
        QuizOption(id: "southernHemisphere", rawValue: String(localized: "onboarding.quiz.latitude.option.southernHemisphere")),
        QuizOption(id: "travel", rawValue: String(localized: "onboarding.quiz.latitude.option.travel"))
    ]

    static let obstacle: [QuizOption] = [
        QuizOption(id: "clouds", rawValue: String(localized: "onboarding.quiz.obstacle.option.clouds")),
        QuizOption(id: "notKnowingWhen", rawValue: String(localized: "onboarding.quiz.obstacle.option.notKnowingWhen")),
        QuizOption(id: "tooTired", rawValue: String(localized: "onboarding.quiz.obstacle.option.tooTired")),
        QuizOption(id: "wrongAlerts", rawValue: String(localized: "onboarding.quiz.obstacle.option.wrongAlerts"))
    ]

    static let intent: [QuizOption] = [
        QuizOption(id: "notFar", rawValue: String(localized: "onboarding.quiz.intent.option.notFar")),
        QuizOption(id: "halfHour", rawValue: String(localized: "onboarding.quiz.intent.option.halfHour")),
        QuizOption(id: "hourOrMore", rawValue: String(localized: "onboarding.quiz.intent.option.hourOrMore"))
    ]

    /// Realistic nights/year by latitude-band answer, for the on-device
    /// reflection screen (spec §5 screen 7). Coarse, directional numbers —
    /// not a scientific claim, just enough to make the "your plan" beat land.
    static func realisticNightsPerYear(forLatitudeBandID id: String) -> Int {
        switch id {
        case "farNorth": return 120
        case "midLatitude": return 15
        case "southernHemisphere": return 20
        case "travel": return 30
        default: return 15
        }
    }
}
