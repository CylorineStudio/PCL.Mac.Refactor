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
                    result.append(TextComponent(content: try RichText.parse(rawContent: textBuffer, trimText: config.trimText), style: .init()))
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
            result.append(TextComponent(content: try RichText.parse(rawContent: textBuffer, trimText: config.trimText), style: .init()))
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
                throw XMLDeserializationError.attributeDeserializationFailed(type: "MyHint.Color", attribute: attribute)
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
    let style: Style
    
    static func deserialize(_ context: Homepage.DeserializeContext, _ element: XMLIndexer) throws -> TextComponent {
        return try TextComponent(
            content: RichText.parse(element, trimText: context.config.trimText),
            style: .deserialize(element)
        )
    }
    
    func makeView() -> some View {
        MyText(content)
            .applyingStyle(style)
    }
}

private enum RichText {
    private static let pclEnglishCharacterSet: CharacterSet = {
        guard let font = NSFont(name: "PCLEnglish", size: 14) else { return .init() }
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
        
        result = applyingFont(to: result)
        
        return result
    }
    
    static func parseColor(from text: String) -> Color? {
        let hexString = text.dropFirst()
        let hex: UInt?
        let alpha: Double
        
        if hexString.count == 6 {
            hex = .init(hexString, radix: 16)
            alpha = 1
        } else if hexString.count == 8 {
            hex = .init(hexString.dropFirst(2), radix: 16)
            guard let a = UInt8(hexString.prefix(2), radix: 16) else { return nil }
            alpha = Double(a) / 255.0
        } else {
            return nil
        }
        
        guard let hex else { return nil }
        return .init(hex, alpha: alpha)
    }
    
    private static func parseBlock(_ block: any StringProtocol) -> AttributedString {
        let parts = block.split(separator: ";", maxSplits: 1, omittingEmptySubsequences: false)
        guard parts.count == 2 else { return .init(block) }
        
        let styles = parts[0].split(separator: ",")
        var result: AttributedString = .init(String(parts[1]).trimmingCharacters(in: .whitespacesAndNewlines))
        
        for style in styles {
            let style = String(style).trimmingCharacters(in: .whitespacesAndNewlines)
            switch style {
            case "bold":
                result.font = (result.font ?? .system(size: 14)).bold()
                result.richText.isBoldOrItalic = true
            case "italic":
                result.font = (result.font ?? .system(size: 14)).italic()
                result.richText.isBoldOrItalic = true
            default:
                if style.hasSuffix("px"), let size = Float(style.dropLast(2)) {
                    let size = CGFloat(size)
                    result.font = .system(size: size)
                    result.richText.originalFontSize = size
                } else if style.hasPrefix("#"), let color = parseColor(from: style) {
                    result.foregroundColor = color
                }
            }
        }
        
        return result
    }
    
