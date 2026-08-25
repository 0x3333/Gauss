import Cocoa

enum HelpContent {

    struct Section {
        let title: String
        let lines: [String]
    }

    static let sections: [Section] = [
        Section(title: "Basics", lines: [
            "2 + 2",
            "0.5",
            "1k",
            "0xFF",
        ]),
        Section(title: "Variables", lines: [
            "price = 49.99",
            "price * 2",
        ]),
        Section(title: "Lines", lines: [
            "@1",
            "prev",
            "sum",
            "total",
            "average",
        ]),
        Section(title: "Percent", lines: [
            "20% of 500",
            "tax on price",
            "10% off",
            "75 is what % of 600",
        ]),
        Section(title: "Functions", lines: [
            "sin  cos  tan  asin  acos  atan",
            "sinh  cosh  tanh",
            "sqrt  cbrt  root  log  ln",
            "abs  ceil  floor  round  fact",
        ]),
        Section(title: "Convert", lines: [
            "100 USD in EUR",
            "in  to  as",
        ]),
        Section(title: "Units", lines: [
            "5 km in miles",
            "100 lb in kg",
            "1 L in gallons",
            "1 acre in m2",
            "32 F in C",
            "90 deg in rad",
            "1 GB in MB",
            "2 hours in minutes",
        ]),
        Section(title: "Color", lines: [
            "#ff5733 in rgb",
            "rgb(255, 87, 51) in hsl",
        ]),
        Section(title: "Base64", lines: [
            "\"hello\" to base64",
        ]),
        Section(title: "Dates", lines: [
            "today",
            "now",
            "March 3 + 5 workdays",
        ]),
        Section(title: "Notes", lines: [
            "# header",
            "// comment",
            "Label:",
        ]),
    ]

    static let leftSections: [Section] = Array(sections.prefix(6))
    static let rightSections: [Section] = Array(sections.dropFirst(6))

    static var plainText: String {
        sections.map { section in
            ([section.title] + section.lines).joined(separator: "\n")
        }.joined(separator: "\n\n")
    }

    static func attributedString(for column: [Section] = sections) -> NSAttributedString {
        let result = NSMutableAttributedString()
        let titleFont = NSFont.systemFont(ofSize: 13, weight: .semibold)
        let bodyFont = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: Theme.headerColor,
        ]
        let bodyAttrs: [NSAttributedString.Key: Any] = [
            .font: bodyFont,
            .foregroundColor: Theme.textPrimary,
        ]

        for (index, section) in column.enumerated() {
            if index > 0 {
                result.append(NSAttributedString(string: "\n\n", attributes: bodyAttrs))
            }
            result.append(NSAttributedString(string: section.title, attributes: titleAttrs))
            result.append(NSAttributedString(string: "\n", attributes: bodyAttrs))
            result.append(NSAttributedString(
                string: section.lines.joined(separator: "\n"),
                attributes: bodyAttrs
            ))
        }
        return result
    }
}
