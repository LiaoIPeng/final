//
//  ImageStore.swift
//  final
//
//  Created by 廖逸芃 on 2025/12/26.
//
import Foundation
import UIKit

enum ImageStore {
  static func saveJPG(_ data: Data) throws -> String {
    let docs = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
    let dir = docs.appendingPathComponent("Photos", isDirectory: true)
    if !FileManager.default.fileExists(atPath: dir.path) {
      try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    }
    let filename = UUID().uuidString + ".jpg"
    try data.write(to: dir.appendingPathComponent(filename), options: [.atomic])
    return filename
  }

  static func loadUIImage(filename: String) -> UIImage? {
    do {
      let docs = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
      let url = docs.appendingPathComponent("Photos").appendingPathComponent(filename)
      return UIImage(contentsOfFile: url.path)
    } catch { return nil }
  }
}
