//
//  collection+download.swift
//  ion-client
//
//  Created by Johannes Schriewer on 27/11/15.
//  Copyright © 2015 anfema GmbH. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted under the conditions of the 3-clause
// BSD license (see LICENSE.txt for full license text)

import Foundation
import Tarpit
import DEjson
import iso_rfc822_date


extension IONCollection {
    fileprivate var lastUpdatedIdentifier: String {
        return "ION.collection.lastUpdated"
    }

    /// Last download of the complete collection
    public var lastCompleteUpdate: Date? {
        get {
            let prefs = UserDefaults.standard

            guard let dict = prefs.object(forKey: self.lastUpdatedIdentifier) as? [String: Date] else {
                return nil
            }

            return dict[self.identifier]
        }

        set (newValue) {
            let prefs = UserDefaults.standard
            var dict: [String: Date] = (prefs.object(forKey: self.lastUpdatedIdentifier) as? [String: Date]) ?? [:]

            dict[self.identifier] = newValue

            prefs.set(dict, forKey: self.lastUpdatedIdentifier)
            prefs.synchronize()
        }
    }

    /// Download an archive of a complete collection
    ///
    /// - parameter callback: Callback to call when the download finished or errored (parameter is success state)
    /// - returns: Collection for chaining
    @discardableResult public func download(_ callback: @escaping ((Bool) -> Void)) -> IONCollection {
        self.workQueue.async {
            guard let archiveURL = self.archiveURL else {
                responseQueueCallback(callback, parameter: false)
                return
            }

            var q = [String: String]()
            var url: String = archiveURL

            // Workaround for bug in Alamofire which does not append queryparameters to an URL that already has some
            if let dt = self.lastCompleteUpdate {
                if archiveURL.contains("?") {
                    url += "&lastUpdated=\((dt as NSDate).isoDateString())"
                } else {
                    q["lastUpdated"] = (dt as NSDate).isoDateString()
                }
            }

            IONRequest.fetchBinary(fromURL: url, queryParameters: q, cacheBehaviour: ION.config.cacheBehaviour(.ignore), checksumMethod: "null", checksum: "") { result in
                guard case .success(let filename) = result else {
                    responseQueueCallback(callback, parameter: false)
                    return
                }

                if filename.isEmpty {
                    responseQueueCallback(callback, parameter: true)
                    return
                }

                self.workQueue.async {
                    let result = self.unpackToCache(filename: filename)
                    ION.config.responseQueue.async {
                        if result == true {
                            self.lastCompleteUpdate = Date()
                            ION.resetMemCache()

                            for (_, collection) in ION.collectionCache where collection.identifier == self.identifier {
                                ION.config.lastOnlineUpdate[collection.identifier] = self.lastCompleteUpdate
                            }
                        }
                        callback(result)
                    }
                }
            }
        }

        return self
    }


    fileprivate func unpackToCache(filename: String) -> Bool {
        var index = [JSONObject]()

        defer {
            IONRequest.saveCacheDB()
        }

        do {
            let tar = try TarFile(fileName: filename)

            while let file = try tar.extractFile() {
                if file.filename == "index.json" {
                    guard let jsonString = NSString(data: file.data, encoding: String.Encoding.utf8.rawValue) else {
                        return false
                    }

                    let indexDB = JSONDecoder(jsonString as String).jsonObject

                    guard case .jsonArray(let i) = indexDB else {
                        return false
                    }

                    index = i
                } else {
                    var found: Int? = nil

                    for (idx, item) in index.enumerated() {
                        guard case .jsonDictionary(let dict) = item else {
                            return false
                        }

                        guard let rawName = dict["name"], let rawURL = dict["url"],
                              case .jsonString(let filename) = rawName,
                              case .jsonString(let url) = rawURL else {
                                return false
                        }

                        var checksum: String? = nil

                        if let dictChecksum = dict["checksum"] {
                            if case .jsonString(let ck) = dictChecksum {
                                checksum = ck
                            }
                        }

                        if filename == file.filename {
                            IONRequest.saveJSONToCache(using: file.data, url: url, checksum: checksum, lastUpdated: file.mtime)
                            found = idx
                            break
                        }
                    }

                    if let found = found {
                        index.remove(at: found)
                    }
                }
            }
        } catch TarFile.Errors.endOfFile {
            // ok
            return true
        } catch {
            return false
        }

        return true
    }
}
