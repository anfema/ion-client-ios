//
//  tarfile.swift
//  tarpit
//
//  Created by Johannes Schriewer on 26/11/15.
//  Copyright © 2015 anfema. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted under the conditions of the 3-clause
// BSD license (see LICENSE.txt for full license text)

import Foundation


open class TarFile {

    public enum Errors: Error {
        /// Invalid header encountered
        case headerParseError
        
        /// End of file marker found
        case endOfFile
        
        /// Programming error (called extractFile on streaming mode or consumeData on file mode)
        case programmingError
    }

    fileprivate struct TarFileHeader {
        var isFile: Bool
        var filepath: String
        var filesize: size_t
        var mtime: Date
    }
    
    fileprivate let streamingMode: Bool
    
    // MARK: - File based unpack
    fileprivate var data: Data! = nil
    fileprivate var offset: size_t = 0

    /// Initialize for unpacking with data
    ///
    /// - parameter data: tar file data
    public init(data: Data) {
        self.streamingMode = false
        self.data = data
    }

    /// Initialize for unpacking with file name
    ///
    /// - parameter fileName: file name to open
    ///
    /// - throws: NSData contentsOfURL errors
    public convenience init(fileName: String) throws {
        self.init(data: try Data(contentsOf: URL(fileURLWithPath: fileName), options: .mappedIfSafe))
    }

    /// Extract file from disk
    ///
    /// - throws: TarFile.Errors
    ///
    /// - returns: tuple with filename and data
    open func extractFile() throws -> (filename: String, mtime: Date, data: Data)? {
        if streamingMode {
            throw Errors.programmingError
        }
        
        var fileData : Data?
        var fileHeader : TarFileHeader?

        try self.data.withUnsafeBytes { rawBufferPointer -> Void in
            let dataPtr = rawBufferPointer.bindMemory(to: CChar.self).baseAddress!

            while true
            {
                guard self.offset + 512 < self.data.count else {
                    throw Errors.endOfFile
                }

                // parse header info
                let header = try self.parse(header: dataPtr.advanced(by: self.offset))

                var data: Data? = nil
                if header.filesize > 0 {
                    // copy over data
                    data = Data(bytes: dataPtr.advanced(by: self.offset + 512), count: header.filesize)
                }

                // advance offset (512 byte blocks)
                var size = 0
                if header.filesize > 0 {
                    if header.filesize % 512 == 0 {
                        size = header.filesize
                    }
                    else {
                        size = (header.filesize + (512 - header.filesize % 512))
                    }
                }

                self.offset += 512 + size

                if let data = data, header.isFile {
                    // return file data
                    fileData = data
                    fileHeader = header
                    break
                }
            }
        }
        
        guard let _fileData = fileData,
            let _fileHeader = fileHeader else
        {
            return nil
        }
        
        return (filename: _fileHeader.filepath, mtime: _fileHeader.mtime, data: _fileData)
    }
    
    // MARK: - Stream based unpack
    fileprivate var buffer = [CChar]()
    
    /// Initialize for unpacking from streaming data
    ///
    /// - parameter streamingData: initial data or nil
    public init(streamingData: [CChar]?) {
        self.streamingMode = true
        if let data = streamingData {
            self.buffer.append(contentsOf: data)
        }
    }

    /// Consume bytes from stream, return unpacked file
    ///
    /// - parameter data: data to consume
    ///
    /// - throws: TarFile.Errors
    ///
    /// - returns: tuple with filename and data on completion of a single file
    open func consume(data: [CChar]) throws -> (filename: String, data: Data)? {
        if !self.streamingMode {
            throw Errors.programmingError
        }
        
        self.buffer.append(contentsOf: data)
        let dataPtr = UnsafePointer<CChar>(self.buffer)

        if self.buffer.count > 512 {
            let header = try self.parse(header: dataPtr)
            
            let endOffset = 512 + (header.filesize + (512 - header.filesize % 512))
            if self.buffer.count > endOffset {
                let data = Data(bytes: dataPtr.advanced(by: 512), count: header.filesize)
                self.buffer.removeFirst(endOffset)
                
                if header.isFile {
                    return (filename: header.filepath, data:data)
                }
            }
        }
        return nil
    }
    
    
    // MARK: - Private
    fileprivate func parse(header: UnsafePointer<CChar>) throws -> TarFileHeader {
        var result = TarFileHeader(isFile: false, filepath: "", filesize: 0, mtime: Date(timeIntervalSince1970: 0))
        let buffer = UnsafeBufferPointer<CChar>(start:header, count:512)
        
        // verify magic 257-262
        guard buffer[257] == 117 && // u
              header[258] == 115 && // s
              header[259] == 116 && // t
              header[260] == 97  && // a
              header[261] == 114 && // r
              header[262] == 0 else {
                
                if header[0] == 0 {
                    throw Errors.endOfFile
                }
                throw Errors.headerParseError
        }
        
        // verify checksum
        var checksum:UInt32 = 0
        for index in 0..<512 {
            if index >= 148 && index < 148+8 {
                checksum += 32
            } else {
                checksum += UInt32(header[index])
            }
        }
        let headerChecksum:UInt32 = UInt32(strtol(header.advanced(by: 148), nil, 8))
        if headerChecksum != checksum {
            throw Errors.headerParseError
        }
        
        // verify we're handling a file
        if header[156] == 0 || header[156] == 48 {
            result.isFile = true
        }

        // extract filename -> 0-99
        guard let filename = String(cString: header, encoding: String.Encoding.utf8) else {
            return result
        }
        result.filepath = filename
        
        // extract file size
        let fileSize = strtol(header.advanced(by: 124), nil, 8)
        result.filesize = fileSize
        
        // extract modification time
        let mTime = strtol(header.advanced(by: 136), nil, 8)
        result.mtime = Date(timeIntervalSince1970: TimeInterval(mTime))
        
        return result
    }
    
}
