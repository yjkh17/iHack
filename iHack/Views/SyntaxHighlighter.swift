//
//  SyntaxHighlighter.swift
//  iHack
//
//  Created by Yousef Jawdat on 28/05/2025.
//

import SwiftUI
import AppKit

enum SyntaxTheme: String, CaseIterable {
    case dark = "Dark"
    case light = "Light"
    case monokai = "Monokai"
    case github = "GitHub"
    case xcode = "Xcode"
    
    var backgroundColor: Color {
        switch self {
        case .dark: return Color(red: 0.12, green: 0.12, blue: 0.12)
        case .light: return Color.white
        case .monokai: return Color(red: 0.16, green: 0.16, blue: 0.16)
        case .github: return Color(red: 0.98, green: 0.98, blue: 0.98)
        case .xcode: return Color(red: 0.15, green: 0.16, blue: 0.17)
        }
    }
    
    var textColor: Color {
        switch self {
        case .dark: return Color.white
        case .light: return Color.black
        case .monokai: return Color(red: 0.97, green: 0.97, blue: 0.94)
        case .github: return Color(red: 0.13, green: 0.16, blue: 0.20)
        case .xcode: return Color.white
        }
    }
    
    var keywordColor: Color {
        switch self {
        case .dark: return Color(red: 0.73, green: 0.40, blue: 0.96)
        case .light: return Color(red: 0.53, green: 0.11, blue: 0.89)
        case .monokai: return Color(red: 0.98, green: 0.15, blue: 0.45)
        case .github: return Color(red: 0.82, green: 0.10, blue: 0.78)
        case .xcode: return Color(red: 0.96, green: 0.31, blue: 0.64)
        }
    }
    
    var stringColor: Color {
        switch self {
        case .dark: return Color(red: 1.0, green: 0.40, blue: 0.40)
        case .light: return Color(red: 0.77, green: 0.10, blue: 0.09)
        case .monokai: return Color(red: 0.90, green: 0.86, blue: 0.45)
        case .github: return Color(red: 0.03, green: 0.52, blue: 0.31)
        case .xcode: return Color(red: 0.91, green: 0.31, blue: 0.24)
        }
    }
    
    var commentColor: Color {
        switch self {
        case .dark: return Color(red: 0.55, green: 0.64, blue: 0.68)
        case .light: return Color(red: 0.42, green: 0.48, blue: 0.54)
        case .monokai: return Color(red: 0.46, green: 0.53, blue: 0.50)
        case .github: return Color(red: 0.40, green: 0.48, blue: 0.51)
        case .xcode: return Color(red: 0.42, green: 0.75, blue: 0.38)
        }
    }
    
    var numberColor: Color {
        switch self {
        case .dark: return Color(red: 0.68, green: 0.85, blue: 1.0)
        case .light: return Color(red: 0.16, green: 0.38, blue: 0.84)
        case .monokai: return Color(red: 0.68, green: 0.51, blue: 1.0)
        case .github: return Color(red: 0.00, green: 0.36, blue: 0.75)
        case .xcode: return Color(red: 0.11, green: 0.33, blue: 0.95)
        }
    }
    
    var functionColor: Color {
        switch self {
        case .dark: return Color(red: 0.40, green: 0.85, blue: 0.94)
        case .light: return Color(red: 0.24, green: 0.51, blue: 0.89)
        case .monokai: return Color(red: 0.40, green: 0.85, blue: 0.94)
        case .github: return Color(red: 0.44, green: 0.20, blue: 0.70)
        case .xcode: return Color(red: 0.26, green: 0.64, blue: 0.76)
        }
    }
}

struct ColoredRange {
    let range: NSRange
    let color: Color
    let priority: Int
}

