//
//  OverviewStatRow.swift
//  final
//
//  Created by 廖逸芃 on 2025/12/26.
//


import SwiftUI
import PhotosUI
import UIKit

struct OverviewStatRow: View {
  let title: String
  let value: Int
  let systemImage: String

  var body: some View {
    HStack(spacing: 12) {
      Image(systemName: systemImage)
        .imageScale(.large)

      Text(title)
        .font(.headline)

      Spacer()

      Text("\(value)")
        .font(.headline)
    }
    .padding(.vertical, 4)
  }
}
