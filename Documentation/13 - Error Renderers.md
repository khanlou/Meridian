# 13 - Error Renderers

Different parts of your app may need to render errors in different ways. For example, a website with a landing page and an API may need two different error renderings. If you go to the wrong address anywhere other than the API, you should get an HTML page that helps you get back to where you want to go. However, if you are in the `/api` subdirectory, you should get a machine readable JSON error. Here's an example:

    Server(errorRenderer: BasicErrorRenderer())
        .register {
            LandingPage()
                .on(.get(.root))
        }
        .group(prefix: "/api", errorRenderer: JSONErrorRenderer()) {
            ListTodos()
                .on(.get("/todos))
        }
        .listen()

With the example, if you go anywhere other than a child of `/api`, you will get the `BasicErrorRenderer`. That will simply render the localized description of the error as a string. If you're in the `/api` subdirectory (or any child) it'll use the `JSONErrorRenderer`, and show a JSON-parseable error.

`BasicErrorRenderer` and `JSONErrorRenderer` are the two error renderers that Meridian ships with. It's likely that you'll want to write your own error renderers, either to match the HTML style of your site, or to customize the output of the JSON.

To create a new error renderer, you need to conform to the `ErrorRenderer` protocol:

    protocol ErrorRenderer {
    
        func render(error: Error) throws -> Response
    
    }

Inside here, you can return any Response — JSON, HTML, plain text, something else — with the content of the error rendered into it.

As an example, Meridian's `JSONErrorRenderer` looks like this:

    struct ErrorContainer: Codable {
        let message: String
    }
    
    public struct JSONErrorRenderer: ErrorRenderer {
    
        public init() { }
    
        public func render(error: Error) throws -> Response {
            JSON(ErrorContainer(message: (error as? ReportableError)?.message ?? "An error occurred."))
                .statusCode((error as? ReportableError)?.statusCode ?? .internalServerError)
        }
    }

The `render` function can throw, however Meridian will crash here if something goes wrong. In a future version, it may close the connection to the peer and continue running.