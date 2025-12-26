//
//  CameraPicker.swift
//  final
//
//  Created by 廖逸芃 on 2025/12/26.
//


import SwiftUI
import PhotosUI
import UIKit

struct CameraPicker: UIViewControllerRepresentable {
  @Environment(\.dismiss) private var dismiss

  @Binding var image: UIImage?
  var onDismiss: () -> Void

  func makeUIViewController(context: Context) -> UIImagePickerController {
    let picker = UIImagePickerController()
    picker.sourceType = .camera
    picker.delegate = context.coordinator
    picker.allowsEditing = false
    return picker
  }

  func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

  func makeCoordinator() -> Coordinator {
    Coordinator(parent: self)
  }

  final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    let parent: CameraPicker

    init(parent: CameraPicker) {
      self.parent = parent
    }

    func imagePickerController(
      _ picker: UIImagePickerController,
      didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]
    ) {
      if let img = info[.originalImage] as? UIImage {
        parent.image = img
      }
      parent.dismiss()
      parent.onDismiss()
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
      parent.dismiss()
      parent.onDismiss()
    }
  }
}