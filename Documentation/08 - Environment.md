# 08 - Environment

If you are familiar with SwiftUI's environment, you'll feel right at home with Meridian's. 

There are two ways to store values into Meridian's environment.

### Environment Objects

First, you can store objects (reference types) by their type. 

For example, if you have a database:

    final class Database {
        // interesting data in here
    }

You can add this to your `Server`.

    Server(errorRenderer: BasicErrorRenderer())
        .register({
            LogInRoute()
                .on(.get("/login"))
        })
        .environmentObject(Database())
        .listen()

You can chain as many `.environmentObject` modifiers as you need. Objects using this approach are keyed off of their type, so there can only ever be one of each type in the environment.

To get access to this database, you can use the `@EnvironmentObject` property wrapper.

    @EnvironmentObject var database: Database

`@EnvironmentObject` uses the type of the variable to find the instance of the object.

### Keyed Environment Values

If the object you'd like to store in the environment is a value type, or you need multiple instances for a given type (like DateFormatters, for instance), you can set up keys. This works very similarly to SwiftUI.

    struct ShortDateFormatterKey: EnvironmentKey {
        static var defaultValue: DateFormatter = {
            let f = DateFormatter()
            f.timeStyle = .none
            f.dateStyle = .short
            return f
        }()
    }

Using an immediately-executed closure ensures that the `defaultValue` is only ever instantiated once.

    extension EnvironmentValues {
        var shortDateFormatter: DateFormatter {
            get {
                self[ShortDateFormatterKey.self]
            }
            set {
                self[ShortDateFormatterKey.self] = newValue
            }
        }
    }

This can be used with the `@Environment` property wrapper:

    @Environment(\.shortDateFormatter) var shortDateFormatter

