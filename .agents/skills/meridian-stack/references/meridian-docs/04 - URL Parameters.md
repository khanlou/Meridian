# 04 - URL Parameters

URL parameters are slightly more complex than query parameters in Meridian. This is because they must be referenced in the path as well as in the responder itself. Here's a  mimimal example.

    struct InvoiceIDParameter: URLParameterKey {
        public typealias DecodeType = Int
    }
    
    extension ParameterKeys {
        var invoiceID: InvoiceIDParameter { .init() }
    }
    
    struct ShowInvoice: Responder {
        public init() { }
    
        @URLParameter(\.invoiceID) var id
        
        func execute() async throws {
            "Showing invoice with ID \(id)."
        }
    }

    Server(errorRenderer: IBErrorRenderer())
        .routes({
            
            ShowInvoice()
                .on("/invoices/\(\.invoiceID)")
            
        })
        .environmentObject(Database())
        .listen()

There are several moving parts here:

1. A simple struct that conforms to Meridian's `URLParameterKey` protocol tells Meridian what kind of value to decode. This could be a String, Int, Double, or any custom `LosslessStringConvertible`. You can also use phantom types here for added safety. That way, `ID<Invoice>` can't be confused with `ID<Client>`.
2. An extension on Meridian's `ParameterKeys` type. This allows for a terser syntax.
3. A `URLParameter` query item that uses keypath syntax to refer to the specific URL parameter key. Note that it doesn't need a type. It can infer that from the DecodeType.
4. A route path that includes the URL parameter key at the specific spot where it is expected. The key can be interpolated into the path at any point, and multiple keys can be interpolated into the path.

    This is also a valid path:

        .on(.post("/invoices/\(\.invoiceID)/update_state"))

URL parameters don't support optionality. If a Responder can sometimes require a URL parameter, and sometimes not, it might be better expressed as two Responders.

Note: URL parameter keys get their identity from the name of the type. This means that if you try to use two URL parameter keys (even at different keypaths) with the same type (`InvoiceIDParameter`, in the above case), they will collide and only one of them will come through. To avoid this, create a new type conforming to `URLParameterKey`, so that their identities will be different.