struct SyntaxHighlighter {
    static func highlightCode(_ code: String, language: String, theme: SyntaxTheme) -> AttributedString {
        var attributedString = AttributedString(code)
        
        // Apply base text color and font
        attributedString.foregroundColor = theme.textColor
        attributedString.font = .system(.body, design: .monospaced)
        
        // Collect all colored ranges with priorities
        var coloredRanges: [ColoredRange] = []
        
        // Apply language-specific highlighting
        switch language.lowercased() {
        case "swift":
            collectSwiftRanges(code, theme: theme, coloredRanges: &coloredRanges)
        case "json":
            collectJSONRanges(code, theme: theme, coloredRanges: &coloredRanges)
        case "javascript", "js":
            collectJavaScriptRanges(code, theme: theme, coloredRanges: &coloredRanges)
        case "python", "py":
            collectPythonRanges(code, theme: theme, coloredRanges: &coloredRanges)
        case "c++", "cpp", "c":
            collectCRanges(code, theme: theme, coloredRanges: &coloredRanges)
        case "objective-c":
            collectObjectiveCRanges(code, theme: theme, coloredRanges: &coloredRanges)
        case "xml", "html":
            collectXMLRanges(code, theme: theme, coloredRanges: &coloredRanges)
        case "css":
            collectCSSRanges(code, theme: theme, coloredRanges: &coloredRanges)
        default:
            collectGenericRanges(code, theme: theme, coloredRanges: &coloredRanges)
        }
        
        // Apply colors in priority order (highest priority wins)
        applyColorsWithPriority(&attributedString, coloredRanges: coloredRanges)
        
        return attributedString
    }
    
    static func collectJSONRanges(_ code: String, theme: SyntaxTheme, coloredRanges: inout [ColoredRange]) {
        let jsonKeywords = ["true", "false", "null"]
        
        // Strings have highest priority
        collectStringRanges(code, color: theme.stringColor, priority: 1, coloredRanges: &coloredRanges)
        // Keywords have medium priority
        collectKeywordRanges(code, keywords: jsonKeywords, color: theme.keywordColor, priority: 2, coloredRanges: &coloredRanges)
        // Numbers have lowest priority
        collectNumberRanges(code, color: theme.numberColor, priority: 3, coloredRanges: &coloredRanges)
    }
    
    static func collectSwiftRanges(_ code: String, theme: SyntaxTheme, coloredRanges: inout [ColoredRange]) {
        let swiftKeywords = [
            "import", "class", "struct", "enum", "protocol", "extension", "func", "var", "let",
            "if", "else", "for", "while", "switch", "case", "default", "return", "break", "continue",
            "private", "public", "internal", "open", "static", "final", "override", "mutating",
            "init", "deinit", "self", "super", "nil", "true", "false", "try", "catch", "throw",
            "guard", "defer", "async", "await", "actor", "@State", "@Binding", "@ObservedObject"
        ]
        
        collectCommentRanges(code, color: theme.commentColor, priority: 1, coloredRanges: &coloredRanges)
        collectStringRanges(code, color: theme.stringColor, priority: 2, coloredRanges: &coloredRanges)
        collectKeywordRanges(code, keywords: swiftKeywords, color: theme.keywordColor, priority: 3, coloredRanges: &coloredRanges)
        collectNumberRanges(code, color: theme.numberColor, priority: 4, coloredRanges: &coloredRanges)
    }
    
    static func collectJavaScriptRanges(_ code: String, theme: SyntaxTheme, coloredRanges: inout [ColoredRange]) {
        let jsKeywords = [
            "var", "let", "const", "function", "return", "if", "else", "for", "while", "do",
            "switch", "case", "default", "break", "continue", "try", "catch", "finally",
            "throw", "new", "this", "typeof", "instanceof", "true", "false", "null", "undefined"
        ]
        
        collectCommentRanges(code, color: theme.commentColor, priority: 1, coloredRanges: &coloredRanges)
        collectStringRanges(code, color: theme.stringColor, priority: 2, coloredRanges: &coloredRanges)
        collectKeywordRanges(code, keywords: jsKeywords, color: theme.keywordColor, priority: 3, coloredRanges: &coloredRanges)
        collectNumberRanges(code, color: theme.numberColor, priority: 4, coloredRanges: &coloredRanges)
    }
    
