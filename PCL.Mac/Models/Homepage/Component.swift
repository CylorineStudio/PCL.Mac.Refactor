//
//  Component.swift
//  PCL.Mac
//
//  Created by AnemoFlower on 2026/6/2.
//

import SwiftUI
import SWXMLHash
import Core

protocol HomepageComponent {
    associatedtype Body: View
    
    @ViewBuilder
    func makeView() -> Body
    
    static func deserialize(_ context: Homepage.DeserializeContext, _ element: XMLIndexer) throws -> Self
}

struct HomepageComponentParser {
    let config: Homepage.Config
    
    func parseAll(_ indexer: XMLIndexer) throws -> [any HomepageComponent] {
        guard let element = indexer.element else { return [] }
        
        var result: [any HomepageComponent] = []
        var textBuffer = ""
        
        for element in element.children {
            if let xmlElement = element as? SWXMLHash.XMLElement {
                if !textBuffer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    result.append(TextComponent(content: try RichText.parse(rawContent: textBuffer, trimText: config.trimText)))
                }
                textBuffer = ""
                
                if let parsedComponent = parse(.element(xmlElement)) {
                    result.append(parsedComponent)
                }
            } else if let textElement = element as? TextElement {
                textBuffer += textElement.text
            }
        }
        
        if !textBuffer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            result.append(TextComponent(content: try RichText.parse(rawContent: textBuffer, trimText: config.trimText)))
        }
        
        return result
    }
    
    func parse(_ indexer: XMLIndexer) -> (any HomepageComponent)? {
        guard let element = indexer.element else { return nil }
        let context = Homepage.DeserializeContext(config: config, componentParser: self)
        do {
            return switch element.name.lowercased() {
            case "myhint", "mytip": try MyHintComponent.deserialize(context, indexer)
            case "mycard": try MyCardComponent.deserialize(context, indexer)
            case "text": try TextComponent.deserialize(context, indexer)
            default: nil
            }
        } catch {
            err("解析主页控件 \(element.name) 失败：\(error.localizedDescription)")
            return nil
        }
    }
}

private struct MyHintComponent: HomepageComponent {
    enum Color: String, XMLAttributeDeserializable {
        case blue, red, yellow
        
        var theme: MyTip.Theme {
            return switch self {
            case .blue: .blue
            case .red: .red
            case .yellow: .yellow
            }
        }
        
        static func deserialize(_ attribute: XMLAttribute) throws -> Color {
            guard let color = Color(rawValue: attribute.text) else {
                throw XMLDeserializationError.attributeDeserializationFailed(type: "Color", attribute: attribute)
            }
            return color
        }
    }
    
    let color: Color
    let content: AttributedString
    
    static func deserialize(_ context: Homepage.DeserializeContext, _ element: XMLIndexer) throws -> MyHintComponent {
        return try MyHintComponent(
            color: (element.value(ofAttribute: "color")) ?? .blue,
            content: RichText.parse(element, trimText: context.config.trimText)
        )
    }
    
    func makeView() -> some View {
        MyTip(attributedText: content, theme: color.theme)
    }
}

private struct MyCardComponent: HomepageComponent {
    let title: String?
    let foldable: Bool
    let folded: Bool
    let body: [any HomepageComponent]
    
    static func deserialize(_ context: Homepage.DeserializeContext, _ element: XMLIndexer) throws -> MyCardComponent {
        return try MyCardComponent(
            title: element.value(ofAttribute: "title"),
            foldable: element.value(ofAttribute: "foldable") ?? true,
            folded: element.value(ofAttribute: "folded") ?? true,
            body: context.componentParser.parseAll(element)
        )
    }
    
    func makeView() -> some View {
        MyCard(title, foldable: foldable, folded: folded) {
            ForEach(Array(body.enumerated()), id: \.offset) { _, entry in
                AnyView(entry.makeView())
            }
        }
    }
}

private struct TextComponent: HomepageComponent {
    let content: AttributedString
    
    static func deserialize(_ context: Homepage.DeserializeContext, _ element: XMLIndexer) throws -> TextComponent {
        return try TextComponent(content: RichText.parse(element, trimText: context.config.trimText))
    }
    
    func makeView() -> some View {
        MyText(content)
    }
}

