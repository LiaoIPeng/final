//
//  CameraPicker.swift
//  final
//
//  Created by 廖逸芃 on 2025/12/26.
//

import SwiftUI
import PhotosUI

struct CameraPicker: View {
  @Environment(\.dismiss) private var dismiss

  @Binding var image: UIImage?
  var onDismiss: () -> Void

  @State private var selectedItem: PhotosPickerItem?

  var body: some View {
    PhotosPicker(
      selection: $selectedItem,
      matching: .images,
      photoLibrary: .shared()
    ) {
      VStack(spacing: 12) {
        Image(systemName: "photo.on.rectangle")
          .font(.system(size: 40))
        Text("選擇相簿照片")
          .font(.headline)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    .onChange(of: selectedItem) { _, newItem in
      guard let newItem else {
        dismiss()
        onDismiss()
        return
      }

      Task {
        if let data = try? await newItem.loadTransferable(type: Data.self),
           let uiImage = UIImage(data: data) {
          image = uiImage
        }
        dismiss()
        onDismiss()
      }
    }
  }
}
