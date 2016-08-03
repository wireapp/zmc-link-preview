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


//final class FoursquareScanner: ScannerType {
//    
//    typealias ParserCompletion = OpenGraphData? -> Void
//    
//    var parser: HTMLParser? = nil
//    var completion: ParserCompletion
//    
//    init(_ xmlString: String, url: NSURL, completion: ParserCompletion) {
//        self.completion = completion
//        parser = HTMLParser(xmlString, url: url, parsers: [OpenGraphParser(), FoursquareImageParser()]) { properties in
//            self.createObjectAndComplete(properties)
//        }
//    }
//    
//    func parse() {
//        parser?.parse()
//    }
//    
//    func createObjectAndComplete(properties: PreviewProperties) {
//        let data = OpenGraphData(propertyMapping: properties.contentsByType, images: properties.images)
//        completion(data)
//    }
//}


final class FoursquareImageParser: ParserType {
    
    func parse(document: ONOXMLDocument) -> PreviewProperties {
        var properties = PreviewProperties()
        guard let img = document.firstChildWithXPath("//li[@class='photo photoWithContent']/img") else { return properties }
        guard let urlString = img.attributes?["src"] as? String else { return properties }
        properties.addProperty(.Image, value: urlString)
        return properties
    }
    
}
