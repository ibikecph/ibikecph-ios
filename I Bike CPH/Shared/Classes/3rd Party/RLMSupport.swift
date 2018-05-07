////////////////////////////////////////////////////////////////////////////
//
// Copyright 2014 Realm Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
////////////////////////////////////////////////////////////////////////////

//import Realm

extension RLMObject {
    // Swift query convenience functions
    public class func objectsWhere(_ predicateFormat: String, _ args: CVarArg...) -> RLMResults<RLMObject> {
        return objects(with: NSPredicate(format: predicateFormat, arguments: getVaList(args)))
    }

    public class func objectsInRealm(_ realm: RLMRealm, _ predicateFormat: String, _ args: CVarArg...) -> RLMResults<RLMObject> {
        return objects(in: realm, with:NSPredicate(format: predicateFormat, arguments: getVaList(args)))
    }
}

extension RLMArray: Sequence {
    // Support Sequence-style enumeration
    public func makeIterator() -> AnyIterator<RLMObject> {
        var i: UInt  = 0

        return AnyIterator<RLMObject> {
            if (i >= self.count) {
                return .none
            } else {
                let returnObject = self[i] as RLMObject
                i += 1
                return returnObject
            }
        }
    }

    // Swift query convenience functions
    public func indexOfObjectWhere(_ predicateFormat: String, _ args: CVarArg...) -> UInt {
        return indexOfObject(with: NSPredicate(format: predicateFormat, arguments: getVaList(args)))
    }

    public func objectsWhere(_ predicateFormat: String, _ args: CVarArg...) -> RLMResults<RLMObject> {
        return objects(with: NSPredicate(format: predicateFormat, arguments: getVaList(args))) as! RLMResults<RLMObject>
    }
}

extension RLMResults: Sequence {
    // Support Sequence-style enumeration
    public func makeIterator() -> AnyIterator<RLMObject> {
        var i: UInt  = 0

        return AnyIterator<RLMObject> {
            if (i >= self.count) {
                return .none
            } else {
                let returnObject = self[i] as? RLMObject
                i += 1
                return returnObject
            }
        }
    }

    // Swift query convenience functions
    public func indexOfObjectWhere(_ predicateFormat: String, _ args: CVarArg...) -> UInt {
        return indexOfObject(with: NSPredicate(format: predicateFormat, arguments: getVaList(args)))
    }

    public func objectsWhere(_ predicateFormat: String, _ args: CVarArg...) -> RLMResults {
        return objects(with: NSPredicate(format: predicateFormat, arguments: getVaList(args)))
    }
}
