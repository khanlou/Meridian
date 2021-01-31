# 09 - Headers, Paths, and Methods

You typically won't need to access the headers, path, or HTTP method of a request, since those things will be handled before you see the request. However, in case you do, there are property wrappers to access that data.

### Headers

To access a specific header, use the `@Header` property wrapper:

    @Header("X-Auth-Token") var authToken

The variable `authToken` will be of type string. If the header is not present, it will contain an empty string.

### Path

To get the path of the current request, you can use the `@Path` property wrapper:

    @Path var path

The variable `path` will be of type string. It includes a leading slash `/`.

### Method

To get the http method of the current request, you can use the `@RequestMethod ` property wrapper:

    @RequestMethod var method

The variable `method` will have the type `HTTPMethod`, which is one of Meridian's types.
