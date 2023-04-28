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
    .register({
        WebSocketTester()
            .on(.get("/ws"))
    })
    .middleware(LoggingMiddleware())
    .middleware(TimingMiddleware())
    .environmentObject(Database())
    .listen()


struct WebSocketTester: WebSocketResponder {
    func connected(to websocket: WebSocket) async throws {
        for try await message in websocket.textMessages {
            print("Received \(message)")
            websocket.send(text: "String: \(message) is \(message.count) characters long")
        }
        print("closed!")
    }
}
