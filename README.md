# Meridian

Meridian is a web server written in Swift that lets you write your endpoints in a declarative way.

Here is an example endpoint:

```swift
struct SampleEndpoint: Responder {
  
    @QueryParameter("sort_direction") var sortDirection: SortDirection = .ascending
  
    @URLParameter(\.id) var userID
    
    @EnvironmentObject var database: Database
    
    func execute() throws {
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

## Installation

Meridian uses Swift Package Manager for installation. 

Add Meridian as a dependency for your package:

    .package(url: "https://github.com/khanlou/Meridian.git", from: "0.2.5"),

The version should be the latest tag on GitHub.

Add Meridian as a dependency for your target as well:

    .product(name: "Meridian", package: "Meridian"),

## Documentation

Full documentation can be found in the [Documentation](Documentation/) folder.
