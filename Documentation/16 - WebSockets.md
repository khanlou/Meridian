# 16 - WebSockets

WebSockets allow you to have a two-way connection with a client, allowing you to receive data as well as pushing it to the client.

Once connected to the WebSocket, you can recieve messages via an AsyncSequence. When the WebSocket is closed for any reason, the AsyncSequence ends.

	struct ChatSocket: WebSocketResponder {
	
	    @Environment var database: Database
	    
	    @URLParameter(\.userID) var userID
	    
	    // not required, defaults to `true`
	    func shouldConnect() async throws -> Bool {
	        try await database.containsUser(withID: userID)
	    }
	    
	    func connected(to webSocket: WebSocket) async throws {
	
	        print("Connected to websocket")
	
	        for try await message in messages {
	            print("A new message arrived: \(message)")
	            websocket.send(text: "Thank you for your message.")
	        }
	
	        print("Websocket closed!")
	    }
	}

WebSocket responders can use any part of the environment, including query parameters, url parameters, and environment values and objects.

`WebSocket` objects can be stored and passed around so that other parts of your application can send values to it.

Middleware is currently not compatible with WebSockets.