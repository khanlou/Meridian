# 15 - Middleware

Middleware is a way to inject behavior before or after your requests.

    Server(errorRenderer: BasicErrorRenderer())
        .register {
            LandingPage()
                .on(.get(.root))
        }
        .middleware(LoggingMiddleware())
        .middleware(TimingMiddleware())
        .listen()

This code will install two middlewares into the server, one to log every request that comes in, and one logs the duration of each request.

Middlewares are executed in the order that they are added. In this case, the logging middleware is the first thing that is executed when the request comes in, and the last thing to be executed as the request is being sent out.

To create a new middleware, you need to conform to the `Middleware` protocol:

    protocol Middleware {
        func execute(next: Responder) async throws -> Response
    }

Middlewares can use any of the property wrappers that regular Responders can use. For example, the LoggingMiddleware looks like this:

    public struct LoggingMiddleware: Middleware {
    
        @Path var path
        
        @RequestMethod var method
    
        public init() { }
    
        public func execute(next: Responder) async throws -> Response {
            print("Request: \(method) \(path)")
            return try await next.execute()
        }
    }

To execute something after the responder has done its work, store the result of the `execute()` method, do your extra work, and then return the result. 

    public struct TimingMiddleware: Middleware {
    
        public init() { }
    
        public func execute(next: Responder) async throws -> Response {
            let start = Date()
            let result = try await next.execute()
            let duration = -start.timeIntervalSinceNow
            print("Request took \(duration)s")
            return result
        }
    }

Middleware can take an arbitrary amount of time to execute, using `async` tasks.

Middleware applies to all queries that come into the server.
