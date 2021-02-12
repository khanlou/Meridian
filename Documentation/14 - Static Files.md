# 13 - Static Files

Your app may need to serve static files, like JavaScript, CSS, or images. Meridian has a Route that can help you with this. Meridian can serve any resources that are in your module.

To enable this, you need to tell your Package.swift that you have static resources to include include in your final bundle. You can do this by updating your App target (not your library target) with 

        targets: [
            .target(name: "App", dependencies: ["MyFirstApp"], resources: [.process("Static")]), // => files in the Static folder will be included in the bundle
            .target(name: "MyFirstApp", dependencies: [
                .product(name: "Meridian", package: "Meridian"),
                .product(name: "Backtrace", package: "swift-backtrace"),
            ]),

(Note: you must use `.process`. `.copy` will not work.)

Now, you can place your static files in the Static folder. Your directory structure should look like this:

    📁 Root
        📄 Package.swift
        📄 Package.resolved
        📁 Sources
            📁 App
                📄 main.swift
                📁 Static
                    📄 styles.css
                    📄 index.js
            📁 MyFirstApp
                📄 HelloWorld.swift

Once that's done, the `BundledFiles` route can be included in your Path.

    // main.swift (in App target)
    
    import Meridian
    import MyFirstApp

    Server(errorRenderer: BasicErrorRenderer())
        .register({
        
            HelloWorld()
                .on(.root)
        
            BundledFiles(bundle: .module)

        })
        .listen()

(You need to explicitly pass the bundle the files are in so that Meridian looks for the files in the correct place.)

The URL `http://localhost:3000/styles.css` should now deliver your CSS file.

When it comes to deployment, the [default Heroku buildpack](https://github.com/vapor-community/heroku-buildpack) should copy the resources into the right place.