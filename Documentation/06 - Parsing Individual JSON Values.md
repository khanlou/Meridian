# 06 - Parsing Individual JSON Values

If you want to parse the whole post body at once, `@JSONBody` is the property wrapper to use. If you just want a single value, but don't want to create a whole Codable type for that, you can use `@JSONValue`.

    struct EditTodo: Responder {
        
        @JSONValue("title") var title: String?
        @JSONValue("completed") var completed: Bool?
        @JSONValue("order") var order: Int?
        
        func execute() throws -> Response {
            if let newTitle = title {
                // update title
            }
            if let newCompleted = completed {
                // update completed
            }
            if let newOrder = order {
                // update order
            }
            return "Todo updated!"
        }
    }

`JSONValue` can accept a key path, including array indices, so `people[1].age` would be a keypath to the `age` of the first person of the array at the `people` key. `@JSONValue` supports any `Decodable` type. It also supports optionals (it will be nil if there is no value at that key, but will throw an error if there is a value but it doesn't decode successfully).