//
//  Localstore.swift
//  final
//
//  Created by 廖逸芃 on 2025/12/26.
//
import Foundation

enum LocalStore {
  private static func fileURL(_ name: String) throws -> URL {
    let dir = try FileManager.default.url(for: .documentDirectory,
                                          in: .userDomainMask,
                                          appropriateFor: nil,
                                          create: true)
    return dir.appendingPathComponent(name)
  }

  static func load<T: Decodable>(_ type: T.Type, from filename: String) -> T? {
    do {
      let url = try fileURL(filename)
      let data = try Data(contentsOf: url)
      return try JSONDecoder().decode(T.self, from: data)
    } catch {
      return nil
    }
  }

  static func save<T: Encodable>(_ value: T, to filename: String) {
    do {
      let url = try fileURL(filename)
      let data = try JSONEncoder().encode(value)
      try data.write(to: url, options: [.atomic])
    } catch {
      // print("Save error:", error)
    }
  }
}
