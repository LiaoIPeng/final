//
//  models.swift
//  final
//
//  Created by 廖逸芃 on 2025/12/26.
//

// MARK: - Model (Temp)
import SwiftUI
import PhotosUI
import UIKit

struct Project: Identifiable, Hashable {
  let id: UUID
  var name: String
  var category: String?
  var symbolName: String
  var createdAt: Date
  var isArchived: Bool
  var profit: Double?
  var records: [PhotoRecord]

  init(
    id: UUID = UUID(),
    name: String,
    category: String? = nil,
    symbolName: String = "leaf",
    createdAt: Date = Date(),
    isArchived: Bool = false,
    profit: Double? = nil,
    records: [PhotoRecord] = []
  ) {
    self.id = id
    self.name = name
    self.category = category
    self.symbolName = symbolName
    self.createdAt = createdAt
    self.isArchived = isArchived
    self.profit = profit
    self.records = records
  }
}

struct PhotoRecord: Identifiable, Hashable {
  let id: UUID
  var imageData: Data
  var shotDate: Date
  var createdAt: Date

  init(id: UUID = UUID(), imageData: Data, shotDate: Date, createdAt: Date = Date()) {
    self.id = id
    self.imageData = imageData
    self.shotDate = shotDate
    self.createdAt = createdAt
  }
}

struct DailyScore: Identifiable, Codable, Equatable {
  var id: UUID = UUID()
  var day: Date      // 當天 00:00
  var score: Int     // 1...10
}

enum SortOption: String, CaseIterable, Identifiable {
  case byCreatedDesc
  case byNameAsc
  case byCategoryAsc

  var id: String { rawValue }
}
