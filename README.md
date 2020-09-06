# Meridian

Meridian is a web server written in Swift that lets you write your endpoints in a declarative way.

Here is an example endpoint:

```
extension URLParameters {
    static let id = URLParameter()
}

struct SampleEndpoint: Route {
  
    static let path: RouteMatcher = "/api/users/\(\.id))/followers"
  
    @QueryParameter("sort_direction") var sortDirection: SortDirection
  
    @URLParameter(\.id) var userID
    
    @EnivronmentObject var database: Database
    
    func body() throws {
        JSON(database.fetchFollowers(of: userID, sortDirection: sortDirection))
    }
  
}
```
