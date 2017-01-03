//
//  JSONKey.swift
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

public protocol JSONKey {
    var rawValue: String { get }
}

public struct JSONRandomKey: JSONKey {
    public let rawValue: String
    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}

public struct JSONCompoundKey: JSONKey {
    public let keys: [JSONKey]

    public init(keys: [JSONKey]) {
        self.keys = keys
    }

    public var rawValue: String {
        return keys.map({$0.rawValue}).joined(separator: "")
    }
}

public struct JSONArrayOffsetKey: JSONKey {
    public let offset: Int

    public init(offset: Int) {
        self.offset = offset
    }

    public var rawValue: String {
        return "[\(offset)]"
    }
}

public extension JSONKey {

    // It's not possible to conform `JSON` to `JSONConvertible`, so
    // its hypothetical `byConverting` code is inlined instead.
    static func JSON_byConverting(jsonValue: Any, from key: JSONKey) throws -> JSON {
        switch jsonValue {
        case let jsonValue as JSON:
            return jsonValue
        default:
            throw JSONError.typeMismatch(key: key, expected: JSON.self, received: jsonValue)
        }
    }

}

public extension JSONKey {

    public func optionalJSONValue(in json: Any) throws -> JSON? {
        let value = try optionalAnyValue(in: json)
        return try value.flatMap { try Self.JSON_byConverting(jsonValue: $0, from: self) }
    }

    public func optionalJSONValue<U>(in json: Any, _ unarchiver: JSONUnarchiving, transform: (JSON) throws -> U) throws -> U? {
        return try optionalAnyValue(in: json, unarchiver, transform: {
            let aJSON = try Self.JSON_byConverting(jsonValue: $0, from: self)
            return try transform(aJSON)
        })
    }

    public func optionalJSONValue<U>(in json: Any, _ unarchiver: JSONUnarchiving, optionalTransform: (JSON) throws -> U?) throws -> U? {
        return try optionalAnyValue(in: json, unarchiver, optionalTransform: {
            let aJSON = try Self.JSON_byConverting(jsonValue: $0, from: self)
            return try optionalTransform(aJSON)
        })
    }

    public func jsonValue(in json: Any) throws -> JSON {
        let value = try anyValue(in: json)
        return try Self.JSON_byConverting(jsonValue: value, from: self)
    }

    public func jsonValue<U>(in json: Any, _ unarchiver: JSONUnarchiving, transform: (JSON) throws -> U) throws -> U {
        return try anyValue(in: json, unarchiver) {
            let aJSON = try Self.JSON_byConverting(jsonValue: $0, from: self)
            return try transform(aJSON)
        }
    }

    public func optionalDateValue(timeIntervalSince1970In json: Any) throws -> Date? {
        let interval: TimeInterval? = try optionalValue(in: json)
        return interval.flatMap { Date(timeIntervalSince1970: $0) }
    }

    public func dateValue(timeIntervalSince1970In json: Any) throws -> Date {
        let interval: TimeInterval = try value(in: json)
        return Date(timeIntervalSince1970: interval)
    }

    public func optionalKeyValue(in json: Any) throws -> JSONKey? {
        let rawValue: String? = try optionalValue(in: json)
        return rawValue.flatMap { JSONRandomKey(rawValue: $0) }
    }

    public func keyValue(in json: Any) throws -> JSONKey {
        let rawValue: String = try value(in: json)
        return JSONRandomKey(rawValue: rawValue)
    }

    public func optionalUnarchivedValue<T: JSONCoding>(in json: Any, _ unarchiver: JSONUnarchiving) throws -> T? {
        return try optionalAnyValue(in: json, unarchiver) {
            try unarchiver.unarchived(with: $0)
        }
    }

    public func unarchivedValue<T: JSONCoding>(in json: Any, _ unarchiver: JSONUnarchiving) throws -> T {
        return try anyValue(in: json, unarchiver) {
            try unarchiver.unarchived(with: $0)
        }
    }

