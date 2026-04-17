# 13 - Errors

Errors are an important part of any server application, and Meridian's errors are first-class. The property wrappers throw specific errors one of their preconditions is not met. For example, the `@QueryParameter` property wrapper can throw two errors:

* `MissingQueryParameterError` – if the query parameter is expected, but not present.

* `QueryParameterDecodingError` – If the query paramater's value is present, but can not decode to the expected type.

Other property wrappers have errors specific to their implementations.

The errors that these property wrappers throw all conform to a protocol called `ReportableError`. A reportable error has two parts:

    public protocol ReportableError: Error {
        var statusCode: StatusCode { get }
        var message: String { get }
    }

Both have defaults: the status code defaults to 500 Internal Server Error, and the message defaults to "An error occurred."

To create your own error, conform to the protocol and override the variables as needed.

    struct MissingAuth: ReportableError {
        let statusCode: StatusCode = .forbidden
        let message: String = "This request requires an auth token."
    }

You can throw this error from an extractor for a [custom property wrapper](10 - Custom Property Wrappers.md) or from the `execute()` method of any Responder.

The error will be rendered by an [ErrorRenderer](14 - Error Renderers.md), which is discussed in the next section.
