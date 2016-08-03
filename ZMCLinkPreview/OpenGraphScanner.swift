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


typealias ParserCompletion = OpenGraphData? -> Void

protocol ScannerType {
    init(url: NSURL)
    func parse(completion: ParserCompletion)
}

final class OpenGraphScanner: ScannerType {

    var url: NSURL
    var streamContainer = MetaStreamContainer()
    
    var readyToParse: Bool { return streamContainer.reachedEnd }
    
    func addData(data: NSData) {
        streamContainer.addData(data)
    }
    
    init(url: NSURL) {
        self.url = url
    }
    
    func parse(completion: ParserCompletion) {
        guard readyToParse else { fatalError("Should only call parse if scanner is ready to parse") }
        guard let string = streamContainer.content else { return completion(nil) }
        let parser = HTMLParser(string, url: url, parsers: [OpenGraphParser()])
        let properties = parser.parse()
        let data = OpenGraphData(propertyMapping: properties.contentsByType, images: properties.images)
        completion(data)
    }
}
