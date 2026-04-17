---
name: meridian-stack
description: "Build or modify Meridian-based Swift server apps that render HTML via the HTML/Swim DSL, define routes with property wrappers, and query Postgres via a Database.swift layer. Use for: adding routes, request parsing, middleware, responses/errors, HTML rendering, SchemaSwift-generated models, or server wiring in Meridian projects."
---

# Meridian Server Stack

## Overview
Use this skill to implement or extend a Meridian web server: define `Responder` routes with property wrappers, render HTML using the HTML/Swim DSL, and route all database access through a `Database.swift` layer backed by SchemaSwift-generated models.

## Quick start
1. Pick the Meridian doc that matches the task (see “Reference map”).
2. Follow the generic app conventions in `references/meridian-app-conventions.md`.
3. Implement route logic in a `Responder` struct and render HTML with layout helpers.
4. Add or update `Database` queries; do not edit `DatabaseModels.swift` directly.

## Core workflow (new page/route)
1. **Define the route type**
   - Create a `public struct Name: Responder` in `Sources/.../Routes/...`.
   - Add `public init()` and `public func execute() async throws -> Response`.
   - Use Meridian property wrappers (`@QueryParameter`, `@Path`, `@Body`, `@URLBodyParameter`, `@Header`, `@RequestMethod`) for request data.
   - Use `@EnvironmentObject var database: Database` for DB access and `@Auth`/`@OptionalAuth` for auth.

2. **Fetch data**
   - Call `Database` methods (`async throws`) for any SQL access.
   - If a query does not exist, add it to `Database.swift` using `bind:`/`binds:` to protect against SQL injection.

3. **Render HTML**
   - Return HTML nodes using a layout helper like `layoutWithNavigation { ... }` or `defaultLayout { ... }`.
   - Build content with the HTML DSL and `@NodeBuilder` helpers.
   - Use `script { Node.raw("...") }` for inline scripts.

4. **Wire the route**
   - Register the route in the server entrypoint (often `Sources/App/main.swift`) using `.routes { ... }` and `Group("/path") { ... }`.

## Core workflow (new database query)
1. Add a method to `Database.swift` that returns model types or simple DTO structs.
2. Use multi-line SQL with `bind:` or `binds:`.
3. Decode rows with `.all(decoding:)`, `.first(decoding:)`, and `.unwrap()` where appropriate.
4. If you need new columns or tables, update the schema and regenerate `DatabaseModels.swift` via SchemaSwift (do not edit the file by hand).

## Core workflow (new request parsing)
1. Use a built-in Meridian property wrapper (see docs below).
2. If needed, create a custom property wrapper (see docs).
3. Keep parsing logic close to the route; keep business logic in model helpers.

## Reference map
Read only the files you need; they are all in `references/meridian-docs/`.

- **Install/setup**: `01 - Installation.md`
- **Hello world route**: `02 - Hello World.md`
- **Query parameters**: `03 - Query Parameters.md`
- **URL parameters**: `04 - URL Parameters.md`
- **JSON bodies**: `05 - Parsing JSON Bodies.md`
- **Single JSON values**: `06 - Parsing Individual JSON Values.md`
- **URL-encoded bodies**: `07 - URL Body Parameters.md`
- **Environment**: `08 - Environment.md`
- **Headers, paths, methods**: `09 - Headers, Paths, and Methods.md`
- **Custom property wrappers**: `10 - Custom Property Wrappers.md`
- **Routing / route matching**: `11 - Routing.md`
- **Responses**: `12 - Responses.md`
- **Errors**: `13 - Errors.md`
- **Error renderers**: `14 - Error Renderers.md`
- **Middleware**: `15 - Middleware.md`
- **WebSockets**: `16 - WebSockets.md`
- **Static files**: `17 - Static Files.md`
- **Databases + HTML/Swim DSL**: `18 - Working with databases and HTML.md`
- **Deploying**: `19 -  Deploying to Heroku.md`

## Implementation notes
- Prefer `async/await` over callbacks.
- Avoid force unwraps unless an existing pattern uses them.
- 