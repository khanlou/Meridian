# 02 - Hello World

Here is a minimal Meridian server.

    import Backtrace
    import Meridian
    
    Backtrace.install()
    
    struct HelloWorld: Responder {
        func execute() throws -> Response {
            "Hello, world!"
        }
    }
    
    Server(errorRenderer: BasicErrorRenderer())
        .register({
            HelloWorld()
                .on(.root)
        })
        .listen()

We will go over each line in depth.

First, import Meridian and Backtrace (for crashes).

    import Backtrace
    import Meridian
    
Install Backtrace. This will ensure that any crashes will be logged.
    
    Backtrace.install()
    
Create your first responder:

    struct HelloWorld: Responder {
        func execute() throws -> Response {
            "Hello, world!"
        }
    }

A Responder is a unit that responds to a request in one way. You can think of these as logical endpoints. While you can use a Responder to respond to more than one route, it generally corresponds to one route.
    
Next, create a server with a basic error renderer. You can read more about error renderers in the appropriate section. `BasicErrorRenderer` outputs the `localizedDescription` of the error in plain text in the response.
    
    Server(errorRenderer: BasicErrorRenderer())

Register your new route. The `.on` modifier attaches a path to a `Responder`, and lets Meridian know when a specific `Responder` should be used when a request comes in.

        .register({
            HelloWorld()
                .on(.root)
        })

Start your server:

        .listen()

Now you can visit [http://localhost:3000](http://localhost:3000) to see your new server in action!