    public func optionalUnarchivedValues<T: JSONCoding>(mappedIn json: Any, _ unarchiver: JSONUnarchiving) throws -> [T]? {
        return try optionalValue(in: json, unarchiver) { (jsons: [Any]) in
            try unarchiver.unarchived(map: jsons)
        }
    }

    public func unarchivedValues<T: JSONCoding>(mappedIn json: Any, _ unarchiver: JSONUnarchiving) throws -> [T] {
        return try value(in: json, unarchiver) { (jsons: [Any]) in
            try unarchiver.unarchived(map: jsons)
        }
    }

    public func optionalUnarchivedValues<T: JSONCoding>(discardingErrorsMappedIn json: Any, _ unarchiver: JSONUnarchiving) throws -> [T]? {
        return try optionalValue(in: json, unarchiver) { (jsons: [Any]) in
            try unarchiver.unarchived(discardingErrorsMap: jsons)
        }
    }

    public func unarchivedValues<T: JSONCoding>(discardingErrorsMappedIn json: Any, _ unarchiver: JSONUnarchiving) throws -> [T] {
        return try value(in: json, unarchiver) { (jsons: [Any]) in
            try unarchiver.unarchived(discardingErrorsMap: jsons)
        }
    }

    public func optionalAnyValue<U>(in json: Any, _ unarchiver: JSONUnarchiving, transform: (Any) throws -> U) throws -> U? {
        let optionalValue = try optionalAnyValue(in: json)
        return try optionalValue.flatMap { value in
            try pushed(on: unarchiver) {
                try transform(value)
            }
        }
    }

    public func optionalAnyValue<U>(in json: Any, _ unarchiver: JSONUnarchiving, optionalTransform: (Any) throws -> U?) throws -> U? {
        let optionalValue = try optionalAnyValue(in: json)
        return try optionalValue.flatMap { value in
            try pushed(on: unarchiver) {
                try optionalTransform(value)
            }
        }
    }

    public func optionalValue<T: JSONConvertible>(in json: Any) throws -> T? {
        let value = try optionalAnyValue(in: json)
        return try value.flatMap { try T.byConverting(jsonValue: $0, from: self) }
    }

    public func optionalValue<T: JSONConvertible, U>(in json: Any, _ unarchiver: JSONUnarchiving, transform: (T) throws -> U) throws -> U? {
        return try optionalAnyValue(in: json, unarchiver, transform: {
            let aT = try T.byConverting(jsonValue: $0, from: self)
            return try transform(aT)
        })
    }

    public func optionalValue<T: JSONConvertible, U>(in json: Any, _ unarchiver: JSONUnarchiving, optionalTransform: (T) throws -> U?) throws -> U? {
        return try optionalAnyValue(in: json, unarchiver, optionalTransform: {
            let aT = try T.byConverting(jsonValue: $0, from: self)
            return try optionalTransform(aT)
        })
    }

    public func value<T: JSONConvertible>(in json: Any) throws -> T {
        let value = try anyValue(in: json)
        return try T.byConverting(jsonValue: value, from: self)
    }

    public func value<T: JSONConvertible, U>(in json: Any, _ unarchiver: JSONUnarchiving, transform: (T) throws -> U) throws -> U {
        return try anyValue(in: json, unarchiver) {
            let aT = try T.byConverting(jsonValue: $0, from: self)
            return try transform(aT)
        }
    }

    public func map<T, U>(in json: Any, _ unarchiver: JSONUnarchiving, transform: (T) throws -> U) throws -> [U] {
        return try value(in: json, unarchiver) {
            try unarchiver.map(jsons: $0, transform: transform)
        }
    }

    public func discardingErrorsMap<T, U>(in json: Any, _ unarchiver: JSONUnarchiving, transform: (T) throws -> U) throws -> [U] {
        return try value(in: json, unarchiver) {
            try unarchiver.discardingErrorsMap(jsons: $0, transform: transform)
        }
    }

