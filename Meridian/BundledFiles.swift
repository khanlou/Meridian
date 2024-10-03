//
//  BundledFiles.swift
//  
//
//  Created by Soroush Khanlou on 2/12/21.
//

import Foundation

public struct Forbidden: ReportableError {
    public let statusCode: StatusCode = .forbidden

    public let message = "This path cannot be accessed."
}

public struct _StaticFiles: Responder {

    public let bundle: Bundle

    public init(bundle: Bundle) {
        self.bundle = bundle
    }

    @Path var path

    public func execute() throws -> Response {

        guard var path = self.path.removingPercentEncoding else {
            throw Forbidden()
        }

        path = String(path.drop(while: { $0 == "/" }))

        guard !path.contains("../") else {
            throw NoRouteFound() // should be 403
        }

        guard let filePath = bundle.url(forResource: path, withExtension: nil) else {
            throw NoRouteFound()
        }

        if let mimeType = commonMimeTypes[filePath.pathExtension] {
            return File(url: filePath)
                .additionalHeaders(["Content-Type": mimeType])
        } else {
            return File(url: filePath)
        }
    }

    let commonMimeTypes: [String: String] = [
        "aac": "audio/aac",
        "abw": "application/x-abiword",
        "apng": "image/apng",
        "arc": "application/x-freearc",
        "avif": "image/avif",
        "avi": "video/x-msvideo",
        "azw": "application/vnd.amazon.ebook",
        "bin": "application/octet-stream",
        "bmp": "image/bmp",
        "bz": "application/x-bzip",
        "bz2": "application/x-bzip2",
        "cda": "application/x-cdf",
        "csh": "application/x-csh",
        "css": "text/css",
        "csv": "text/csv",
        "doc": "application/msword",
        "docx": "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
        "eot": "application/vnd.ms-fontobject",
        "epub": "application/epub+zip",
        "gz": "application/gzip",
        "gif": "image/gif",
        "htm, .html": "text/html",
        "ico": "image/vnd.microsoft.icon",
        "ics": "text/calendar",
        "jar": "application/java-archive",
        "jpeg": "image/jpeg",
        "jpg": "image/jpeg",
        "js": "text/javascript",
        "json": "application/json",
        "jsonld": "application/ld+json",
        "mid": "audio/midi",
        "midi": "audio/midi",
        "mjs": "text/javascript",
        "mp3": "audio/mpeg",
        "mp4": "video/mp4",
        "mpeg": "video/mpeg",
        "mpkg": "application/vnd.apple.installer+xml",
        "odp": "application/vnd.oasis.opendocument.presentation",
        "ods": "application/vnd.oasis.opendocument.spreadsheet",
        "odt": "application/vnd.oasis.opendocument.text",
        "oga": "audio/ogg",
        "ogv": "video/ogg",
        "ogx": "application/ogg",
        "opus": "audio/ogg",
        "otf": "font/otf",
        "png": "image/png",
        "pdf": "application/pdf",
        "php": "application/x-httpd-php",
        "ppt": "application/vnd.ms-powerpoint",
        "pptx": "application/vnd.openxmlformats-officedocument.presentationml.presentation",
        "rar": "application/vnd.rar",
        "rtf": "application/rtf",
        "sh": "application/x-sh",
        "svg": "image/svg+xml",
        "tar": "application/x-tar",
        "tif": "image/tiff",
        "tiff": "image/tiff",
        "ts": "video/mp2t",
        "ttf": "font/ttf",
        "txt": "text/plain",
        "vsd": "application/vnd.visio",
        "wav": "audio/wav",
        "weba": "audio/webm",
        "webm": "video/webm",
        "webp": "image/webp",
        "woff": "font/woff",
        "woff2": "font/woff2",
        "xhtml": "application/xhtml+xml",
        "xls": "application/vnd.ms-excel",
        "xlsx": "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        "xml": "application/xml",
        "xul": "application/vnd.mozilla.xul+xml",
        "zip": "application/zip",
        "3gp": "video/3gpp",
        "3g2": "video/3gpp2",
        "7z": "application/x-7z-compressed",
    ]
}

public func BundledFiles(bundle: Bundle) -> Route {
    return _StaticFiles(bundle: bundle)
        .on(RouteMatcher(matches: { header in
            if bundle.url(forResource: header.path, withExtension: nil) != nil {
                return MatchedRoute(parameters: [:])
            } else {
                return nil
            }
        }))
}
