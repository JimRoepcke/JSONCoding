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

import Foundation

public protocol JSONKey {
    var keyValue: String { get }
}

public extension JSONKey where Self: RawRepresentable, Self.RawValue == String {
    var keyValue: String {
        return rawValue
    }
}

public struct JSONRandomKey: JSONKey {
    public let keyValue: String
    public init(keyValue: String) {
        self.keyValue = keyValue
    }
}

public struct JSONCompoundKey: JSONKey {
    public let keys: [JSONKey]

    public init(keys: [JSONKey]) {
        self.keys = keys
    }

    public var keyValue: String {
        return keys.map({$0.keyValue}).joined(separator: "")
    }
}

public struct JSONArrayOffsetKey: JSONKey {
    public let offset: Int

    public init(offset: Int) {
        self.offset = offset
    }

    public var keyValue: String {
        return "[\(offset)]"
    }
}

public extension JSONKey {

    // It's not possible to conform `JSON` to `JSONConvertible`, so
    // its hypothetical `byConverting` code is inlined instead.
    static func JSON_byConverting(jsonValue: Any, from key: JSONKey) throws -> NSDictionary {
        switch jsonValue {
        case let jsonValue as NSDictionary:
            return jsonValue
        default:
            throw JSONError.typeMismatch(key: key, expected: NSDictionary.self, received: jsonValue)
        }
    }

}

public extension Array where Element: JSONKey {
    func optionalJSONValue<U>(in json: Any, _ unarchiver: JSONUnarchiving, optionalTransform: (NSDictionary) throws -> U?) throws -> U? {
        var current: NSDictionary? = nil
        var keysPushed = [JSONKey]()
        defer { keysPushed.forEach { _ in unarchiver.popKey() } }
        for key in self {
            if let inside = try key.optionalJSONValue(in: current ?? json) {
                unarchiver.push(key: key)
                keysPushed.append(key)
                current = inside
            } else {
                return nil
            }
        }
        return try current.flatMap(optionalTransform)
    }
}

public extension JSONKey {

    static func keys(_ args: Self...) -> [Self] {
        return args
    }

    func optionalJSONValue(in json: Any) throws -> NSDictionary? {
        let value = try optionalAnyValue(in: json)
        return try value.flatMap { try Self.JSON_byConverting(jsonValue: $0, from: self) }
    }

    func optionalJSONValue<U>(in json: Any, _ unarchiver: JSONUnarchiving, transform: (NSDictionary) throws -> U) throws -> U? {
        return try optionalAnyValue(in: json, unarchiver, transform: {
            let aJSON = try Self.JSON_byConverting(jsonValue: $0, from: self)
            return try transform(aJSON)
        })
    }

    func optionalJSONValue<U>(in json: Any, _ unarchiver: JSONUnarchiving, optionalTransform: (NSDictionary) throws -> U?) throws -> U? {
        return try optionalAnyValue(in: json, unarchiver, optionalTransform: {
            let aJSON = try Self.JSON_byConverting(jsonValue: $0, from: self)
            return try optionalTransform(aJSON)
        })
    }

    func jsonValue(in json: Any) throws -> NSDictionary {
        let value = try anyValue(in: json)
        return try Self.JSON_byConverting(jsonValue: value, from: self)
    }

    func jsonValue<U>(in json: Any, _ unarchiver: JSONUnarchiving, transform: (NSDictionary) throws -> U) throws -> U {
        return try anyValue(in: json, unarchiver) {
            let aJSON = try Self.JSON_byConverting(jsonValue: $0, from: self)
            return try transform(aJSON)
        }
    }

    func optionalDateValue(timeIntervalSince1970In json: Any) throws -> Date? {
        let interval: TimeInterval? = try optionalValue(in: json)
        return interval.flatMap { Date(timeIntervalSince1970: $0) }
    }

    func dateValue(timeIntervalSince1970In json: Any) throws -> Date {
        let interval: TimeInterval = try value(in: json)
        return Date(timeIntervalSince1970: interval)
    }

    func optionalKeyValue(in json: Any) throws -> JSONKey? {
        let keyValue: String? = try optionalValue(in: json)
        return keyValue.flatMap { JSONRandomKey(keyValue: $0) }
    }

