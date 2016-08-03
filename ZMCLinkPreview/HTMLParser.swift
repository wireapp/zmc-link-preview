//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see http://www.gnu.org/licenses/.
//

import Ono

struct PreviewProperties {
    private(set) var contentsByType = [OpenGraphPropertyType: String]()
    private(set) var images = Set<String>()
    
    mutating func addProperty(type: OpenGraphPropertyType, value: String) {
        guard let content = value.resolvingXMLEntityReferences() else { return }
        if type == .Image {
            images.insert(content)
        } else {
            contentsByType[type] = content
        }
    }
}

func +(lhs: PreviewProperties, rhs: PreviewProperties) -> PreviewProperties {
    let images = rhs.images.union(lhs.images)
    var contents = lhs.contentsByType
    for (type, value) in rhs.contentsByType {
        contents[type] = value
    }
    return PreviewProperties(contentsByType: contents, images: images)
}


protocol ParserType {
    func parse(document: ONOXMLDocument) -> PreviewProperties
}

final class HTMLParser: NSObject {

    typealias ParserCompletion = PreviewProperties -> Void

    let document: ONOXMLDocument?
    var properties = PreviewProperties()
    var originalURL: NSURL
    let parsers: [ParserType]
    
    init(_ xmlString: String, url: NSURL, parsers: [ParserType]) {
        document = try? ONOXMLDocument.HTMLDocumentWithString(xmlString, encoding: NSUTF8StringEncoding)
        originalURL = url
        self.parsers = parsers
        super.init()
    }
    
    func parse() -> PreviewProperties {
        guard let document = document else { return PreviewProperties() }
        parseXML(document)
        insertMissingUrlIfNeeded()
        insertMissingTitleIfNeeded()
        return properties
    }
    
    private func parseXML(xmlDocument: ONOXMLDocument) {
        for parser in parsers {
            let result = parser.parse(xmlDocument)
            properties = properties + result
        }
    }
    
    func insertMissingUrlIfNeeded() {
        guard !properties.contentsByType.keys.contains(.Url) else { return }
        properties.addProperty(.Url, value: originalURL.absoluteString)
    }
    
    func insertMissingTitleIfNeeded() {
        guard !properties.contentsByType.keys.contains(.Title) else { return }
        
        document?.enumerateElementsWithXPath("//title", usingBlock: { [weak self] (element, _, _) in
            guard let `self` = self else { return }
            self.properties.addProperty(.Title, value: element.stringValue())
        })
    }
}

final class OpenGraphParser: ParserType {
    
    func parse(document: ONOXMLDocument) -> PreviewProperties {
        var properties = PreviewProperties()
        
        document.enumerateElementsWithXPath("//meta", usingBlock: { element, _, _ in
            guard let property = element[OpenGraphAttribute.Property.rawValue] as? String,
                content = element[OpenGraphAttribute.Content.rawValue] as? String,
                type = OpenGraphPropertyType(rawValue: property) else { return }
            properties.addProperty(type, value: content)
        })
        
        return properties
    }
    
}
