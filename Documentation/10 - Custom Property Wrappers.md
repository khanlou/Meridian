# 10 - Custom Property Wrappers

Part of the magic of using Meridian is being able to define your own property wrappers. In fact, many of Meridian's own property wrappers are defined in this way. The most common custom property wrapper is an authentication property wrapper.

To make a custom property wrapper, You need to create an extractor. There are two protocols you can use to define your extractor: `ParameterizedExtractor` and `NonParameterizedExtractor`. We will focus on `NonParameterizedExtractor` here, but using  a parameter is very similar.

First, let's define an error in case the user isn't logged in.

    struct MissingAuth: ReportableError {    
        var statusCode: StatusCode = .forbidden
        
        var message: String = "This request requires an auth token."
    }

Next, we can define our extractor, which just needs an `extract` method. This method takes a `RequestContext` (and a parameter value, if applicable) and returns some value. The return type of the function will be the type of the value when it is a property wrapper. In this case, we are returning a `User`.

    struct AuthExtractor: NonParameterizedExtractor {
        static func extract(from context: RequestContext) throws -> User {
            guard let authToken = context.header.headers["X-Auth-Token"] else {
                throw MissingAuth()
            }
            guard let user = Database().user(for: authToken) else {
                throw MissingAuth()
            }
            return user
        }
    }

(Extractors can not yet access Meridian's environment.)

You could use this as-is, in a property wrapper:

    @Custom<AuthExtractor> var user // => will have type `User`

But we can make it a little nicer to use with a quick typealias:

    typealias Auth = Custom<AuthExtractor>

And then boom:

    @Auth var user // => will have type `User`

A first-class property wrapper.