    public func flatMap<T, U>(in json: Any, _ unarchiver: JSONUnarchiving, transform: (T) throws -> U?) throws -> [U] {
        return try value(in: json, unarchiver) {
            try unarchiver.flatMap(jsons: $0, transform: transform)
        }
    }

    public func flatMap<T, U>(in json: Any, _ unarchiver: JSONUnarchiving, transform: (T) throws -> [U]) throws -> [U] {
        return try value(in: json, unarchiver) {
            try unarchiver.flatMap(jsons: $0, transform: transform)
        }
    }

    public func discardingErrorsFlatMap<T, U>(in json: Any, _ unarchiver: JSONUnarchiving, transform: (T) throws -> U?) throws -> [U] {
        return try value(in: json, unarchiver) {
            try unarchiver.discardingErrorsFlatMap(jsons: $0, transform: transform)
        }
    }

    public func discardingErrorsFlatMap<T, U>(in json: Any, _ unarchiver: JSONUnarchiving, transform: (T) throws -> [U]) throws -> [U] {
        return try value(in: json, unarchiver) {
            try unarchiver.discardingErrorsFlatMap(jsons: $0, transform: transform)
        }
    }

    public func optionalMap<T, U>(in json: Any, _ unarchiver: JSONUnarchiving, transform: (T) throws -> U) throws -> [U]? {
        return try optionalValue(in: json, unarchiver) {
            try unarchiver.map(jsons: $0, transform: transform)
        }
    }

    public func optionalDiscardingErrorsMap<T, U>(in json: Any, _ unarchiver: JSONUnarchiving, transform: (T) throws -> U) throws -> [U]? {
        return try optionalValue(in: json, unarchiver) {
            try unarchiver.discardingErrorsMap(jsons: $0, transform: transform)
        }
    }

    public func optionalFlatMap<T, U>(in json: Any, _ unarchiver: JSONUnarchiving, transform: (T) throws -> U?) throws -> [U]? {
        return try optionalValue(in: json, unarchiver) {
            try unarchiver.flatMap(jsons: $0, transform: transform)
        }
    }

    public func optionalFlatMap<T, U>(in json: Any, _ unarchiver: JSONUnarchiving, transform: (T) throws -> [U]) throws -> [U]? {
        return try optionalValue(in: json, unarchiver) {
            try unarchiver.flatMap(jsons: $0, transform: transform)
        }
    }

    public func optionalDiscardingErrorsFlatMap<T, U>(in json: Any, _ unarchiver: JSONUnarchiving, transform: (T) throws -> U?) throws -> [U]? {
        return try optionalValue(in: json, unarchiver) {
            try unarchiver.discardingErrorsFlatMap(jsons: $0, transform: transform)
        }
    }

    public func optionalDiscardingErrorsFlatMap<T, U>(in json: Any, _ unarchiver: JSONUnarchiving, transform: (T) throws -> [U]) throws -> [U]? {
        return try optionalValue(in: json, unarchiver) {
            try unarchiver.discardingErrorsFlatMap(jsons: $0, transform: transform)
        }
    }

    public func optionalAnyValue(in json: Any) throws -> Any? {
        switch json {
        case let j as JSON:
            switch j[rawValue] {
            case .none:
                return nil
            case let .some(value) where type(of: value) == NSNull.self:
                return nil
            case let .some(value):
                return value
            }
        default:
            throw JSONError.expectedJSON(received: json)
        }
    }

    public func anyValue(in json: Any) throws -> Any {
        switch json {
        case let j as JSON:
            switch j[rawValue] {
            case .none:
                throw JSONError.missing(key: self)
            case let .some(value) where type(of: value) == NSNull.self:
                throw JSONError.null(key: self)
            case let .some(value):
                return value
            }
        default:
            throw JSONError.expectedJSON(received: json)
        }
    }

    public func anyValue<U>(in json: Any, _ unarchiver: JSONUnarchiving, transform: (Any) throws -> U) throws -> U {
        let value = try anyValue(in: json)
        return try pushed(on: unarchiver) {
            try transform(value)
        }
    }

}
