# 14 - Error Renderers

Different parts of your app may need to render errors in different ways. For example, a website with a landing page and an API may need two different error renderings. If you go to the wrong address anywhere other than the API, you should get an HTML page that helps you get back to where you want to go. However, if you are in the `/api` subdirectory, you should get a machine readable JSON error. Here's an example:

    Server(errorRenderer: BasicErrorRenderer())
        .routes {
            LandingPage()
                .on(.get(.root))
                
            Group("/api") {
                ListTodos()
                    .on(.get("/todos))
            }
            .errorRenderer(JSONErrorRenderer())
            .middleware(RateLimitingMiddleware())
            .middleware(LoggingMiddleware())
        }
        .listen()

With the example, if you go anywhere other than a child of `/api`, you will get the `BasicErrorRenderer`. That will simply render the localized description of the error as a string. If you're in the `/api` subdirectory (or any child), it'll use the `JSONErrorRenderer`, and show a JSON-parseable error.

`BasicErrorRenderer` and `JSONErrorRenderer` are the two error renderers that Meridian ships with. It's likely that you'll want to write your own error renderers, either to match the HTML style of your site, or to customize the output of the JSON.

To create a new error renderer, you need to conform to the `ErrorRenderer` protocol:

    protocol ErrorRenderer {

        func render(primaryError: Error, context: ErrorsContext) async throws -> Response

    }

ErrorRenderers can return any Response — JSON, HTML, plain text, or something else — with the content of the error rendered into it. Error renderers will always get at least one error, the `primaryError`, but the `context` includes an `allErrors` array, which can contain more than one error. Because Meridian can find errors in more than one property wrapper simultaneously, any errors besides the first will be included in the `context`.

`ErrorsContext` contains a few useful helpers, including a status code you can use when rendering your response (`statusCode`), a single error message string (`errorMessage`), and an array of error message strings (`errorMessages`). These can be useful when rendering your own error responses.

As an example, Meridian's `JSONErrorRenderer` looks like this:

    struct ErrorContainer: Codable {
        let errors: [String]
    }

    struct JSONErrorRenderer: ErrorRenderer {

        func render(primaryError error: Error, context: ErrorsContext) async throws -> Response {
            return JSON(ErrorContainer(errors: context.errorMessages))
                .statusCode(context.statusCode)
        }
    }

The `render` function can throw, which will close the connection to the peer. This should not be relied on.
