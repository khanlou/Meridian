# 19 - Deploying to Heroku

Deploying Meridian apps to Heroku is very similar to other Swift on the server frameworks. You need 3 things.

1. Set your app's buildpack to [https://github.com/vapor-community/heroku-buildpack/](https://github.com/vapor-community/heroku-buildpack/). This can be done in your app's settings or via the Heroku CLI.
2. Create a root level file called `Procfile` with the contents:

        web: App --host 0.0.0.0 --port $PORT
    
    If your application is called something other than `App`, use that name. 
3. Ensure your database URL is being accessed by the environment variable named `DATABASE_URL`. You can access this in Swift like so:

        ProcessInfo.processInfo.environment["DATABASE_URL"]

Lastly, if you are using `swift-backtrace` to log any crashes, you should set the `SWIFT_BUILD_FLAGS` config variable (on Heroku) to `-Xswiftc -g`. This will ensure that debug symbols are emitted in the binary and can be read by Backtrace.
