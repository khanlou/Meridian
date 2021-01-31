# 03 - Query Parameters

Meridian uses property wrappers to extract information from incoming requests.

Here's how you can extract query parameters:

    struct HelloWorld: Responder {
    
        @QueryParameter("name") var name: String
    
        func execute() throws -> Response {
            "Hello, \(name)!"
        }
    }

Using the same server from the "Hello, world" section of the documentation, you can run this code again. If you try to load the root of the server ([http://localhost:3000/](http://localhost:3000/)), you will now see an error:

> The endpoint expects a query parameter named "name", but it was missing.

Because `name` is not-optional, the `execute()` function can not be called unless it has a value. If you load the root of the server with the correct query parameter ([http://localhost:3000/?name=Soroush](http://localhost:3000/?name=Soroush)), you should see:

> Hello, Soroush!

### Optionality

If the query parameter is not always required, you can change its type to be an optional:

    @QueryParameter("name") var name: String?

You will have to handle this optionality in your `execute()` function:

    func execute() throws -> Response {
        "Hello, \(name ?? "world")!"
    }

For simple behavior like providing a default, you can do this inline. 

    @QueryParameter("name") var name: String = "world"

### Codable

Query parameters support `Codable`. This can be something as simple as an integer or double:

    @QueryParameter("minimumPrice") var name: Double?

For this example, even though the value is optional, if the value cannot be decoded into a `Double`, an error will be shown. If the value is missing, it will be nil and no error will be shown.

It can also support your own custom `Codable` types, like a sort direction:

    enum SortDirection: String, Codable {
        case ascending, descending
    }
    
    @QueryParameter("sortDirection") var sortDirection: SortDirection = .ascending

### Presence

HTTP allows query parameters with no value. These are intended to be treated as flags. For example, this is valid path and query string:

    /search?sortDirection=asc&minimumPrice=10&favorited

To access these kinds of query parameters, Meridian has a special value called `Present`.

    @QueryParameter("favorited") var favorited: Present

Using a non-optional value here means the flag must be present for the request to run. If the flag is optional, then it should be marked as optional with a question mark.

    @QueryParameter("favorited") var favorited: Present?

If it is optional, two helpers are available, `isPresent` and `isNotPresent`:

    func execute() throws -> Response {
        if favorited.isPresent {
            return "Showing favorites!"
        } else {
            return "Showing all items."
        }
    }
