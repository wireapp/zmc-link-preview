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

protocol StreamContainerType {
    var parser: StreamParser { get }
    var content: String? { get }
}

extension StreamContainerType {
    var reachedEnd: Bool { return parser.reachedEnd }
    
    func addData(data: NSData) -> NSData {
        return parser.addData(data)
    }
}


class StreamParser {
    
    var parsingEnd: String
    var reachedEnd = false
    
    init(parsingEnd: String) {
        self.parsingEnd = parsingEnd
    }
    
    let bytes = NSMutableData()
    
    var stringContent: String? {
        return String(data: bytes, encoding: NSUTF8StringEncoding)
    }

    func updateReachedEnd(withData data: NSData) {
        guard let string = String(data: data, encoding: NSUTF8StringEncoding)?.lowercaseString else { return }
        if string.containsString(parsingEnd) {
            reachedEnd = true
        }
    }
    
    func addData(data: NSData) -> NSData {
        updateReachedEnd(withData: data)
        bytes.appendData(data)
        return bytes
    }
}

final class StreamContainerFactory {

    static func container(forURL url: NSURL) -> StreamContainerType {
        let urlString = url.absoluteString
        if urlString.containsString("foursquare") || urlString.containsString("4sq") {
            return FullSiteStreamContainer()
        }
        
        return MetaStreamContainer()
    }

}
