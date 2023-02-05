# 14 - Working with databases and HTML

Meridian does not include support for HTML or databases, but they can be added very easily.

### HTML

To render HTML, the best approach is to use Robert Böhnke's Swim. Add it as a dependency in your package:

    .package(name: "HTML", url: "https://github.com/robb/Swim", .revision("46d115e")),

And in your target:

    .product(name: "HTML", package: "HTML")

The next step is to conform Swim's Node to be a `Response`:

    struct HTMLEncodingError: Error { }
    
    extension HTML.Node: Response {
        public func body() throws -> Data {
            var string = ""
            self.write(to: &string)
            guard let data = string.data(using: .utf8) else {
                throw HTMLEncodingError()
            }
            return data
        }
    }

Once that's done, you can return HTML nodes as responses:

    struct HTMLHelloWorld: Responder {
        
        func execute() throws -> Response {
            html(lang: "en-US") {
                body {
                    h1 { "Hello, world!" }
                }
            }
        }
    }

### Databases

Meridian does not include a way to talk to databases. However, any synchronous database library will work fine. If you're using Postgres, you can use this dependency:

    .package(name: "SwiftgreSQL", url: "https://github.com/khanlou/SwiftgresQL", from: "0.1.4"),

Then, to make a database, make a new class, like so:

    import SwiftgreSQL
    
    final class Database {
    
        let connection = try! Connection(connInfo: ProcessInfo.processInfo.environment["DATABASE_URL"] ?? "")
        
        func fetchAllUsers() throws -> [User] {
            return try connection.execute("SELECT * FROM users")
                .decode(User.self)
        }
    }

Lastly, add your database to the environment:

    .environmentObject(Database())

Now, you can use your database in a Responder:

    public struct ListUsersRoute: Responder {
        
        @EnvironmentObject var database: Database
    
        public func execute() throws -> Response {
            return try JSON(database.fetchAllUsers())
        }
    }
