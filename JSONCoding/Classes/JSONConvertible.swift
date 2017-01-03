//
//  JSONConvertible.swift
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

public protocol JSONConvertible {
    static func byConverting(jsonValue: Any, from key: JSONKey) throws -> Self
}

extension String: JSONConvertible {
    public static func byConverting(jsonValue: Any, from key: JSONKey) throws -> String {
        switch jsonValue {
        case let stringValue as String:
            return stringValue
        case let stringValue as NSString:
            return stringValue.description
        default:
            throw JSONError.typeMismatch(key: key, expected: self, received: jsonValue)
        }
    }
}

extension Int: JSONConvertible {
    public static func byConverting(jsonValue: Any, from key: JSONKey) throws -> Int {
        switch jsonValue {
        case let intValue as Int:
            return intValue
        case let n as NSNumber:
            return n.intValue
        default:
            throw JSONError.typeMismatch(key: key, expected: self, received: jsonValue)
        }
    }
}

extension Int64: JSONConvertible {
    public static func byConverting(jsonValue: Any, from key: JSONKey) throws -> Int64 {
        switch jsonValue {
        case let intValue as Int64:
            return intValue
        case let n as NSNumber:
            return n.int64Value
        default:
            throw JSONError.typeMismatch(key: key, expected: self, received: jsonValue)
        }
    }
}

extension UInt: JSONConvertible {
    public static func byConverting(jsonValue: Any, from key: JSONKey) throws -> UInt {
        switch jsonValue {
        case let intValue as UInt:
            return intValue
        case let n as NSNumber:
            return n.uintValue
        default:
            throw JSONError.typeMismatch(key: key, expected: self, received: jsonValue)
        }
    }
}

extension Bool: JSONConvertible {
    public static func byConverting(jsonValue: Any, from key: JSONKey) throws -> Bool {
        switch jsonValue {
        case let boolValue as Bool:
            return boolValue
        case let n as NSNumber:
            return n.boolValue
        default:
            throw JSONError.typeMismatch(key: key, expected: self, received: jsonValue)
        }
    }
}

extension Double: JSONConvertible {
    public static func byConverting(jsonValue: Any, from key: JSONKey) throws -> Double {
        switch jsonValue {
        case let doubleValue as Double:
            return doubleValue
        case let n as NSNumber:
            return n.doubleValue
        default:
            throw JSONError.typeMismatch(key: key, expected: self, received: jsonValue)
        }
    }
}

extension URL: JSONConvertible {
    public static func byConverting(jsonValue: Any, from key: JSONKey) throws -> URL {
        switch jsonValue {
        case let stringValue as String:
            guard let url = URL(string: stringValue) else {
                throw JSONError.invalidJSONValue(key: key, received: jsonValue)
            }
            return url
        default:
            throw JSONError.typeMismatch(key: key, expected: String.self, received: jsonValue)
        }
    }
}

extension Array: JSONConvertible {
    public static func byConverting(jsonValue: Any, from key: JSONKey) throws -> Array {
        switch jsonValue {
        case let array as Array<Element>:
            return array
        case let array as NSArray:
            return try array.map { (e: Any) -> Element in
                guard let element = e as? Element else {
                    throw JSONError.invalidJSONValue(key: key, received: e)
                }
                return element
            }
        default:
            throw JSONError.typeMismatch(key: key, expected: self, received: jsonValue)
        }
    }
}
