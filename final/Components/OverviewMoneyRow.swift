//
//  OverviewMoneyRow.swift
//  final
//
//  Created by 廖逸芃 on 2025/12/26.
//


import SwiftUI
import PhotosUI
import UIKit

struct OverviewMoneyRow: View {
  let title: String
  let amount: Double
  let systemImage: String

  var body: some View {
    HStack(spacing: 12) {
      Image(systemName: systemImage)
        .imageScale(.large)

      Text(title)
        .font(.headline)

      Spacer()

      Text(amount, format: .number)
        .font(.headline)
    }
    .padding(.vertical, 4)
  }
}