private enum RichText {
    private static let pclEnglishCharacterSet: CharacterSet = {
        guard let font = NSFont(name: "PCLEnglish", size: 14) else { return CharacterSet() }
        return CTFontCopyCharacterSet(font as CTFont) as CharacterSet
    }()
    
    static func parse(_ indexer: XMLIndexer, trimText: Bool) throws -> AttributedString {
        return try parse(rawContent: indexer.value(), trimText: trimText)
    }
    
    static func parse(rawContent: String, trimText: Bool) throws -> AttributedString {
        let content = trimText
        ? rawContent
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .split(separator: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .joined(separator: "\n")
        : rawContent
        
        var result = AttributedString()
        
        var currentIndex = content.startIndex
        
        while currentIndex < content.endIndex {
            guard let openBrace = content[currentIndex...].firstIndex(of: "{") else {
                result += .init(content[currentIndex...])
                break
            }
            
            if openBrace > currentIndex {
                result += .init(content[currentIndex..<openBrace])
            }
            
            guard let closeBrace = content[openBrace...].firstIndex(of: "}") else {
                result += .init(content[openBrace...])
                break
            }
            
            let block = content[content.index(after: openBrace)..<closeBrace]
            result += parseBlock(block)
            currentIndex = content.index(after: closeBrace)
        }
        
        result = applyPCLEnglish(to: result)
        
        return result
    }
    
    private static func parseBlock(_ block: any StringProtocol) -> AttributedString {
        let parts = block.split(separator: ";", maxSplits: 1, omittingEmptySubsequences: false)
        guard parts.count == 2 else { return .init(block) }
        
        let styles = parts[0].split(separator: ",")
        var result: AttributedString = AttributedString(String(parts[1]).trimmingCharacters(in: .whitespacesAndNewlines))
        
        for style in styles {
            let style = String(style)
            switch style {
            case "bold":
                result.font = (result.font ?? .system(size: 14)).bold()
            case "italic":
                result.font = (result.font ?? .system(size: 14)).italic()
            default:
                if style.hasSuffix("px"), let size = Float(style.dropLast(2)) {
                    let size = CGFloat(size)
                    result.font = .system(size: size)
                    result.richText.originalFontSize = size
                } else if style.hasPrefix("#"), style.count == 7, let hex = UInt(style.dropFirst(), radix: 16) {
                    result.foregroundColor = .init(hex)
                }
            }
        }
        
        return result
    }
    
    private static func applyPCLEnglish(to text: AttributedString) -> AttributedString {
        var result = AttributedString()
        let runs = text.runs
        for run in runs {
            let substr = text[run.range]
            if isBoldOrItalic(substr.font) {
                result.append(substr)
                continue
            }
            
            var currentPart: String = ""
            var lastShouldUse: Bool? = nil
            for char in substr.characters {
                let shouldUse = char.unicodeScalars.allSatisfy(pclEnglishCharacterSet.contains)
                if let lastShouldUse, lastShouldUse != shouldUse {
                    result.append(buildAttributedPart(from: substr, currentPart, usePCLEnglish: lastShouldUse))
                    currentPart = ""
                }
                currentPart.append(char)
                lastShouldUse = shouldUse
            }
            if let lastShouldUse {
                result.append(buildAttributedPart(from: substr, currentPart, usePCLEnglish: lastShouldUse))
            }
        }
        
        return result
    }
    
    private static func buildAttributedPart(
        from source: any AttributedStringProtocol,
        _ content: String,
        usePCLEnglish: Bool
    ) -> AttributedString {
        var result = AttributedString(content)
        result.foregroundColor = source.foregroundColor
        let size = source.richText.originalFontSize ?? 14
        result.font = usePCLEnglish ? .custom("PCLEnglish", size: size) : .system(size: size)
        return result
    }
    
    private static func isBoldOrItalic(_ font: Font?) -> Bool {
        guard let font else { return false }
        let description = String(describing: font).lowercased()
        return description.contains("bold") || description.contains("italic")
    }
}

private struct OriginalFontSizeKey: AttributedStringKey {
    typealias Value = CGFloat
    static let name = "originalFontSize"
}

private extension AttributeScopes {
    struct RichTextAttributes: AttributeScope {
        let originalFontSize: OriginalFontSizeKey
    }
    
    var richText: RichTextAttributes.Type { RichTextAttributes.self }
}
