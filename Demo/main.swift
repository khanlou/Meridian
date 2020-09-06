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

Server(errorRenderer: BasicErrorRenderer.self)
    .group(prefix: "/todos",
           DeleteTodo.self,
           EditTodo.self,
           ShowTodo.self,
           ClearTodos.self,
           CreateTodo.self,
           ListTodos.self,
           errorRenderer: JSONErrorRenderer.self
    )
    .environmentObject(Database())
    .listen()
