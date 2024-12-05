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
    .routes {
        Group("todos") {

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
        .errorRenderer(JSONErrorRenderer())
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

    @Path var path

    func connected(to webSocket: WebSocket) async throws {

        print("Connected to websocket")

        for try await message in webSocket.textMessages {
            print("Received \(message) at \(path)")
            webSocket.send(text: "String: \(message) is \(message.count) characters long")
        }

        print("Websocket closed!")
    }
}
