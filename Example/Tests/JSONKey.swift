//
//  JSONKey.swift
//  JSONCoding
//
//  Created by Jim Roepcke on 2017-09-28.
//  Copyright © 2017- Jim Roepcke.
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
import Quick
import Nimble
import JSONCoding

class JSONKeySpec: QuickSpec {
    override func spec() {
        describe("JSONKey") {

            context("has many nested dictionaries to parse") {

                var json: JSON?
                var unarchiver: JSONUnarchiving?

                beforeEach {
                    let aJSON: JSON = ["a": ["b": ["c": ["result": "test"]]]]
                    json = aJSON
                    unarchiver = JSONUnarchiver(rootJSON: aJSON, errorHandler: { _, _, _, error in fail("\(error)") })
                }

                afterEach {
                    unarchiver = nil
                    json = nil
                }

                it("can get a value out of a deeply nested dictionary") {
                    guard let json = json, let unarchiver = unarchiver else { return fail() }
                    do {
                        let result: String? = try Key.keys(.a, .b, .c).optionalJSONValue(in: json, unarchiver) {
                            try Key.result.optionalValue(in: $0)
                        }
                        expect(result) == "test"
                    } catch {
                        fail("\(error)")
                    }
                }

            }
        }
    }
}

private enum Key: String, JSONKey {
    case a
    case b
    case c
    case result
}
