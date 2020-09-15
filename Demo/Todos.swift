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

struct IDParameter: URLParameterKey {
    public typealias DecodeType = String
}

extension ParameterKeys {
    var id: IDParameter {
        IDParameter()
    }
}

struct ListTodos: Responder {

    @EnvironmentObject var database: Database

    func execute() throws -> Response {
        JSON(database.todos)
            .allowCORS()
    }

}

struct ClearTodos: Responder {
    
    @EnvironmentObject var database: Database

    func execute() throws -> Response {
        self.database.todos = []
        return JSON(database.todos)
            .allowCORS()
    }
}

struct CreateTodo: Responder {

    @JSONBody var todo: Todo

    @EnvironmentObject var database: Database

    func execute() throws -> Response {
        self.database.todos.append(todo)
        return JSON(todo)
            .statusCode(.created)
            .allowCORS()
    }
}

struct ShowTodo: Responder {

    @URLParameter(\.id) var id

    @EnvironmentObject var database: Database

    func execute() throws -> Response {
        guard let todo = database.todos.first(where: { $0.id.uuidString == id }) else {
            throw NoRouteFound()
        }
        return JSON(todo).allowCORS()
    }
}

struct EditTodo: Responder {

    @URLParameter(\.id) var id

    @JSONValue("title") var title: String?
    @JSONValue("completed") var completed: Bool?
    @JSONValue("order") var order: Int?

    @EnvironmentObject var database: Database

    func execute() throws -> Response {
        guard let index = database.todos.firstIndex(where: { $0.id.uuidString == id }) else {
            throw NoRouteFound()
        }
        if let newTitle = title {
            database.todos[index].title = newTitle
        }
        if let newCompleted = completed {
            database.todos[index].completed = newCompleted
        }
        if let newOrder = order {
            database.todos[index].order = newOrder
        }
        return JSON(database.todos[index]).allowCORS()
    }
}

struct DeleteTodo: Responder {

    @URLParameter(\.id) var id

    @EnvironmentObject var database: Database

    func execute() throws -> Response {
        database.todos.removeAll(where: { $0.id.uuidString == id })
        return EmptyResponse().allowCORS()
    }
}
