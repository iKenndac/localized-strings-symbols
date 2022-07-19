import Foundation

struct StringSymbolBuilder {

    /// Returns a symbol definition for a localized key with no format specifiers.
    static func symbolDefinition(for keySymbol: String, fullKey: String, hasPluralization: Bool,
                                 pluralizedFullKey: String, indentLevel: Int = 4) -> [String] {
        let indent: String = String(repeating: " ", count: indentLevel)
        var generatedCode: [String] = []
        if hasPluralization {
            generatedCode.append("\(indent)static func \(keySymbol)(pluralizationCount: Int) -> String {")
            generatedCode.append("\(indent)\(indent)return NSLocalizedString(pluralizationCount == 1 ? \"\(fullKey)\" : \"\(pluralizedFullKey)\", tableName: \"\(tableName)\", comment: \"\")")
            generatedCode.append("\(indent)}")
        } else {
            generatedCode.append("\(indent)static var \(keySymbol): String {")
            generatedCode.append("\(indent)\(indent)return NSLocalizedString(\"\(fullKey)\", tableName: \"\(tableName)\", comment: \"\")")
            generatedCode.append("\(indent)}")
        }
        return generatedCode
    }

    /// Returns a symbol definition for a localized key with format specifiers.
    static func symbolDefinition(for keySymbol: String, fullKey: String, formatSpecifiers: [String],
                                 hasPluralization: Bool, pluralizedFullKey: String, indentLevel: Int = 4) -> [String] {
        let indent: String = String(repeating: " ", count: indentLevel)
        var generatedCode: [String] = []

        let stringParameterList: String = formatSpecifiers.enumerated().map({ "formatValue value\($0.offset): String" }).joined(separator: ", ")
        let parameterFormatList: String = formatSpecifiers.enumerated().map({ "value\($0.offset)" }).joined(separator: ", ")

        if hasPluralization {
            generatedCode.append("\(indent)static func \(keySymbol)(pluralizationCount: Int, \(stringParameterList)) -> String {")
            generatedCode.append("\(indent)\(indent)let string = NSLocalizedString(pluralizationCount == 1 ? \"\(fullKey)\" : \"\(pluralizedFullKey)\", tableName: \"\(tableName)\", comment: \"\")")
            generatedCode.append("\(indent)\(indent)return String(format: string, \(parameterFormatList))")
            generatedCode.append("\(indent)}")
        } else {
            generatedCode.append("\(indent)static func \(keySymbol)(\(stringParameterList)) -> String {")
            generatedCode.append("\(indent)\(indent)let string = NSLocalizedString(\"\(fullKey)\", tableName: \"\(tableName)\", comment: \"\")")
            generatedCode.append("\(indent)\(indent)return String(format: string, \(parameterFormatList))")
            generatedCode.append("\(indent)}")
        }

        return generatedCode
    }
}

struct SwiftUISymbolBuilder {

    /// Returns a symbol definition for a localized key with no format specifiers.
    static func symbolDefinition(for keySymbol: String, fullKey: String, hasPluralization: Bool,
                                 pluralizedSuffix: String, indentLevel: Int = 4) -> [String] {
        let indent: String = String(repeating: " ", count: indentLevel)
        if hasPluralization {
            var generatedCode: [String] = []
            generatedCode.append("\(indent)static func \(keySymbol)(pluralizationCount: Int) -> LocalizedStringKey {")
            generatedCode.append("\(indent)\(indent)return LocalizedStringKey(pluralizationCount == 1 ? \"\(fullKey)\" : \"\(fullKey)\(pluralizedSuffix)\")")
            generatedCode.append("\(indent)}")
            return generatedCode
        } else {
            return ["\(indent)static let \(keySymbol): LocalizedStringKey = LocalizedStringKey(\"\(fullKey)\")"]
        }
    }

    /// Returns a symbol definition for a localized key with format specifiers.
    static func symbolDefinition(for keySymbol: String, keyName: String, formatSpecifiers: [String],
                                 hasPluralization: Bool, pluralizedSuffix: String, indentLevel: Int = 4) -> [String] {
        let indent: String = String(repeating: " ", count: indentLevel)
        var generatedCode: [String] = []
        // Image func
        let imageParameterList: String = formatSpecifiers.enumerated().map({ "imageValue value\($0.offset): Image" }).joined(separator: ", ")

        if hasPluralization {
            generatedCode.append("\(indent)static func \(keySymbol)(pluralizationCount: Int, \(imageParameterList)) -> LocalizedStringKey {")
        } else {
            generatedCode.append("\(indent)static func \(keySymbol)(\(imageParameterList)) -> LocalizedStringKey {")
        }

        generatedCode.append("\(indent)\(indent)var interpolation = LocalizedStringKey.StringInterpolation(literalCapacity: \(1 + formatSpecifiers.count), interpolationCount: \(formatSpecifiers.count))")

        if hasPluralization {
            generatedCode.append("\(indent)\(indent)interpolation.appendLiteral(pluralizationCount == 1 ? \"\(keyName)\" : \"\(keyName)\(pluralizedSuffix)\")")
        } else {
            generatedCode.append("\(indent)\(indent)interpolation.appendLiteral(\"\(keyName)\")")
        }

        formatSpecifiers.enumerated().forEach({
            generatedCode.append("\(indent)\(indent)interpolation.appendLiteral(\" \")")
            generatedCode.append("\(indent)\(indent)interpolation.appendInterpolation(value\($0.offset))")
        })
        generatedCode.append("\(indent)\(indent)return LocalizedStringKey(stringInterpolation: interpolation)")
        generatedCode.append("\(indent)}")

        // String func
        let stringParameterList: String = formatSpecifiers.enumerated().map({ "formatValue value\($0.offset): String" }).joined(separator: ", ")

        if hasPluralization {
            generatedCode.append("\(indent)static func \(keySymbol)(pluralizationCount: Int, \(stringParameterList)) -> LocalizedStringKey {")
        } else {
            generatedCode.append("\(indent)static func \(keySymbol)(\(stringParameterList)) -> LocalizedStringKey {")
        }

        generatedCode.append("\(indent)\(indent)var interpolation = LocalizedStringKey.StringInterpolation(literalCapacity: \(1 + formatSpecifiers.count), interpolationCount: \(formatSpecifiers.count))")

        if hasPluralization {
            generatedCode.append("\(indent)\(indent)interpolation.appendLiteral(pluralizationCount == 1 ? \"\(keyName)\" : \"\(keyName)\(pluralizedSuffix)\")")
        } else {
            generatedCode.append("\(indent)\(indent)interpolation.appendLiteral(\"\(keyName)\")")
        }

        formatSpecifiers.enumerated().forEach({
            generatedCode.append("\(indent)\(indent)interpolation.appendLiteral(\" \")")
            generatedCode.append("\(indent)\(indent)interpolation.appendInterpolation(value\($0.offset))")
        })
        generatedCode.append("\(indent)\(indent)return LocalizedStringKey(stringInterpolation: interpolation)")
        generatedCode.append("\(indent)}")
        return generatedCode
    }
}
