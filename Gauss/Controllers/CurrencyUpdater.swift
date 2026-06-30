import Foundation
import GaussEngine

final class CurrencyUpdater {
    private let currencyConverter: CurrencyConverter
    private var updateTimer: Timer?
    private let cacheFile: URL

    /// Called on the main thread after each rate refresh with a human-readable status string.
    var onRatesUpdated: ((String) -> Void)?

    /// The interval between periodic rate refreshes. Changing this reschedules the timer.
    var updateInterval: TimeInterval = 4 * 3600 {
        didSet {
            guard updateInterval != oldValue else { return }
            updateTimer?.invalidate()
            updateTimer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { [weak self] _ in
                self?.fetchRates()
            }
        }
    }

    private var lastUpdateDate: Date?

    init(currencyConverter: CurrencyConverter) {
        self.currencyConverter = currencyConverter
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let gaussDir = appSupport.appendingPathComponent("Gauss")
        try? FileManager.default.createDirectory(at: gaussDir, withIntermediateDirectories: true)
        cacheFile = gaussDir.appendingPathComponent("rates.json")

        // Load cached rates first so currency conversion works offline
        loadCachedRates()

        // Fetch fresh rates immediately
        fetchRates()

        // Schedule periodic updates every 4 hours
        updateTimer = Timer.scheduledTimer(withTimeInterval: 4 * 3600, repeats: true) { [weak self] _ in
            self?.fetchRates()
        }
    }

    func fetchRates() {
        guard let url = URL(string: "https://api.frankfurter.app/latest?from=USD") else { return }

        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard let self = self, let data = data, error == nil else {
                DispatchQueue.main.async {
                    self?.onRatesUpdated?("Offline")
                }
                return
            }

            // Parse frankfurter.app response: {"base":"USD","date":"...","rates":{"EUR":0.92,...}}
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let rates = json["rates"] as? [String: Double] else { return }

            var fullRates = rates
            fullRates["USD"] = 1.0

            // Update converter and record timestamp
            self.currencyConverter.updateRates(fullRates)
            self.lastUpdateDate = Date()

            // Cache to disk for offline use
            try? data.write(to: self.cacheFile)

            DispatchQueue.main.async {
                self.onRatesUpdated?("Updated just now")
            }
        }.resume()
    }

    private func loadCachedRates() {
        guard let data = try? Data(contentsOf: cacheFile),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let rates = json["rates"] as? [String: Double] else { return }

        var fullRates = rates
        fullRates["USD"] = 1.0
        currencyConverter.updateRates(fullRates)
    }

    func statusText() -> String {
        guard let date = lastUpdateDate else { return "Offline" }
        let minutes = Int(-date.timeIntervalSinceNow / 60)
        if minutes < 1 { return "Updated just now" }
        if minutes < 60 { return "Updated \(minutes)m ago" }
        let hours = minutes / 60
        return "Updated \(hours)h ago"
    }
}
