import Foundation

struct StringSymbolBuilder {

    /// Returns a symbol definition for a localized key with format specifiers.
    static func symbolDefinition(for key: ParsedKey, hasPluralization: Bool, indentLevel: Int = 4) -> [String] {
        let indent: String = String(repeating: " ", count: indentLevel)
        var generatedCode: [String] = []

        if key.formatSpecifierCount == 0 {
            if hasPluralization {
                generatedCode.append("\(indent)static func \(key.symbolisedKey)(pluralizationCount: Int) -> String {")
                generatedCode.append("\(indent)\(indent)return NSLocalizedString(pluralizationCount == 1 ? \"\(key.originalKey)\" : \"\(key.pluralisedOriginalKey)\", tableName: \"\(tableName)\", comment: \"\")")
                generatedCode.append("\(indent)}")
            } else {
                generatedCode.append("\(indent)static var \(key.symbolisedKey): String {")
                generatedCode.append("\(indent)\(indent)return NSLocalizedString(\"\(key.originalKey)\", tableName: \"\(tableName)\", comment: \"\")")
                generatedCode.append("\(indent)}")
            }
        } else {
            let stringParameterList: String = (0..<key.formatSpecifierCount).map({ "formatValue value\($0): String" }).joined(separator: ", ")
            let parameterFormatList: String = (0..<key.formatSpecifierCount).map({ "value\($0)" }).joined(separator: ", ")

            if hasPluralization {
                generatedCode.append("\(indent)static func \(key.symbolisedKey)(pluralizationCount: Int, \(stringParameterList)) -> String {")
                generatedCode.append("\(indent)\(indent)let string = NSLocalizedString(pluralizationCount == 1 ? \"\(key.originalKey)\" : \"\(key.pluralisedOriginalKey)\", tableName: \"\(tableName)\", comment: \"\")")
                generatedCode.append("\(indent)\(indent)return String(format: string, \(parameterFormatList))")
                generatedCode.append("\(indent)}")
            } else {
                generatedCode.append("\(indent)static func \(key.symbolisedKey)(\(stringParameterList)) -> String {")
                generatedCode.append("\(indent)\(indent)let string = NSLocalizedString(\"\(key.originalKey)\", tableName: \"\(tableName)\", comment: \"\")")
                generatedCode.append("\(indent)\(indent)return String(format: string, \(parameterFormatList))")
                generatedCode.append("\(indent)}")
            }
        }

        return generatedCode
    }
}

struct SwiftUISymbolBuilder {

