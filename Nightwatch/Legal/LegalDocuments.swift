import Foundation

/// Loads the filled-in legal documents bundled from `Legal/Documents/` (see
/// `LEGAL_STATUS.md` at the repo root for the privacy policy's approval
/// status). `FactorySettingsView` displays whatever string it is given via
/// `LegalDocumentView` — this is the app's side of that contract.
enum LegalDocuments {
    static var privacyPolicyMarkdown: String {
        loadDocument(named: "Privacy")
    }

    static var termsMarkdown: String {
        loadDocument(named: "Terms")
    }

    private static func loadDocument(named name: String) -> String {
        guard
            let url = Bundle.main.url(forResource: name, withExtension: "md"),
            let contents = try? String(contentsOf: url, encoding: .utf8)
        else {
            assertionFailure("Missing bundled legal document: \(name).md")
            return ""
        }
        return contents
    }
}
