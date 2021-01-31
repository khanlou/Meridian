# 05 - Parsing JSON Bodies

Meridian includes first class support for JSON.

To decode a JSON body, create a codable type and use the `@JSONBody` property wrapper:
    
    struct Trip: Codable {
        let departure: String
        let destination: Int
        let date: Date
    }
    
    struct CreateDateRoute: Responder {
        
        @JSONBody var trip: Trip
        
        public func execute() throws -> Response {
            "Flying from \(trip.departure) to \(trip.destination)!"
        }
    }

Meridian will use the type of the `trip` variable, in this case `Trip` to decode the incoming request's post body. This value can be optional, which will be nil in the case that the post body is empty. However, if the value does not decode, Meridian will respond with an error, even if the type is optional.

Using `JSONBody` requires an incoming `Content-Type` of `application/json`. Without this, Meridian will respond with an error.

Assuming you have a custom JSONDecoder available at `JSONDecoder.myCustomJSONDecoder`, you can use it like so:

    @JSONBody(.myCustomJSONDecoder) var trip: Trip