    /// Returns a symbol definition for a localized key with format specifiers.
    static func symbolDefinition(key: ParsedKey, hasPluralization: Bool, pluralizedSuffix: String, indentLevel: Int = 4) -> [String] {
        guard key.formatSpecifierCount > 0 else {
            let indent: String = String(repeating: " ", count: indentLevel)
            let availabilityLine: String = "\(indent)@available(iOS 13.0, macOS 10.15, macCatalyst 13.0, tvOS 13.0, watchOS 6.0, *)"
            if hasPluralization {
                var generatedCode: [String] = [availabilityLine]
                generatedCode.append("\(indent)static func \(key.symbolisedKey)(pluralizationCount: Int) -> LocalizedStringKey {")
                generatedCode.append("\(indent)\(indent)return LocalizedStringKey(pluralizationCount == 1 ? \"\(key.originalKey)\" : \"\(key.pluralisedOriginalKey)\")")
                generatedCode.append("\(indent)}")
                return generatedCode
            } else {
                return [availabilityLine, "\(indent)static let \(key.symbolisedKey): LocalizedStringKey = LocalizedStringKey(\"\(key.originalKey)\")"]
            }
        }

        let indent: String = String(repeating: " ", count: indentLevel)
        var generatedCode: [String] = []
        // Image func
        let imageParameterList: String = (0..<key.formatSpecifierCount).map({ "imageValue value\($0): SwiftUI.Image" }).joined(separator: ", ")

        let imageInterpolationAvailabilityLine: String = "\(indent)@available(iOS 14.0, macOS 11.0, macCatalyst 14.0, tvOS 14.0, watchOS 7.0, *)"
        generatedCode.append(imageInterpolationAvailabilityLine)
        
        if hasPluralization {
            generatedCode.append("\(indent)static func \(key.symbolisedKey)(pluralizationCount: Int, \(imageParameterList)) -> LocalizedStringKey {")
        } else {
            generatedCode.append("\(indent)static func \(key.symbolisedKey)(\(imageParameterList)) -> LocalizedStringKey {")
        }

        generatedCode.append("\(indent)\(indent)var interpolation = LocalizedStringKey.StringInterpolation(literalCapacity: \(1 + key.formatSpecifierCount), interpolationCount: \(key.formatSpecifierCount))")

        func interpolationConstructionCode(for originalKey: String, indentCount: Int) -> [String] {
            guard #available(iOS 13.0, macCatalyst 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, visionOS 1.0, *) else { return [] }
            let combinedIndent = String(repeating: indent, count: indentCount)
            var codeComponents: [String] = []

            var formatSpecifiersEncountered: Int = 0
            var parsingKey = originalKey
            while parsingKey.hasPrefix("%@") {
                codeComponents.append("\(combinedIndent)interpolation.appendInterpolation(value\(formatSpecifiersEncountered))")
                formatSpecifiersEncountered += 1
                parsingKey.removeFirst(2)
            }

            let scanner = Scanner(string: parsingKey)
            scanner.charactersToBeSkipped = CharacterSet()
            while let literal = scanner.scanUpToString("%@") {
                codeComponents.append("\(combinedIndent)interpolation.appendLiteral(\"\(literal)\")")
                if let _ = scanner.scanString("%@") {
                    codeComponents.append("\(combinedIndent)interpolation.appendInterpolation(value\(formatSpecifiersEncountered))")
                    formatSpecifiersEncountered += 1
                }
            }
            return codeComponents
        }

        // This bit needs to completely reconstruct the original key, since format values can be interpolated.
        if hasPluralization {
            generatedCode.append("\(indent)\(indent)if pluralizationCount == 1 {")
            generatedCode.append(contentsOf: interpolationConstructionCode(for: key.originalKey, indentCount: 3))
            generatedCode.append("\(indent)\(indent)} else {")
            generatedCode.append(contentsOf: interpolationConstructionCode(for: key.pluralisedOriginalKey, indentCount: 3))
            generatedCode.append("\(indent)\(indent)}")
        } else {
            generatedCode.append(contentsOf: interpolationConstructionCode(for: key.originalKey, indentCount: 2))
        }

        generatedCode.append("\(indent)\(indent)return LocalizedStringKey(stringInterpolation: interpolation)")
        generatedCode.append("\(indent)}")

        // String func
        let stringParameterList: String = (0..<key.formatSpecifierCount).map({ "formatValue value\($0): String" }).joined(separator: ", ")

        let stringInterpolationAvailabilityLine: String = "\(indent)@available(iOS 13.0, macOS 10.15, macCatalyst 13.0, tvOS 13.0, watchOS 6.0, *)"
        generatedCode.append(stringInterpolationAvailabilityLine)

        if hasPluralization {
            generatedCode.append("\(indent)static func \(key.symbolisedKey)(pluralizationCount: Int, \(stringParameterList)) -> LocalizedStringKey {")
        } else {
            generatedCode.append("\(indent)static func \(key.symbolisedKey)(\(stringParameterList)) -> LocalizedStringKey {")
        }

        generatedCode.append("\(indent)\(indent)var interpolation = LocalizedStringKey.StringInterpolation(literalCapacity: \(1 + key.formatSpecifierCount), interpolationCount: \(key.formatSpecifierCount))")

        // This bit needs to completely reconstruct the original key, since format values can be interpolated.
        if hasPluralization {
            generatedCode.append("\(indent)\(indent)if pluralizationCount == 1 {")
            generatedCode.append(contentsOf: interpolationConstructionCode(for: key.originalKey, indentCount: 3))
            generatedCode.append("\(indent)\(indent)} else {")
            generatedCode.append(contentsOf: interpolationConstructionCode(for: key.pluralisedOriginalKey, indentCount: 3))
            generatedCode.append("\(indent)\(indent)}")
        } else {
            generatedCode.append(contentsOf: interpolationConstructionCode(for: key.originalKey, indentCount: 2))
        }

        generatedCode.append("\(indent)\(indent)return LocalizedStringKey(stringInterpolation: interpolation)")
        generatedCode.append("\(indent)}")
        return generatedCode
    }
}
