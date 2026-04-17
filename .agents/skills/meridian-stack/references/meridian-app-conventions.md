# Meridian App Conventions (Generic)

This file summarizes common, observable patterns in Meridian + HTML DSL server apps so you can build consistent routes, layouts, and database queries.

## Project shape
- Swift Package with two targets: `App` (executable) and a library target for routes/models.
- Server entrypoint lives in `Sources/App/main.swift` and wires routes + middleware.
- Web UI is HTML rendered via the HTML/Swim DSL (not SwiftUI).
- Static assets live in `Sources/App/Static` and are served via `BundledFiles(bundle: .module)`.

## Routing & responders
- Routes are `struct`s conforming to `Responder` in `Sources/<LibraryTarget>/Routes/...`.
- Public route types include `public init()` and `public func execute() async throws -> Response`.
- Route composition and registration is in `main.swift` using `.routes { ... }` and `Group("/path") { ... }`.
- Routes typically use `layoutWithNavigation(...)` or `defaultLayout(...)` to wrap HTML output.
- Parameters are defined in `Sources/<LibraryTarget>/Routes/URLParameters.swift` via `URLParameterKey` types and `ParameterKeys` extensions.

## Middleware & environment
- Database is injected as an `@EnvironmentObject` (see `main.swift` and request logging middleware).
- Auth is accessed via `@Auth` or `@OptionalAuth` in routes.
- Common request data uses Meridian property wrappers: `@Header`, `@Path`, `@RequestMethod`, `@Body`, `@QueryParameter`, `@URLBodyParameter`.

## HTML rendering
- HTML is built with the `HTML` DSL and `@NodeBuilder` helpers.
- Layout helpers live in `Sources/<LibraryTarget>/Layouts/`.
- Forms are built with DSL nodes (e.g., `form`, `input`, `label`, `textarea`) and use string paths.
- Scripts are injected with `script { Node.raw("...") }` when needed.

## Database access
- `Sources/<LibraryTarget>/Model/Database/Database.swift` encapsulates all SQL access.
- SQL is written as multiline string literals with `bind:` and `binds:` for parameters.
- Database methods are `async throws` and return decoded model types or simple structs.
- Example pattern:
  - `execute("SELECT * FROM users WHERE id = \(bind: id)")`
  - `.all(decoding: User.self).first.unwrap()`

## Database models
- `Sources/<LibraryTarget>/Model/DatabaseModels.swift` is auto-generated (using a tool called SchemaSwift) and should not be edited manually.
- Database model types use `static let tableName` and `CodingKeys` to map snake_case DB columns to Swift camelCase.
- Database enums are Codable and mirror database enums.

## Models & utilities
- Models are in `Sources/<LibraryTarget>/Model/` and are mostly `struct` types.
- Formatting helpers live in `Model/*Formatter.swift` and extensions under `Extensions/`.

## Tests
- Tests live in `Tests/<LibraryTarget>Tests/` using `XCTest`.
- Tests are minimal and focused on core model behavior.

## Style & patterns
- Prefer `async/await` over callbacks.
- Avoid force unwraps except when existing patterns explicitly do so.
- Keep route logic thin: fetch data, render HTML, and delegate calculations to model helpers.

## HTML + Meridian response bridging
- `Sources/<LibraryTarget>/Layouts/HTML+Meridian.swift` typically extends `HTML.Node` to conform to `Response`.
- Implementation writes the node to a UTF-8 string and returns `Data`.
- This allows `HTML.Node` to be returned directly from `execute()`.

## Route example (typical)
- `public struct Overview: Responder { ... }`
- `@Auth var auth`, `@EnvironmentObject var database: Database`
- `@QueryParameter("date") var date: GregorianDate?`
- `execute()` gathers data via `Database` then returns `layoutWithNavigation { ... }`
- Uses `@NodeBuilder` helpers for tables and blocks