    func keyValue(in json: Any) throws -> JSONKey {
        let keyValue: String = try value(in: json)
        return JSONRandomKey(keyValue: keyValue)
    }

    func optionalUnarchivedValue<T: JSONCoding>(in json: Any, _ unarchiver: JSONUnarchiving) throws -> T? {
        return try optionalAnyValue(in: json, unarchiver) {
            try unarchiver.unarchived(with: $0)
        }
    }

    func optionalUnarchivedValue<T: JSONCoding>(discardingErrorsIn json: Any, _ unarchiver: JSONUnarchiving) throws -> T? {
        return try optionalAnyValue(in: json, unarchiver) {
            do {
                return try unarchiver.unarchived(with: $0)
            } catch {
                unarchiver.errorHandler(unarchiver, T.self, json, error)
                return nil
            }
        }
    }

    func unarchivedValue<T: JSONCoding>(in json: Any, _ unarchiver: JSONUnarchiving) throws -> T {
        return try anyValue(in: json, unarchiver) {
            try unarchiver.unarchived(with: $0)
        }
    }

    func optionalUnarchivedValues<T: JSONCoding>(mappedIn json: Any, _ unarchiver: JSONUnarchiving) throws -> [T]? {
        return try optionalValue(in: json, unarchiver) { (jsons: [Any]) in
            try unarchiver.unarchived(map: jsons)
        }
    }

    func unarchivedValues<T: JSONCoding>(mappedIn json: Any, _ unarchiver: JSONUnarchiving) throws -> [T] {
        return try value(in: json, unarchiver) { (jsons: [Any]) in
            try unarchiver.unarchived(map: jsons)
        }
    }

    func optionalUnarchivedValues<T: JSONCoding>(discardingErrorsMappedIn json: Any, _ unarchiver: JSONUnarchiving) throws -> [T]? {
        return try optionalValue(in: json, unarchiver) { (jsons: [Any]) in
            unarchiver.unarchived(discardingErrorsMap: jsons)
        }
    }

    func unarchivedValues<T: JSONCoding>(discardingErrorsMappedIn json: Any, _ unarchiver: JSONUnarchiving) throws -> [T] {
        return try value(in: json, unarchiver) { (jsons: [Any]) in
            unarchiver.unarchived(discardingErrorsMap: jsons)
        }
    }

    func optionalAnyValue<U>(in json: Any, _ unarchiver: JSONUnarchiving, transform: (Any) throws -> U) throws -> U? {
        let optionalValue = try optionalAnyValue(in: json)
        return try optionalValue.flatMap { value in
            try pushed(on: unarchiver) {
                try transform(value)
            }
        }
    }

    func optionalAnyValue<U>(in json: Any, _ unarchiver: JSONUnarchiving, optionalTransform: (Any) throws -> U?) throws -> U? {
        let optionalValue = try optionalAnyValue(in: json)
        return try optionalValue.flatMap { value in
            try pushed(on: unarchiver) {
                try optionalTransform(value)
            }
        }
    }

    func optionalValue<T: JSONConvertible>(in json: Any) throws -> T? {
        let value = try optionalAnyValue(in: json)
        return try value.flatMap { try T.byConverting(jsonValue: $0, from: self) }
    }

    func optionalValue<T: JSONConvertible, U>(in json: Any, _ unarchiver: JSONUnarchiving, transform: (T) throws -> U) throws -> U? {
        return try optionalAnyValue(in: json, unarchiver, transform: {
            let aT = try T.byConverting(jsonValue: $0, from: self)
            return try transform(aT)
        })
    }

    func optionalValue<T: JSONConvertible, U>(in json: Any, _ unarchiver: JSONUnarchiving, optionalTransform: (T) throws -> U?) throws -> U? {
        return try optionalAnyValue(in: json, unarchiver, optionalTransform: {
            let aT = try T.byConverting(jsonValue: $0, from: self)
            return try optionalTransform(aT)
        })
    }

    func value<T: JSONConvertible>(in json: Any) throws -> T {
        let value = try anyValue(in: json)
        return try T.byConverting(jsonValue: value, from: self)
    }

    func value<T: JSONConvertible, U>(in json: Any, _ unarchiver: JSONUnarchiving, transform: (T) throws -> U) throws -> U {
        return try anyValue(in: json, unarchiver) {
            let aT = try T.byConverting(jsonValue: $0, from: self)
            return try transform(aT)
        }
    }

