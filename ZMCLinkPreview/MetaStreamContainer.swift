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

final class MetaStreamContainer: StreamContainerType {
    
    let parser = StreamParser(parsingEnd: OpenGraphXMLNode.HeadEnd.rawValue)
    
    var content: String? {
        guard let content = parser.stringContent else { return nil }
        let startRange = content.rangeOfString(OpenGraphXMLNode.HeadStart.rawValue)
        let endRange = content.rangeOfString(OpenGraphXMLNode.HeadEnd.rawValue)
        
        guard let start = startRange?.startIndex, end = endRange?.endIndex else { return nil }
        let result = content.characters[start..<end].map { String($0) }.joinWithSeparator("")
        return result
    }
}
