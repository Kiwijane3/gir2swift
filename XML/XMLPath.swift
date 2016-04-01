//
//  XMLPath.swift
//  Gtk3Swift
//
//  Created by Rene Hexel on 25/03/2016.
//  Copyright © 2016 Rene Hexel. All rights reserved.
//
#if os(Linux)
    import Glibc
#else
    import Darwin
#endif

import libxml2

///
/// A wrapper around libxml2 xmlXPathTypePtr
///
public struct XMLPath {
    let xpath: xmlXPathObjectPtr
}

///
/// Extension to make XMLPath behave like an array
///
extension XMLPath: CollectionType {
    public typealias Index = Int
    public typealias Generator = AnyGenerator<XMLElement>

    var nodeSet: xmlNodeSetPtr { return xpath.memory.nodesetval }
    public var count: Int { return nodeSet != nil ? Int(nodeSet.memory.nodeNr) : 0 }
    public var startIndex: Index { return 0 }
    public var endIndex: Index { return count }
    public var first: XMLElement? {
        guard count > 0 else { return nil }
        return self[startIndex]
    }
    public var last: XMLElement? {
        guard count > 0 else { return nil }
        return self[endIndex]
    }

    public subscript(i: Index) -> XMLElement {
        precondition(i >= startIndex)
        precondition(i < endIndex)
        return XMLElement(node: nodeSet.memory.nodeTab[i])
    }

    public func generate() -> Generator {
        var i = 0
        return AnyGenerator {
            let j = i
            guard j < self.count else { return nil }
            i += 1
            return self[j]
        }
    }
}

extension XMLDocument {
    /// compile a given XPath for queries
    func xpath(p: String, namespaces ns: AnySequence<XMLNameSpace> = emptySequence(), defaultPrefix: String = "ns") -> XMLPath? {
        let context = xmlXPathNewContext(xml)
        guard context != nil else { return nil }
        defer { xmlXPathFreeContext(context) }
        ns.forEach { xmlXPathRegisterNs(context, $0.prefix ?? defaultPrefix, $0.href ?? "") }
        return xpath(p, context: context)
    }

    /// compile a given XPath for queries
    func xpath(p: String, namespaces ns: [(prefix: String, href: String)]) -> XMLPath? {
        let context = xmlXPathNewContext(xml)
        guard context != nil else { return nil }
        defer { xmlXPathFreeContext(context) }
        ns.forEach { xmlXPathRegisterNs(context, $0.prefix, $0.href) }
        return xpath(p, context: context)
    }

    /// compile an xpath for queries with a given context
    func xpath(p: String, context: xmlXPathContextPtr) -> XMLPath? {
        let xmlXPath = xmlXPathEvalExpression(p, context)
        guard xmlXPath != nil else { return nil }
        return XMLPath(xpath: xmlXPath)
    }
}

