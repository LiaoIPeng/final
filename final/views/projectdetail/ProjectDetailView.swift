//
//  ProjectDetailView.swift
//  final
//
//  Created by 廖逸芃 on 2025/12/26.
//


import SwiftUI
import PhotosUI
import UIKit

struct ProjectDetailView: View {
  @State private var isShowingArchivePrompt: Bool = false
  @State private var profitText: String = ""
  @State private var archiveErrorMessage: String? = nil
  let projectID: UUID
  @Binding var projects: [Project]

  @State private var isShowingAddMenu: Bool = false
  @State private var isShowingPhotosPicker: Bool = false
  @State private var isShowingCamera: Bool = false

  @State private var pickedItem: PhotosPickerItem? = nil
  @State private var pendingImage: UIImage? = nil
  @State private var pendingShotDate: Date = Date()
  @State private var isShowingConfirmSheet: Bool = false

  @State private var isShowingPhotoViewer: Bool = false
  @State private var photoViewerIndex: Int = 0

  private var projectIndex: Int? {
    projects.firstIndex(where: { $0.id == projectID })
  }

  private var currentProject: Project? {
    guard let idx = projectIndex, projects.indices.contains(idx) else { return nil }
    return projects[idx]
  }

  private var projectName: String {
    currentProject?.name ?? "專案"
  }

  private func sortedRecords(for project: Project) -> [PhotoRecord] {
    let recs = project.records
    return recs.sorted { (lhs, rhs) in
      lhs.shotDate > rhs.shotDate
    }
  }

  var body: some View {
    Group {
      if let project = currentProject {
        let records = sortedRecords(for: project)
        ScrollView {
          if records.isEmpty {
            VStack(spacing: 12) {
              Text("尚無照片紀錄")
                .font(.headline)
              Text("點右上角 ＋ 新增照片")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, minHeight: 160)
            .padding(.top, 24)
          } else {
            PhotoGridView(records: records) { tappedIndex in
              photoViewerIndex = tappedIndex
              isShowingPhotoViewer = true
            }
            .padding(.horizontal)
            .padding(.top, 12)
          }
        }
      } else {
        ContentUnavailableView("找不到專案", image: "leaf")
      }
    }
    .navigationTitle(projectName)
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        Button {
          isShowingAddMenu = true
        } label: {
          Image(systemName: "plus")
        }
        .accessibilityLabel("新增照片紀錄")
      }
      ToolbarItem(placement: .topBarLeading) {
        if let project = currentProject, !project.isArchived {
          Button {
            profitText = ""
            archiveErrorMessage = nil
            isShowingArchivePrompt = true
          } label: {
            Label("移到成果", systemImage: "archivebox")
          }
        }
      }
    }
    .alert("移到成果（歸檔）", isPresented: $isShowingArchivePrompt) {
      TextField("透過植物賺了多少錢", text: $profitText)
        .keyboardType(.numbersAndPunctuation)

      Button("確認") {
        guard let idx = projectIndex else { return }
        let trimmed = profitText.trimmingCharacters(in: .whitespacesAndNewlines)
          .replacingOccurrences(of: ",", with: "")

        guard let value = Double(trimmed) else {
          archiveErrorMessage = "請輸入有效的數字（可為負數）"
          // 重新打開同一個輸入框
          isShowingArchivePrompt = true
          return
        }

        projects[idx].isArchived = true
        projects[idx].profit = value
      }

      Button("取消", role: .cancel) {}
    } message: {
      if let msg = archiveErrorMessage {
        Text(msg)
      } else {
        Text("這次賺了多少錢（可為負數）")
      }
    }
    .confirmationDialog("新增照片", isPresented: $isShowingAddMenu, titleVisibility: .visible) {
      Button("從相簿選取") {
        isShowingPhotosPicker = true
      }
      
      Button("取消", role: .cancel) {}
    }
    .photosPicker(isPresented: $isShowingPhotosPicker, selection: $pickedItem, matching: .images)
    .onChange(of: pickedItem) { _, newValue in
      guard let item = newValue else { return }
      Task {
        if let data = try? await item.loadTransferable(type: Data.self),
           let uiImage = UIImage(data: data) {
          await MainActor.run {
            pendingImage = uiImage
            pendingShotDate = Date()
            isShowingConfirmSheet = true
          }
        }
      }
    }
    .sheet(isPresented: $isShowingCamera) {
      CameraPicker(image: $pendingImage) {
        // onDismiss
        if pendingImage != nil {
          pendingShotDate = Date()
          isShowingConfirmSheet = true
        }
      }
      .ignoresSafeArea()
    }
    .sheet(isPresented: $isShowingConfirmSheet, onDismiss: {
      // 如果使用者取消而沒有儲存，保留預設即可
    }) {
      AddRecordConfirmSheet(
        image: $pendingImage,
        shotDate: $pendingShotDate,
        onSave: { uiImage, shotDate in
          guard let idx = projectIndex else { return }
          guard let data = uiImage.jpegData(compressionQuality: 0.9) else { return }
          var project = projects[idx]
          let record = PhotoRecord(imageData: data, shotDate: shotDate)
          project.records.append(record)
          projects[idx] = project
          // reset
          pendingImage = nil
          pickedItem = nil
        },
        onCancel: {
          pendingImage = nil
          pickedItem = nil
        }
      )
      .presentationDetents([.medium, .large])
    }
    .fullScreenCover(isPresented: $isShowingPhotoViewer) {
      if let project = currentProject {
        PhotoPagerView(records: sortedRecords(for: project), startIndex: photoViewerIndex)
      } else {
        ContentUnavailableView("找不到照片", image: "photo")
      }
    }
  }
}
