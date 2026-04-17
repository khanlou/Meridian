# 11 - Routing

Meridian's routing allows the expression of all kinds of routes.

Let's look at the routing for a hypothetical todo app.

    Server(errorRenderer: BasicErrorRenderer())
        .routes {
            LandingPage()
                .on(.get(.root))

            Group("/api/todos") {

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
            .errorRenderer(JSONErrorRenderer())
        }
        .environmentObject(Database())
        .listen()

Routes go in a `routes` method. You can have more than one, but you don't need more than one. Inside the routes method is a Swift result builder, which accepts both routes and groups. Using the `Group` type, you can register multiple routes under a prefix. You can also leave the prefix off, which serves as an organizational tool and will not create a path component. You can read more about Groups in [14 Error Renderers](14 - Error Renderers.md) and [15 Middleware](15 - Middleware.md)

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
