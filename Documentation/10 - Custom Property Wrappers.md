# 10 - Custom Property Wrappers

Part of the magic of using Meridian is being able to define your own property wrappers. In fact, many of Meridian's own property wrappers are defined in this way. The most common custom property wrapper is an authentication property wrapper.

To make a custom property wrapper, You need to create an extractor. There are two protocols you can use to define your extractor: `ParameterizedExtractor` and `NonParameterizedExtractor`. We will focus on `NonParameterizedExtractor` here, but using  a parameter is very similar.

### Simple Extractors

An extractor just needs a static `extract` method. This method takes a `RequestContext` (and a parameter value, if applicable) and returns some value. The return type of the function will be the type of the value when it is a property wrapper.

For a simple example, we'll take a look at an API version, passed in via a header:

    enum APIVersion: String {
        case v1 = "2021-06-23"
        case v2 = "2023-02-04"
    }
    
    struct APIVersionExtractor: NonParameterizedExtractor {
        static func extract(from context: RequestContext) throws -> User {
            let apiVersion = context.header.headers["X-API-Version"] else {
                return nil
            }
            return APIVersion(rawValue: apiVersion)
        }
    }

You could use this as-is, in a property wrapper:

    @Custom<APIVersionExtractor> var apiVersion // => will have type `APIVersion`

But we can make it a little nicer to use with a quick typealias:

    typealias APIVersion = Custom<APIVersionExtractor>

And then boom:

    @APIVersion var apiVersion // => will have type `APIVersion`

A first-class property wrapper.

### Advanced Extractors

We can also use custom property wrappers for authentication and access control.

First, let's define an error in case the user isn't logged in.

    struct MissingAuth: ReportableError {    
        var statusCode: StatusCode = .forbidden
        
        var message: String = "This request requires an auth token."
    }

Using `context.environment`, you can access both environment objects (like Databases) and keyed environment values (like DateFormatters).

    struct AuthExtractor: NonParameterizedExtractor {
        static func extract(from context: RequestContext) throws -> User {
            guard let authToken = context.header.headers["X-Auth-Token"] else {
                throw MissingAuth()
            }
            guard let database = context.environment.object(ofType: Database.self) else {
                fatalError("There must be a Database to run this app.")
            }
            guard let user = database.user(for: authToken) else {
                throw MissingAuth()
            }
            return user
        }
    }

Another typealias, just like above:

    typealias Auth = Custom<AuthExtractor>

And now you can use your new authentication property wrapper:

    @Auth var user // => will have type `User`

This requires the request to be logged into execute (providing access control) and also allows you to access the user in the request's `execute()` method.
