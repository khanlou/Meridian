# Meridian

Meridian is a web server written in Swift that lets you write your endpoints in a declarative way.

Here is an example endpoint:

```swift

struct SampleEndpoint: Responder {
  
    @QueryParameter("sort_direction") var sortDirection: SortDirection
  
    @URLParameter(\.id) var userID
    
    @EnivronmentObject var database: Database
    
    func body() throws {
        JSON(database.fetchFollowers(of: userID, sortDirection: sortDirection))
    }
  
}

Server(errorRenderer: BasicErrorRenderer())
    .register {

        SampleEndpoint()
            .on("/api/users/\(\.id))/followers")

    }
    .environmentObject(Database())
    .listen()

```
