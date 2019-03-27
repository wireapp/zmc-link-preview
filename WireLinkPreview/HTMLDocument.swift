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

import Foundation
import HTMLString
import libxml2

// MARK: Models

/**
 * Wrapper around a `xmlDocPtr`, that represents an HTML document.
 */

class HTMLDocument {
    let rawPtr: xmlDocPtr

    /// Tries to parse the content of an XML string.
    init?(string: String) {
        let options = Int32(HTML_PARSE_NOWARNING.rawValue) | Int32(HTML_PARSE_NOERROR.rawValue) | Int32(HTML_PARSE_RECOVER.rawValue)
        let stringLength = string.utf8.count
        let decodedDocument = string.withCString(encodedAs: UTF8.self) { (xmlData: UnsafePointer<UInt8>) in
            xmlData.withMemoryRebound(to: Int8.self, capacity: stringLength) {
                return htmlReadMemory($0, Int32(stringLength), "", "UTF-8", options)
            }
        }

        guard let rawPtr = decodedDocument else { return nil }
        self.rawPtr = rawPtr
    }

    deinit {
        xmlFreeDoc(rawPtr)
    }

    /// Returns the root element of the document.
    var rootElement: HTMLElement? {
        guard let rootPtr = xmlDocGetRootElement(rawPtr) else { return nil }
        return HTMLElement(rawPtr: rootPtr)
    }
}

/**
 * Wrapper around a `xmlNodePtr`, that represents an element in an HTML DOM tree.
 */

class HTMLElement {
    let rawPtr: xmlNodePtr

    init(rawPtr: xmlNodePtr) {
        self.rawPtr = rawPtr
    }

    /// The name of the HTML tag.
    var tagName: HTMLStringBuffer {
        return HTMLStringBuffer(rawPtr.pointee.name)
    }

    /// The textual content of the element.
    var content: HTMLStringBuffer? {
        guard let text = xmlNodeGetContent(rawPtr) else { return nil }
        return HTMLStringBuffer(text)
    }

    /// The children of the element, as an iterable sequence.
    var children: HTMLChildrenSequence {
        let iterator = HTMLChildrenIterator(rootElement: self)
        return HTMLChildrenSequence(iterator)
    }

    /// The attributes of the element.
    var attributes: HTMLAttributesContainer {
        return HTMLAttributesContainer(element: self)
    }
}

// MARK: - Helper Types

/// A sequence of HTML elements.
typealias HTMLChildrenSequence = IteratorSequence<HTMLChildrenIterator>

class HTMLChildrenIterator: IteratorProtocol {
    let rootElement: HTMLElement
    let numberOfChildren: UInt
    var currentChild: HTMLElement?

    init(rootElement: HTMLElement) {
        self.rootElement = rootElement
        self.numberOfChildren = xmlChildElementCount(rootElement.rawPtr)
        self.currentChild = nil
    }

    func next() -> HTMLElement? {
        guard numberOfChildren > 0 else {
            return nil
        }

        let nextPtr: xmlNodePtr?

        if let currentChild = self.currentChild {
            nextPtr = xmlNextElementSibling(currentChild.rawPtr)
        } else {
            nextPtr = xmlFirstElementChild(rootElement.rawPtr)
        }

        currentChild = nextPtr.map(HTMLElement.init)
        return currentChild
    }
}

/**
 * Wrapper to access the elements of an HTML element through subscripting.
 */

class HTMLAttributesContainer {
    let element: HTMLElement

    init(element: HTMLElement) {
        self.element = element
    }

    subscript(attributeName: String) -> HTMLStringBuffer? {
        guard let xmlProp = xmlGetProp(element.rawPtr, attributeName) else { return nil }
        return HTMLStringBuffer(xmlProp)
    }
}

/**
 * Wrapper around a `xmlCharPtr`, that represents an HTML string.
 */

class HTMLStringBuffer {
    enum Storage {
        case retained(UnsafeMutablePointer<xmlChar>)
        case unowned(UnsafePointer<xmlChar>)

        var ptr: UnsafePointer<xmlChar> {
            switch self {
            case .retained(let ptr): return UnsafePointer(ptr)
            case .unowned(let ptr): return ptr
            }
        }
    }

    let storage: Storage

    /// Creates a new string wrapper.
    init(_ ptr: UnsafePointer<xmlChar>) {
        self.storage = .unowned(ptr)
    }

    /// Creates a new string wrapper.
    init(_ ptr: UnsafeMutablePointer<xmlChar>) {
        self.storage = .retained(ptr)
    }

    deinit {
        if case let .retained(ptr) = storage {
            xmlFree(ptr)
        }
    }

    /// Returns the value of the string, with unescaped HTML entities.
    var stringValue: String {
        return String(cString: storage.ptr).removingHTMLEntities
    }

}

/// Compares an HTML string with an UTF-8 Swift string.
func == (lhs: HTMLStringBuffer, rhs: String) -> Bool {
    return xmlStrEqual(lhs.storage.ptr, rhs) == 1
}
