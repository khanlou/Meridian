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

Server(errorRenderer: JSONErrorRenderer.self)
    .group(prefix: "/todos",
           DeleteTodo.self,
           EditTodo.self,
           ShowTodo.self,
           ClearTodos.self,
           CreateTodo.self,
           ListTodos.self
    )
    .environmentObject(Database())
    .listen()
