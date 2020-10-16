//
//  FileRepository.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 11/21/19.
//  Copyright © 2019 Apptentive, Inc. All rights reserved.
//

import Foundation

class FileRepository<T> {
    let containerURL: URL
    let fileManager: FileManager
    let filename: String

    var fileExists: Bool {
        self.fileManager.fileExists(atPath: self.url.path)
    }

    init(containerURL: URL, filename: String, fileManager: FileManager) {
        self.containerURL = containerURL
        self.filename = filename
        self.fileManager = fileManager
    }

    func load() throws -> T {
        let data = try self.loadData()
        return try self.decode(data: data)
    }

    func save(_ object: T) throws {
        let data = try self.encode(object: object)
        try self.save(data: data)
    }

    fileprivate var url: URL {
        containerURL.appendingPathComponent(self.filename).appendingPathExtension(self.fileExtension)
    }

    var fileExtension: String {
        ""
    }

    fileprivate func loadData() throws -> Data {
        return try Data(contentsOf: self.url)
    }

    fileprivate func save(data: Data) throws {
        try data.write(to: self.url)
    }

    fileprivate func decode(data: Data) throws -> T {
        throw ApptentiveError.internalInconsistency
    }

    fileprivate func encode(object: T) throws -> Data {
        throw ApptentiveError.internalInconsistency
    }

}

class PropertyListRepository<T: Codable>: FileRepository<T> {
    let decoder = PropertyListDecoder()
    let encoder = PropertyListEncoder()

    override func decode(data: Data) throws -> T {
        return try self.decoder.decode(T.self, from: data)
    }

    override func encode(object: T) throws -> Data {
        return try self.encoder.encode(object)
    }

    override var fileExtension: String {
        return "plist"
    }
}
