# 11 - Routing

Meridian's routing allows the expression of all kinds of routes.

Let's look at the routing for a hypothetical todo app.

    Server(errorRenderer: BasicErrorRenderer())
        .register {
            LandingPage()
                .on(.get(.root))
        }
        .group(prefix: "/api/todos", errorRenderer: JSONErrorRenderer()) {
        
            ListTodos()
                .on([.get(.root), .get("/list")])
    
            ClearTodos()
                .on(.delete(.root))
    
            ShowTodo()
                .on(.get("/\(\.id)"))

            CreateTodo()
                .on(.post(.root))
    
            EditTodo()
                .on(.patch("/\(\.id)"))
    
            DeleteTodo()
                .on(.delete("/\(\.id)"))
    
        }
        .environmentObject(Database())
        .listen()

There are two ways to register routes — first, you can use the `register` method, which registers top level routes, and second, you can use the `group` method, which registers all the routes under a prefix (and includes an optional custom `ErrorRenderer`).

Every Responder needs to have `.on` called on it with a `RouteMatcher`. Mostly, you won't need to define custom `RouteMatcher` instances, but the ability is there if necessary.

Routes can be represented as a string literal, which is the easiest way to define a route. Leading and trailing slashes are normalized, so these are all the same:

    /route/
    /route
    route/
    route

`.root` is equivalent to an empty route, `""`.

Routes can be locked to specific methods, like so: `.on(.get(.root))`

Routes can have URLParameterKey keypaths interpolated into them, like so: `.on(.delete("/\(\.id)"))`

Routes can also also be represented by an array literal, which will match the first of any of the routes, like so: `.on([.get(.root), .get("/list")])`

To define a custom `RouteMatcher`, you only need to provide a single function:

    struct RouteMatcher {
        let matches: (RequestHeader) -> MatchedRoute?
    }

Using the header, decide if you want your matcher to match the incoming data. If it does match, return a MatchedRoute (with any matched url parameters). If it does not match, return nil.
