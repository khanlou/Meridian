# 20 - Request State

Request state is per-request storage. Middleware can write values into it, and later middleware or the route can read those values from the same request. Values stored in request state do not carry over to the next request.

Request state follows the same key pattern as environment values. First, define a key:

    struct CurrentUserKey: RequestStateKey {
        static var defaultValue: User? {
            nil
        }
    }

The value for a request state key must be `Sendable`, so custom types stored in request state should conform to `Sendable`.

Then add a typed property to `RequestStateValues`:

    extension RequestStateValues {
        var currentUser: User? {
            get {
                self[CurrentUserKey.self]
            }
            set {
                self[CurrentUserKey.self] = newValue
            }
        }
    }

Now middleware can write the value:

    struct AuthMiddleware: Middleware {

        @Header("X-Auth-Token") var authToken

        @EnvironmentObject var database: Database

        @RequestState(\.currentUser) var currentUser

        func execute(next: Responder) async throws -> Response {
            currentUser = database.user(for: authToken)
            return try await next.execute()
        }
    }

And a route can read it:

    struct ProfileRoute: Responder {

        @RequestState(\.currentUser) var currentUser

        func execute() throws -> Response {
            guard let currentUser else {
                throw MissingAuth()
            }
            return JSON(currentUser)
        }
    }

You can also use request state from later middleware. Because `@RequestState` reads and writes live request storage, it observes changes made by earlier middleware during the same request.