    static func collectPythonRanges(_ code: String, theme: SyntaxTheme, coloredRanges: inout [ColoredRange]) {
        let pythonKeywords = [
            "def", "class", "import", "from", "return", "if", "elif", "else", "for", "while",
            "try", "except", "finally", "with", "as", "pass", "break", "continue", "and", "or",
            "not", "in", "is", "True", "False", "None", "self", "lambda", "yield", "global"
        ]
        
        collectCommentRanges(code, color: theme.commentColor, prefix: "#", priority: 1, coloredRanges: &coloredRanges)
        collectStringRanges(code, color: theme.stringColor, priority: 2, coloredRanges: &coloredRanges)
        collectKeywordRanges(code, keywords: pythonKeywords, color: theme.keywordColor, priority: 3, coloredRanges: &coloredRanges)
        collectNumberRanges(code, color: theme.numberColor, priority: 4, coloredRanges: &coloredRanges)
    }
    
    static func collectCRanges(_ code: String, theme: SyntaxTheme, coloredRanges: inout [ColoredRange]) {
        let cKeywords = [
            "int", "float", "double", "char", "void", "long", "short", "unsigned", "signed",
            "if", "else", "for", "while", "do", "switch", "case", "default", "break", "continue",
            "return", "struct", "union", "enum", "typedef", "const", "static", "extern", "auto",
            "register", "volatile", "sizeof", "NULL", "true", "false"
        ]
        
        collectCommentRanges(code, color: theme.commentColor, priority: 1, coloredRanges: &coloredRanges)
        collectStringRanges(code, color: theme.stringColor, priority: 2, coloredRanges: &coloredRanges)
        collectKeywordRanges(code, keywords: cKeywords, color: theme.keywordColor, priority: 3, coloredRanges: &coloredRanges)
        collectNumberRanges(code, color: theme.numberColor, priority: 4, coloredRanges: &coloredRanges)
    }
    
    static func collectObjectiveCRanges(_ code: String, theme: SyntaxTheme, coloredRanges: inout [ColoredRange]) {
        let objcKeywords = [
            "@interface", "@implementation", "@end", "@property", "@synthesize", "@dynamic",
            "@class", "@protocol", "@optional", "@required", "@selector", "@encode", "@synchronized",
            "id", "nil", "YES", "NO", "self", "super", "Class", "SEL", "IMP", "BOOL",
            "NSString", "NSInteger", "NSUInteger", "CGFloat", "instancetype"
        ]
        
        collectCommentRanges(code, color: theme.commentColor, priority: 1, coloredRanges: &coloredRanges)
        collectStringRanges(code, color: theme.stringColor, priority: 2, coloredRanges: &coloredRanges)
        collectKeywordRanges(code, keywords: objcKeywords, color: theme.keywordColor, priority: 3, coloredRanges: &coloredRanges)
        collectNumberRanges(code, color: theme.numberColor, priority: 4, coloredRanges: &coloredRanges)
    }
    
    static func collectXMLRanges(_ code: String, theme: SyntaxTheme, coloredRanges: inout [ColoredRange]) {
        collectCommentRanges(code, color: theme.commentColor, prefix: "<!--", suffix: "-->", priority: 1, coloredRanges: &coloredRanges)
        collectStringRanges(code, color: theme.stringColor, priority: 2, coloredRanges: &coloredRanges)
        
        // XML tags
        let tagPattern = try! NSRegularExpression(pattern: "<[^>]+>", options: [])
        let range = NSRange(location: 0, length: code.count)
        
        for match in tagPattern.matches(in: code, range: range) {
            coloredRanges.append(ColoredRange(range: match.range, color: theme.keywordColor, priority: 3))
        }
    }
    
