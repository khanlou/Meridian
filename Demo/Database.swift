//
//  Database.swift
//  Meridian
//
//  Created by Soroush Khanlou on 8/29/20.
//

import Foundation
import Meridian

struct Todo: Codable {
    var id: UUID
    var title: String 
    var completed: Bool = false
    var order: Int

    var url: String {
        return "https://meridian-demo.herokuapp.com/todos/\(id)"
    }

    enum CodingKeys: String, CodingKey {
        case id, title, completed, url, order
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = UUID()
        title = try container.decode(String.self, forKey: .title)
        self.order = try container.decodeIfPresent(Int.self, forKey: .order) ?? -1
    }

    init(title: String, completed: Bool) {
        self.id = UUID()
        self.title = title
        self.completed = completed
        self.order = -1
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(completed, forKey: .completed)
        try container.encode(url, forKey: .url)
        try container.encode(order, forKey: .order)
    }
}

final class Database {
    var todos: [Todo]
    
    init() {
        todos = []
    }
}
