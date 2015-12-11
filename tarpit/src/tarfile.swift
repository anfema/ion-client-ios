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


public class TarFile {

    public enum Errors: ErrorType {
        /// Invalid header encountered
        case HeaderParseError
        
        /// End of file marker found
        case EndOfFile
        
        /// Programming error (called extractFile on streaming mode or consumeData on file mode)
        case ProgrammingError
    }

    private struct TarFileHeader {
        var isFile: Bool
        var filepath: String
        var filesize: size_t
        var mtime: NSDate
    }
    
    private let streamingMode: Bool
    
    // MARK: - File based unpack
    private var data: NSData! = nil
    private var offset: size_t = 0

    /// Initialize for unpacking with data
    ///
    /// - parameter data: tar file data
    public init(data: NSData) {
        self.streamingMode = false
        self.data = data
    }

    /// Initialize for unpacking with file name
    ///
    /// - parameter fileName: file name to open
    ///
    /// - throws: NSData contentsOfURL errors
    public convenience init(fileName: String) throws {
        self.init(data: try NSData(contentsOfURL: NSURL(fileURLWithPath: fileName), options: .DataReadingMappedIfSafe))
    }

    /// Extract file from disk
    ///
    /// - throws: TarFile.Errors
    ///
    /// - returns: tuple with filename and data
    public func extractFile() throws -> (filename: NSString, mtime: NSDate, data: NSData)? {
        if streamingMode {
            throw Errors.ProgrammingError
        }
        
        // fetch one block at offset
        let dataPtr = UnsafePointer<CChar>(self.data.bytes)

        while true {
            // parse header info
            let header = try self.parseHeader(dataPtr.advancedBy(self.offset))

            var data: NSData? = nil
            if header.filesize > 0 {
                // copy over data
                data = NSData(bytes: dataPtr.advancedBy(self.offset + 512), length: header.filesize)
            }
            
            // advance offset (512 byte blocks)
            var size = 0
            if header.filesize > 0 {
                size = (header.filesize + (512 - header.filesize % 512))
            }
            self.offset += 512 + size

            if let data = data where header.isFile {
                // return file data
                return (filename: header.filepath, mtime: header.mtime, data: data)
            }
        }
    }
    
    // MARK: - Stream based unpack
    private var buffer = [CChar]()
    
    /// Initialize for unpacking from streaming data
    ///
    /// - parameter streamingData: initial data or nil
    public init(streamingData: [CChar]?) {
        self.streamingMode = true
        if let data = streamingData {
            self.buffer.appendContentsOf(data)
        }
    }

    /// Consume bytes from stream, return unpacked file
    ///
    /// - parameter data: data to consume
    ///
    /// - throws: TarFile.Errors
    ///
    /// - returns: tuple with filename and data on completion of a single file
    public func consumeData(data: [CChar]) throws -> (filename: NSString, data: NSData)? {
        if !self.streamingMode {
            throw Errors.ProgrammingError
        }
        
        self.buffer.appendContentsOf(data)
        let dataPtr = UnsafePointer<CChar>(self.buffer)

        if self.buffer.count > 512 {
            let header = try self.parseHeader(dataPtr)
            
            let endOffset = 512 + (header.filesize + (512 - header.filesize % 512))
            if self.buffer.count > endOffset {
                let data = NSData(bytes: dataPtr.advancedBy(512), length: header.filesize)
                self.buffer.removeFirst(endOffset)
                
                if header.isFile {
                    return (filename: header.filepath, data:data)
                }
            }
        }
        return nil
    }
    
    
    // MARK: - Private
    private func parseHeader(let header: UnsafePointer<CChar>) throws -> TarFileHeader {
        var result = TarFileHeader(isFile: false, filepath: "", filesize: 0, mtime: NSDate(timeIntervalSince1970: 0))
        let buffer = UnsafeBufferPointer<CChar>(start:header, count:512)
        
        // verify magic 257-262
        guard buffer[257] == 117 && // u
              header[258] == 115 && // s
              header[259] == 116 && // t
              header[260] == 97  && // a
              header[261] == 114 && // r
              header[262] == 0 else {
                
                if header[0] == 0 {
                    throw Errors.EndOfFile
                }
                throw Errors.HeaderParseError
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
        let headerChecksum:UInt32 = UInt32(strtol(header.advancedBy(148), nil, 8))
        if headerChecksum != checksum {
            throw Errors.HeaderParseError
        }
        
        // verify we're handling a file
        if header[156] == 0 || header[156] == 48 {
            result.isFile = true
        }

        // extract filename -> 0-99
        guard let filename = String(CString: header, encoding: NSUTF8StringEncoding) else {
            return result
        }
        result.filepath = filename
        
        // extract file size
        let fileSize = strtol(header.advancedBy(124), nil, 8)
        result.filesize = fileSize
        
        // extract modification time
        let mTime = strtol(header.advancedBy(136), nil, 8)
        result.mtime = NSDate(timeIntervalSince1970: NSTimeInterval(mTime))
        
        return result
    }
    
}