    static func collectCSSRanges(_ code: String, theme: SyntaxTheme, coloredRanges: inout [ColoredRange]) {
        let cssKeywords = [
            "color", "background", "font", "margin", "padding", "border", "width", "height",
            "display", "position", "top", "left", "right", "bottom", "float", "clear"
        ]
        
        collectCommentRanges(code, color: theme.commentColor, prefix: "/*", suffix: "*/", priority: 1, coloredRanges: &coloredRanges)
        collectStringRanges(code, color: theme.stringColor, priority: 2, coloredRanges: &coloredRanges)
        collectKeywordRanges(code, keywords: cssKeywords, color: theme.keywordColor, priority: 3, coloredRanges: &coloredRanges)
    }
    
    static func collectGenericRanges(_ code: String, theme: SyntaxTheme, coloredRanges: inout [ColoredRange]) {
        collectCommentRanges(code, color: theme.commentColor, priority: 1, coloredRanges: &coloredRanges)
        collectStringRanges(code, color: theme.stringColor, priority: 2, coloredRanges: &coloredRanges)
        collectNumberRanges(code, color: theme.numberColor, priority: 3, coloredRanges: &coloredRanges)
    }
    
    // Collection helpers
    static func collectKeywordRanges(_ code: String, keywords: [String], color: Color, priority: Int, coloredRanges: inout [ColoredRange]) {
        for keyword in keywords {
            let pattern = try! NSRegularExpression(pattern: "\\b\(NSRegularExpression.escapedPattern(for: keyword))\\b", options: [])
            let range = NSRange(location: 0, length: code.count)
            
            for match in pattern.matches(in: code, range: range) {
                coloredRanges.append(ColoredRange(range: match.range, color: color, priority: priority))
            }
        }
    }
    
    static func collectStringRanges(_ code: String, color: Color, priority: Int, coloredRanges: inout [ColoredRange]) {
        let stringPattern = try! NSRegularExpression(pattern: "\"[^\"]*\"|'[^']*'", options: [])
        let range = NSRange(location: 0, length: code.count)
        
        for match in stringPattern.matches(in: code, range: range) {
            coloredRanges.append(ColoredRange(range: match.range, color: color, priority: priority))
        }
    }
    
    static func collectCommentRanges(_ code: String, color: Color, prefix: String = "//", suffix: String? = nil, priority: Int, coloredRanges: inout [ColoredRange]) {
        let pattern: String
        if let suffix = suffix {
            pattern = "\(NSRegularExpression.escapedPattern(for: prefix)).*?\(NSRegularExpression.escapedPattern(for: suffix))"
        } else {
            pattern = "\(NSRegularExpression.escapedPattern(for: prefix)).*$"
        }
        
        let commentPattern = try! NSRegularExpression(pattern: pattern, options: [.anchorsMatchLines])
        let range = NSRange(location: 0, length: code.count)
        
        for match in commentPattern.matches(in: code, range: range) {
            coloredRanges.append(ColoredRange(range: match.range, color: color, priority: priority))
        }
    }
    
    static func collectNumberRanges(_ code: String, color: Color, priority: Int, coloredRanges: inout [ColoredRange]) {
        let numberPattern = try! NSRegularExpression(pattern: "\\b\\d+(\\.\\d+)?\\b", options: [])
        let range = NSRange(location: 0, length: code.count)
        
        for match in numberPattern.matches(in: code, range: range) {
            coloredRanges.append(ColoredRange(range: match.range, color: color, priority: priority))
        }
    }
    
    static func applyColorsWithPriority(_ text: inout AttributedString, coloredRanges: [ColoredRange]) {
        // Sort by priority (lower number = higher priority)
        let sortedRanges = coloredRanges.sorted { $0.priority < $1.priority }
        
        // Track which characters have been colored
        var coloredPositions = Set<Int>()
        
        for coloredRange in sortedRanges {
            let range = coloredRange.range
            let positions = Set(range.location..<(range.location + range.length))
            
            // Only apply if no characters in this range have been colored yet
            if positions.isDisjoint(with: coloredPositions) {
                if let stringRange = Range(range, in: text) {
                    text[stringRange].foregroundColor = coloredRange.color
                    coloredPositions.formUnion(positions)
                }
            }
        }
    }
}
