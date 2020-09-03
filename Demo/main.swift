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

let app = Server(
    routes: [
        DeleteTodo.self,
        EditTodo.self,
        ShowTodo.self,
        ClearTodos.self,
        CreateTodo.self,
        ListTodos.self,
    ],
    errorRenderer: JSONErrorRenderer.self
)
.environmentObject(Database())

app.listen()
