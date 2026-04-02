import Foundation

/// Persisted application settings backed by UserDefaults.
@Observable
public final class AppSettings {
    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    /// Whether to persist the last search/replace terms between sessions.
    public var persistState: Bool {
        get { defaults.bool(forKey: "persistState") }
        set { defaults.set(newValue, forKey: "persistState") }
    }

    /// Maximum number of MRU (Most Recently Used) entries.
    public var maxMRUSize: Int {
        get {
            let val = defaults.integer(forKey: "maxMRUSize")
            return val > 0 ? val : 10
        }
        set { defaults.set(newValue, forKey: "maxMRUSize") }
    }

    /// Default rename flags to apply on startup.
    public var defaultFlags: UInt32 {
        get { UInt32(defaults.integer(forKey: "defaultFlags")) }
        set { defaults.set(Int(newValue), forKey: "defaultFlags") }
    }

    /// Last used search term (if persistState is enabled).
    public var lastSearchTerm: String? {
        get { defaults.string(forKey: "lastSearchTerm") }
        set { defaults.set(newValue, forKey: "lastSearchTerm") }
    }

    /// Last used replace term (if persistState is enabled).
    public var lastReplaceTerm: String? {
        get { defaults.string(forKey: "lastReplaceTerm") }
        set { defaults.set(newValue, forKey: "lastReplaceTerm") }
    }
}