    func map<T, U>(in json: Any, _ unarchiver: JSONUnarchiving, transform: (T) throws -> U) throws -> [U] {
        return try value(in: json, unarchiver) {
            try unarchiver.map(jsons: $0, transform: transform)
        }
    }

    func discardingErrorsMap<T, U>(in json: Any, _ unarchiver: JSONUnarchiving, transform: (T) throws -> U) throws -> [U] {
        return try value(in: json, unarchiver) {
            try unarchiver.discardingErrorsMap(jsons: $0, transform: transform)
        }
    }

    func compactMap<T, U>(in json: Any, _ unarchiver: JSONUnarchiving, transform: (T) throws -> U?) throws -> [U] {
        return try value(in: json, unarchiver) {
            try unarchiver.compactMap(jsons: $0, transform: transform)
        }
    }

    func flatMap<T, U>(in json: Any, _ unarchiver: JSONUnarchiving, transform: (T) throws -> [U]) throws -> [U] {
        return try value(in: json, unarchiver) {
            try unarchiver.flatMap(jsons: $0, transform: transform)
        }
    }

    func discardingErrorsCompactMap<T, U>(in json: Any, _ unarchiver: JSONUnarchiving, transform: (T) throws -> U?) throws -> [U] {
        return try value(in: json, unarchiver) {
            try unarchiver.discardingErrorsCompactMap(jsons: $0, transform: transform)
        }
    }

    func discardingErrorsFlatMap<T, U>(in json: Any, _ unarchiver: JSONUnarchiving, transform: (T) throws -> [U]) throws -> [U] {
        return try value(in: json, unarchiver) {
            try unarchiver.discardingErrorsFlatMap(jsons: $0, transform: transform)
        }
    }

    func optionalMap<T, U>(in json: Any, _ unarchiver: JSONUnarchiving, transform: (T) throws -> U) throws -> [U]? {
        return try optionalValue(in: json, unarchiver) {
            try unarchiver.map(jsons: $0, transform: transform)
        }
    }

    func optionalDiscardingErrorsMap<T, U>(in json: Any, _ unarchiver: JSONUnarchiving, transform: (T) throws -> U) throws -> [U]? {
        return try optionalValue(in: json, unarchiver) {
            try unarchiver.discardingErrorsMap(jsons: $0, transform: transform)
        }
    }

    func optionalCompactMap<T, U>(in json: Any, _ unarchiver: JSONUnarchiving, transform: (T) throws -> U?) throws -> [U]? {
        return try optionalValue(in: json, unarchiver) {
            try unarchiver.compactMap(jsons: $0, transform: transform)
        }
    }

    func optionalFlatMap<T, U>(in json: Any, _ unarchiver: JSONUnarchiving, transform: (T) throws -> [U]) throws -> [U]? {
        return try optionalValue(in: json, unarchiver) {
            try unarchiver.flatMap(jsons: $0, transform: transform)
        }
    }

    func optionalDiscardingErrorsCompactMap<T, U>(in json: Any, _ unarchiver: JSONUnarchiving, transform: (T) throws -> U?) throws -> [U]? {
        return try optionalValue(in: json, unarchiver) {
            try unarchiver.discardingErrorsCompactMap(jsons: $0, transform: transform)
        }
    }

    func optionalDiscardingErrorsFlatMap<T, U>(in json: Any, _ unarchiver: JSONUnarchiving, transform: (T) throws -> [U]) throws -> [U]? {
        return try optionalValue(in: json, unarchiver) {
            try unarchiver.discardingErrorsFlatMap(jsons: $0, transform: transform)
        }
    }

    func optionalAnyValue(in json: Any) throws -> Any? {
        switch json {
        case let j as NSDictionary:
            switch j[keyValue] {
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

    func anyValue(in json: Any) throws -> Any {
        switch json {
        case let j as NSDictionary:
            switch j[keyValue] {
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

    func anyValue<U>(in json: Any, _ unarchiver: JSONUnarchiving, transform: (Any) throws -> U) throws -> U {
        let value = try anyValue(in: json)
        return try pushed(on: unarchiver) {
            try transform(value)
        }
    }
}