    private static func applyingFont(to text: AttributedString) -> AttributedString {
        var result = AttributedString()
        let runs = text.runs
        for run in runs {
            let substr = text[run.range]
            if substr.richText.isBoldOrItalic == true {
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
}

private extension AttributeScopes {
    struct OriginalFontSizeKey: AttributedStringKey {
        typealias Value = CGFloat
        static let name = "originalFontSize"
    }
    
    struct IsBoldOrItalicKey: AttributedStringKey {
        typealias Value = Bool
        static let name = "isBoldOrItalic"
    }
    
    struct RichTextAttributes: AttributeScope {
        let originalFontSize: OriginalFontSizeKey
        let isBoldOrItalic: IsBoldOrItalicKey
    }
    
    var richText: RichTextAttributes.Type { RichTextAttributes.self }
}

private struct Style: XMLObjectDeserialization {
    enum ColorStyle: XMLAttributeDeserializable {
        case solid(color: Color)
        case linearGradient(LinearGradient)
        case radialGradient(RadialGradient)
        case angularGradient(AngularGradient)
        
        static func deserialize(_ attribute: XMLAttribute) throws -> Style.ColorStyle {
            let text = attribute.text
            if text.starts(with: "#") {
                guard let color = RichText.parseColor(from: text) else {
                    throw XMLDeserializationError.attributeDeserializationFailed(type: "ColorStyle.solid", attribute: attribute)
                }
                return .solid(color: color)
            }
            
            let error = XMLDeserializationError.attributeDeserializationFailed(type: "ColorStyle", attribute: attribute)
            
            let input = text.trimmingCharacters(in: .whitespacesAndNewlines)
            let typeEndIndex = input.firstIndex(of: "(") ?? input.endIndex
            let type = String(input[..<typeEndIndex]).trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            
            guard let openParenIndex = input.firstIndex(of: "("),
                  let closeParenIndex = input.lastIndex(of: ")"),
                  openParenIndex < closeParenIndex else {
                throw error
            }
            let args = input[input.index(after: openParenIndex)..<closeParenIndex]
                .split(separator: ",").map {
                    String($0).trimmingCharacters(in: .whitespacesAndNewlines)
                }
            
            switch type {
            case "lineargradient":
                guard args.count >= 5,
                      let startX = Float(args[0]), let startY = Float(args[1]),
                      let endX = Float(args[2]), let endY = Float(args[3])
                else { throw error }
                
                let colors = args.dropFirst(4).compactMap { RichText.parseColor(from: $0) }
                guard colors.count == args.count - 4 else { throw error }
                
                return .linearGradient(
                    .init(
                        colors: colors,
                        startPoint: .init(x: .init(startX), y: .init(startY)),
                        endPoint: .init(x: .init(endX), y: .init(endY))
                    )
                )
            case "radialgradient":
                guard args.count >= 5,
                      let startRadius = Float(args[0]), let endRadius = Float(args[1]),
                      let centerX = Float(args[2]), let centerY = Float(args[3])
                else { throw error }
                
                let colors = args.dropFirst(4).compactMap { RichText.parseColor(from: $0) }
                guard colors.count == args.count - 4 else { throw error }
                
                return .radialGradient(
                    .init(
                        colors: colors,
                        center: .init(x: .init(centerX), y: .init(centerY)),
                        startRadius: .init(startRadius),
                        endRadius: .init(endRadius)
                    )
                )
            
            case "angulargradient":
                guard args.count >= 4,
                      let angle = Double(args[0]),
                      let centerX = Float(args[2]), let centerY = Float(args[3])
                else { throw error }
                
                let colors = args.dropFirst(4).compactMap { RichText.parseColor(from: $0) }
                guard colors.count == args.count - 4 else { throw error }
                
                return .angularGradient(
                    .init(
                        colors: colors,
                        center: .init(x: .init(centerX), y: .init(centerY)),
                        angle: .degrees(angle)
                    )
                )
            default:
                err("未知的 ColorStyle 类型：\(type)")
                throw error
            }
        }
        
        var style: any ShapeStyle {
            switch self {
            case .solid(let color): color
            case .linearGradient(let linearGradient): linearGradient
            case .radialGradient(let radialGradient): radialGradient
            case .angularGradient(let angularGradient): angularGradient
            }
        }
    }
    
    let background: any ShapeStyle
    let border: (style: any ShapeStyle, width: CGFloat)
    let cornerRadius: CGFloat
    
    init() {
        self.background = .clear
        self.border = (Color.clear, width: 0)
        self.cornerRadius = 0
    }
    
    init(
        background: any ShapeStyle,
        border: (style: any ShapeStyle, width: CGFloat),
        cornerRadius: CGFloat
    ) {
        self.background = background
        self.border = border
        self.cornerRadius = cornerRadius
    }
    
    static func deserialize(_ element: XMLIndexer) throws -> Style {
        return .init(
            background: (element.value(ofAttribute: "background") as ColorStyle?)?.style ?? .clear,
            border: (Color.clear, width: 0),
            cornerRadius: 0
        )
    }
}

private extension View {
    @ViewBuilder
    func applyingStyle(_ style: Style) -> some View {
        self
            .background(AnyShapeStyle(style.background))
    }
}
