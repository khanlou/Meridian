//
//  Todos.swift
//  
//
//  Created by Soroush Khanlou on 9/2/20.
//

import Foundation
import Meridian

// Specs
// https://www.todobackend.com/specs/index.html?https://meridian-demo.herokuapp.com/todos

extension Response {
    func allowCORS() -> Response {
        return self.additionalHeaders([
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Headers": "X-Requested-With, Origin, Content-Type, Accept",
            "Access-Control-Allow-Methods": "POST, GET, PUT, OPTIONS, DELETE, PATCH",
        ])
    }
}

struct ListTodos: Route {

    static let route: RouteMatcher = "/todos"

    @EnvironmentObject var database: Database

    func execute() throws -> Response {
        JSON(database.todos)
            .allowCORS()
    }

}

struct ClearTodos: Route {
    static let route: RouteMatcher = .delete("/todos")

    @EnvironmentObject var database: Database

    func execute() throws -> Response {
        self.database.todos = []
        return JSON(database.todos)
            .allowCORS()
    }
}

struct CreateTodo: Route {
    static let route: RouteMatcher = .post("/todos")

    @JSONBody var todo: Todo

    @EnvironmentObject var database: Database

    func execute() throws -> Response {
        self.database.todos.append(todo)
        return JSON(todo)
            .statusCode(.created)
            .allowCORS()
    }
}

struct ShowTodo: Route {
    static let route: RouteMatcher = "/todos/\(.id)"

    @URLParameter(key: .id) var id: String

    @EnvironmentObject var database: Database

    func execute() throws -> Response {
        guard let todo = database.todos.first(where: { $0.id.uuidString == id }) else {
            throw NoRouteFound()
        }
        return JSON(todo).allowCORS()
    }

}

struct TodoPatch: Codable {
    var title: String?
    var completed: Bool?
    var order: Int?
}

struct EditTodo: Route {
    static let route: RouteMatcher = .patch("/todos/\(.id)")

    @URLParameter(key: .id) var id: String

    @JSONBody var patch: TodoPatch

    @EnvironmentObject var database: Database

    func execute() throws -> Response {
        guard let index = database.todos.firstIndex(where: { $0.id.uuidString == id }) else {
            throw NoRouteFound()
        }
        if let newTitle = patch.title {
            database.todos[index].title = newTitle
        }
        if let newCompleted = patch.completed {
            database.todos[index].completed = newCompleted
        }
        if let newOrder = patch.order {
            database.todos[index].order = newOrder
        }
        return JSON(database.todos[index]).allowCORS()
    }
}

struct DeleteTodo: Route {
    static let route: RouteMatcher = .delete("/todos/\(.id)")

    @URLParameter(key: .id) var id: String

    @EnvironmentObject var database: Database

    func execute() throws -> Response {
        database.todos.removeAll(where: { $0.id.uuidString == id })
        return EmptyResponse().allowCORS()
    }
}
