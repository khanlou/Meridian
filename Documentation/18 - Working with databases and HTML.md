# 18 - Working with databases and HTML

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

Meridian does not include a way to talk to databases. However, many database libraries will work fine. If you're using Postgres, the Vapor community's Postgres library works well:

    .package(url: "https://github.com/vapor/postgres-kit.git", from: "2.12.0"),

Then, to make a database, make a new class, like so:

    import PostgresKit
    
    final class Database {
    
        let pools: EventLoopGroupConnectionPool<PostgresConnectionSource>

        public init(loopGroup: EventLoopGroup) throws {
             var configuration = try SQLPostgresConfiguration(url: ProcessInfo.processInfo.environment["DATABASE_URL"] ?? "")
             var tlsConfig = TLSConfiguration.makeClientConfiguration()
             tlsConfig.certificateVerification = .none
             configuration.coreConfiguration.tls = try .prefer(.init(configuration: tlsConfig))

             self.pools = EventLoopGroupConnectionPool(
                 source: PostgresConnectionSource(sqlConfiguration: configuration),
                 on: loopGroup
             )
         }
        
        func fetchAllUsers() async throws -> [User] {
            return try await self.pools
                .database(logger: Logger(label: "postgres"))
                .sql()
                .raw("SELECT * FROM users")
                .all(decoding: User.self)
        }
    }

Lastly, add your database to the environment:

    .environmentObject(with: { env in
        try! Database(loopGroup: env.loopGroup)
    })

Finally, you can use your database in a Responder:

    public struct ListUsersRoute: Responder {
        
        @EnvironmentObject var database: Database
    
        public func execute() async throws -> Response {
            return try await JSON(database.fetchAllUsers())
        }
    }
