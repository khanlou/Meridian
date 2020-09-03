//
//  ThreadEnvironment.swift
//  Meridian
//
//  Created by Soroush Khanlou on 8/29/20.
//

import Foundation

public var _errors: [ReportableError] {
    get {
        (Thread.current.threadDictionary[RequestErrorsKey] as? [Any] ?? []).compactMap({ $0 as? ReportableError })
    }
    set {
        Thread.current.threadDictionary[RequestErrorsKey] = newValue
    }
}

public var _currentRequest: RequestContext {
    guard let currentRequest = Thread.current.threadDictionary[CurrentRequestKey] as? RequestContext else {
        fatalError("There must be a current request in the thread dictionary.")
    }
    return currentRequest
}
