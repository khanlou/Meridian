//
//  main.swift
//  MeridianDemo
//
//  Created by Soroush Khanlou on 8/26/20.
//

import Foundation
import Backtrace
import Meridian

Backtrace.install()

Server(errorRenderer: BasicErrorRenderer())
    .group(prefix: "/todos", errorRenderer: JSONErrorRenderer()) {

        DeleteTodo()
            .on(.delete("/\(\.id)"))

        EditTodo()
            .on(.patch("/\(\.id)"))

        ShowTodo()
            .on(.get("/\(\.id)"))

        ClearTodos()
            .on(.delete(.root))

        CreateTodo()
            .on(.post(.root))
        
        ListTodos()
            .on(.get(.root))

    }
    .middleware(LoggingMiddleware())
    .middleware(TimingMiddleware())
    .environmentObject(Database())
    .listen()
