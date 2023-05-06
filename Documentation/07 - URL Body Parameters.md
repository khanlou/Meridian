# 07 - URL Body Parameters

HTML forms will encode their fields into the body using URL encoding. This looks like a query parameter string, but is encoded into the body.

Here's how you can extract URL body parameters:

    struct HelloWorld: Responder {
    
        @URLBodyParameter("name") var name: String
    
        func execute() async throws -> Response {
            "Hello, \(name)!"
        }
    }

Using this property wrapper requires a `Content-Type` of `application/x-www-form-urlencoded`.

### Optionality

If the URL body parameter is not required, you can change its type to be an optional:

    @URLBodyParameter("name") var name: String?

You will have to handle this optionality in your `execute()` function:

    func execute() throws -> Response {
        "Hello, \(name ?? "world")!"
    }

For simple behavior like providing a default, you can do this inline. 

    @URLBodyParameter("name") var name: String = "world"

### Codable

URL body parameters support `Codable`. This can be something as simple as an integer or double:

    @URLBodyParameter("minimumPrice") var name: Double?

For this example, even though the value is optional, if the value cannot be decoded into a `Double`, an error will be shown. If the value is missing, it will be nil and no error will be shown.

It can also support your own custom `Codable` types.

### Presence

HTTP allows URL-encoded body parameters to have no value. These are intended to be treated as flags. 

To access these kinds of URL body parameters, Meridian has a special value called `Present`.

    @URLBodyParameter("favorited") var favorited: Present

Using a non-optional value here means the flag must be present for the request to run. If the flag is optional, then it should be marked as optional with a question mark.

    @URLBodyParameter("favorited") var favorited: Present?

If it is optional, two helpers are available, `isPresent` and `isNotPresent`:

    func execute() async throws -> Response {
        if favorited.isPresent {
            return "Showing favorites!"
        } else {
            return "Showing all items."
        }
    }
