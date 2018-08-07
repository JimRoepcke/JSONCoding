//
//  JSONUnarchiver.swift
//  JSONCoding
//
//  Created by Jim Roepcke on 2017-01-02.
//  Copyright © 2016- Jim Roepcke.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to
//  deal in the Software without restriction, including without limitation the
//  rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
//  IN THE SOFTWARE.
//

public protocol JSONUnarchiving {
    func unarchived<T>(with json: Any) throws -> T where T: JSONCoding
    func unarchived<T>(map jsons: [Any]) throws -> [T] where T: JSONCoding
    func unarchived<T>(discardingErrorsMap jsons: [Any]) throws -> [T] where T: JSONCoding
    func map<T, U>(jsons: [T], transform: (T) throws -> U) throws -> [U]
    func discardingErrorsMap<T, U>(jsons: [T], transform: (T) throws -> U) throws -> [U]
    func flatMap<T, U>(jsons: [T], transform: (T) throws -> [U]) throws -> [U]
    func discardingErrorsFlatMap<T, U>(jsons: [T], transform: (T) throws -> [U]) throws -> [U]
    func compactMap<T, U>(jsons: [T], transform: (T) throws -> U?) rethrows -> [U]
    func discardingErrorsCompactMap<T, U>(jsons: [T], transform: (T) throws -> U?) rethrows -> [U]
    var keyStack: [JSONKey] { get }
    func push(key: JSONKey)
    @discardableResult
    func popKey() -> JSONKey?
    var errorHandler: JSONUnarchiveErrorHandler { get }
}

extension JSONKey {

    public func pushed<R>(on unarchiver: JSONUnarchiving, do work: () throws -> (R) ) rethrows -> R {
        unarchiver.push(key: self)
        defer { unarchiver.popKey() }
        return try work()
    }

}

/// Closure that accepts the JSONUnarchiver, the JSONCoding type that failed to
/// be unarchived, the JSON that was passed into the `_unarchived` method, and
/// the error thrown.
public typealias JSONUnarchiveErrorHandler = (JSONUnarchiving, Any.Type, Any, Error) -> Void

open class JSONUnarchiver: JSONUnarchiving {

    public let rootJSON: Any
    public let errorHandler: JSONUnarchiveErrorHandler
    public var keyStack: [JSONKey]

    public init(rootJSON: Any, errorHandler: @escaping JSONUnarchiveErrorHandler) {
        self.rootJSON = rootJSON
        self.errorHandler = errorHandler
        self.keyStack = []
    }

    open func push(key: JSONKey) {
        keyStack.append(key)
    }

    @discardableResult
    open func popKey() -> JSONKey? {
        return keyStack.popLast()
    }

    open func unarchived<T>(with json: Any) throws -> T where T: JSONCoding {
        do {
            return try T._unarchived(with: json, unarchiver: self)
        } catch {
            errorHandler(self, T.self, json, error)
            throw error
        }
    }

    open func unarchived<T>(map jsons: [Any]) throws -> [T] where T: JSONCoding {
        return try jsons.enumerated().map { offset, json in
            try JSONArrayOffsetKey(offset: offset).pushed(on: self) {
                try unarchived(with: json)
            }
        }
    }

    open func unarchived<T>(discardingErrorsMap jsons: [Any]) -> [T] where T: JSONCoding {
        return jsons.enumerated().flatMap { offset, json in
            JSONArrayOffsetKey(offset: offset).pushed(on: self) {
                try? unarchived(with: json)
            }
        }
    }

    public func map<T, U>(jsons: [T], transform: (T) throws -> U) throws -> [U] {
        return try jsons.enumerated().map { offset, json in
            try JSONArrayOffsetKey(offset: offset).pushed(on: self) {
                try transform(json)
            }
        }
    }

    public func discardingErrorsMap<T, U>(jsons: [T], transform: (T) throws -> U) -> [U] {
        return jsons.enumerated().flatMap { offset, json in
            JSONArrayOffsetKey(offset: offset).pushed(on: self) {
                try? transform(json)
            }
        }
    }

    public func flatMap<T, U>(jsons: [T], transform: (T) throws -> [U]) throws -> [U] {
        return try jsons.enumerated().flatMap { offset, json in
            try JSONArrayOffsetKey(offset: offset).pushed(on: self) {
                try transform(json)
            }
        }
    }

    public func compactMap<T, U>(jsons: [T], transform: (T) throws -> U?) rethrows -> [U] {
        return try jsons.enumerated().flatMap { offset, json in
            try JSONArrayOffsetKey(offset: offset).pushed(on: self) {
                try transform(json)
            }
        }
    }

    public func discardingErrorsFlatMap<T, U>(jsons: [T], transform: (T) throws -> [U]) -> [U] {
        return jsons.enumerated().flatMap { offset, json -> [U] in
            JSONArrayOffsetKey(offset: offset).pushed(on: self) {
                do {
                    return try transform(json)
                } catch {
                    return []
                }
            }
        }
    }

    public func discardingErrorsCompactMap<T, U>(jsons: [T], transform: (T) throws -> U?) -> [U] {
        return jsons.enumerated().flatMap { offset, json -> U? in
            JSONArrayOffsetKey(offset: offset).pushed(on: self) {
                do {
                    return try transform(json)
                } catch {
                    return nil
                }
            }
        }
    }

    open class func topLevelUnarchived<T>(with rootJSON: Any, errorHandler: @escaping JSONUnarchiveErrorHandler) throws -> T where T: JSONCoding {
        let unarchiver = JSONUnarchiver(rootJSON: rootJSON, errorHandler: errorHandler)
        return try unarchiver.unarchived(with: rootJSON)
    }

    open class func topLevelUnarchived<T>(mappedIn jsons: [Any], errorHandler: @escaping JSONUnarchiveErrorHandler) throws -> [T] where T: JSONCoding {
        let unarchiver = JSONUnarchiver(rootJSON: jsons, errorHandler: errorHandler)
        return try unarchiver.unarchived(map: jsons)
    }

    open class func topLevelUnarchived<T>(discardingErrorsMappedIn jsons: [Any], errorHandler: @escaping JSONUnarchiveErrorHandler) -> [T] where T: JSONCoding {
        let unarchiver = JSONUnarchiver(rootJSON: jsons, errorHandler: errorHandler)
        return unarchiver.unarchived(discardingErrorsMap: jsons)
    }

}
