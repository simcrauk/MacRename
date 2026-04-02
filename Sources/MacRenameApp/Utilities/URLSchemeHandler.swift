import SwiftUI
import MacRenameCore

/// Handles the `macrename://` URL scheme for receiving files from the Finder extension.
struct URLSchemeHandler {

    /// Parses a `macrename://open?files=...` URL and returns file URLs.
    static func parseURLScheme(_ url: URL) -> [URL]? {
        guard url.scheme == "macrename",
              url.host == "open" else { return nil }

        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let filesParam = components.queryItems?.first(where: { $0.name == "files" })?.value else {
            return nil
        }

        let fileURLStrings = filesParam.components(separatedBy: ",")
        let urls = fileURLStrings.compactMap { URL(string: $0) }

        return urls.isEmpty ? nil : urls
    }
}
