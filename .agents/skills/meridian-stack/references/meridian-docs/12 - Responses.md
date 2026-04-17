# 12 - Responses

Typically, a request in Meridian asks for some data (in the form of property wrappers), uses that data to do something (like access a database), and then renders the result of that action. The rendered result may be JSON, HTML, a string, or something else, and the conversion of the value into something that can travel over the wire is handled by a `Response`.

### JSON

Meridian is great at JSON out of the box. 

To render JSON, simply wrap your codable value in the `JSON` response:

    struct ListTodos: Responder {
    
        @EnvironmentObject var database: Database
    
        func execute() async throws -> Response {
            try JSON(database.listTodos())
        }
    }

This will convert the array of todos into JSON data and automatically attach a `Content-Type` header with the value `application/json`.

The global JSONEncoder can be changed or accessed through the environment, or a custom encoder for any specific JSON response can be passed as an initializer parameter.

### Empty responses

Some requests should return an empty body with a status code of 204 No Content. Meridian provides a custom response for this.

    struct DeleteTodo: Responder {
    
        @URLParameter(\.id) var id
    
        @EnvironmentObject var database: Database
    
        func execute() async throws -> Response {
            database.removeTodo(withID: id)
            return EmptyResponse()
        }
    }

Using `EmptyResponse` automatically attaches a status code of 204 No Content.

### Redirects

There are three kinds of redirects: 

* `Redirect.temporary(url)` (307 Temporary Redirect)
* `Redirect.permanent(url)` (308 Permanent Redirect)
* `Redirect.seeOther(url)` (303 See Other)

### String responses

Sometimes it can be convenient to return a simple string for a response. Swift's `String` conforms to `Response` and can be returned in any `Responder`.

### Status codes and additional headers

If you need to change the status code or add additional headers, you can use SwiftUI-style modifiers to attach them.

    func execute() async throws -> Response {
        try JSON(database.listTodos())
            .statusCode(.imATeapot)
            .additionalHeaders(["Access-Control-Allow-Origin": "*"])
    }

With status code modifiers, the last one will win, and with headers, different keys will be merged, and in case of key conflicts, the last one wins.

### Custom responses

Conforming to the `Response` protocol can be a useful in some circumstances. The protocol allows you to access environment variables and other request context from property wrappers, like middleware and responders.
