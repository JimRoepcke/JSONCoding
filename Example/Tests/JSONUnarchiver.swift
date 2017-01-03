//
//  JSONUnarchiverSpec.swift
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
import Quick
import Nimble
import JSONCoding

class JSONUnarchiverSpec: QuickSpec {
    override func spec() {
        describe("JSONUnarchiver") {

            context("unarchiving top level JSONCoding values") {

                it("can unarchive a VerySimpleTestThing") {
                    let number = 42
                    let json: JSON = ["number": number]
                    do {
                        let thing: VerySimpleTestThing = try JSONUnarchiver.topLevelUnarchived(with: json) { _ in }
                        expect(thing.number) == number
                    } catch {
                        fail("\(error)")
                    }
                }

            }
        }
    }
}

private struct VerySimpleTestThing: JSONCoding {

    let number: Int

    enum Key: String, JSONKey {
        case number
    }

    static func _unarchived(with json: Any, unarchiver: JSONUnarchiving) throws -> VerySimpleTestThing {
        return VerySimpleTestThing(number: try Key.number.value(in: json))
    }

}
