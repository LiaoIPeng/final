//
//  ContentView.swift
//  final
//
//  Created by 廖逸芃 on 2025/12/16.
//

import SwiftUI
import PhotosUI
import UIKit

// MARK: - Root Tab

struct ContentView: View {
  @State private var projects: [Project] = []

  var body: some View {
    TabView {
      HomeView(projects: $projects)
        .tabItem {
          Label("首頁", systemImage: "house")
        }

      DailyPickView(projects: $projects)
        .tabItem {
          Label("精選", systemImage: "sparkles")
        }

      ResultsView(projects: $projects)
        .tabItem {
          Label("成果", systemImage: "archivebox")
        }

      OverviewView(projects: $projects)
        .tabItem {
          Label("總覽", systemImage: "gear")
        }
    }
  }
}

// MARK: - Daily Pick

// MARK: - Overview

struct OverviewView: View {
  @Binding var projects: [Project]

  private var totalProjectsCount: Int {
    projects.count
  }

  private var activeProjectsCount: Int {
    projects.filter { !$0.isArchived }.count
  }

  private var archivedProjectsCount: Int {
    projects.filter { $0.isArchived }.count
  }

  private var totalProfitPositive: Double {
    // 只把正金額相加（通常來自已歸檔專案）
    projects
      .compactMap { $0.profit }
      .filter { $0 > 0 }
      .reduce(0, +)
  }

  private var totalLossPositive: Double {
    // 把負金額（支出/虧損）轉成正值再相加
    projects
      .compactMap { $0.profit }
      .filter { $0 < 0 }
      .map { abs($0) }
      .reduce(0, +)
  }

  var body: some View {
    NavigationStack {
      List {
        Section {
          OverviewStatRow(title: "專案總數", value: totalProjectsCount, systemImage: "square.grid.2x2")
          OverviewStatRow(title: "正在執行的專案", value: activeProjectsCount, systemImage: "leaf")
          OverviewStatRow(title: "已歸檔專案", value: archivedProjectsCount, systemImage: "archivebox")
        }

        Section("收益") {
          OverviewMoneyRow(title: "總獲利", amount: totalProfitPositive, systemImage: "plus.circle")
          OverviewMoneyRow(title: "總虧損", amount: totalLossPositive, systemImage: "minus.circle")
        }

        if projects.isEmpty {
          Section {
            ContentUnavailableView("開始你的第一個專案吧！", image: "dog")
              .frame(maxWidth: .infinity, minHeight: 140)
          }
        }
      }
      .navigationTitle("總覽")
    }
  }
}

private struct OverviewStatRow: View {
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

private struct OverviewMoneyRow: View {
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

struct DailyPickView: View {
  @Binding var projects: [Project]
  @State private var pickedProjectID: UUID? = nil
  @State private var selfScore: Int = 5

  private var activeProjects: [Project] {
    projects.filter { !$0.isArchived }
  }

  private var pickedProject: Project? {
    guard !activeProjects.isEmpty else { return nil }
    if let id = pickedProjectID, let p = activeProjects.first(where: { $0.id == id }) {
      return p
    }
    return nil
  }

  private var selfScoreBinding: Binding<Double> {
    Binding(
      get: { Double(selfScore) },
      set: { newValue in
        selfScore = Int(newValue.rounded())
      }
    )
  }

  var body: some View {
    NavigationStack {
      Group {
        if activeProjects.isEmpty {
          VStack(spacing: 10) {
            Text("目前沒有可顯示的專案")
              .font(.headline)

            if projects.isEmpty {
              Text("到『首頁』點右上角 ＋ 新增")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            } else {
              Text("你已把所有專案都移到成果（歸檔）")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
          }
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .padding()
        } else {
          VStack(spacing: 16) {
            if let project = pickedProject ?? activeProjects.randomElement() {
              NavigationLink {
                ProjectDetailView(projectID: project.id, projects: $projects)
              } label: {
                VStack(alignment: .leading, spacing: 12) {
                  // 如果這個專案有照片紀錄，就顯示最新的一張
                  if let latest = project.records.sorted(by: { $0.shotDate > $1.shotDate }).last,
                     let uiImage = UIImage(data: latest.imageData) {
                    Image(uiImage: uiImage)
                      .resizable()
                      .scaledToFill()
                      .frame(height: 220)
                      .clipped()
                      .clipShape(RoundedRectangle(cornerRadius: 16))
                  } else {
                    RoundedRectangle(cornerRadius: 16)
                      .fill(.secondary.opacity(0.15))
                      .frame(height: 220)
                      .overlay {
                        VStack(spacing: 8) {
                          Image(systemName: "leaf")
                            .font(.system(size: 40))
                            .foregroundStyle(.secondary)
                          Text("尚無照片紀錄")
                            .foregroundStyle(.secondary)
                        }
                      }
                  }

                  VStack(alignment: .leading, spacing: 6) {
                    Text(project.name)
                      .font(.title2)
                      .bold()

                    Text(project.category ?? "未分類")
                      .font(.subheadline)
                      .foregroundStyle(.secondary)
                  }
                  .padding(.horizontal, 4)
                }
              }
              .buttonStyle(.plain)
            }

            VStack(alignment: .leading, spacing: 10) {
              HStack {
                Text("給自己一個評分吧！")
                  .font(.headline)
                Spacer()
                Text("\(selfScore) 分")
                  .font(.headline)
              }

              Slider(value: selfScoreBinding, in: 1...10, step: 1)

              Text("1 分 = 還要再加油；10 分 = 很棒")
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .padding(16)
            .background(
              RoundedRectangle(cornerRadius: 16)
                .fill(.secondary.opacity(0.08))
            )

            Spacer(minLength: 0)
          }
          .padding()
        }
      }
      .navigationTitle("每日精選")
      .onAppear {
        // 第一次進來就抽一次
        if pickedProjectID == nil {
          pickedProjectID = activeProjects.randomElement()?.id
        }
      }
    }
  }
}

// MARK: - Home (Projects List)

/// NOTE: 目前先把 HomeView / Model 都放在同一個檔案，讓你先跑起來。
/// 你之後照你的規範把它們拆到：
/// - Views/Home/HomeView.swift
/// - Models/Project.swift
struct HomeView: View {
  @Binding var projects: [Project]

  @State private var searchText: String = ""
  @State private var sortOption: SortOption = .byCreatedDesc
  @State private var selectedCategory: String = "全部"

  private var activeProjects: [Project] {
    projects.filter { !$0.isArchived }
  }

  private var availableCategories: [String] {
    let cats = Set(activeProjects.compactMap { $0.category?.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty })
    return ["全部"] + cats.sorted()
  }

  private var filteredProjects: [Project] {
    let key = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

    let base = activeProjects
      .filter { p in
        // Category filter
        if selectedCategory != "全部" {
          if (p.category ?? "未分類") != selectedCategory { return false }
        }
        // Search filter
        guard !key.isEmpty else { return true }
        return p.name.localizedCaseInsensitiveContains(key)
        || (p.category?.localizedCaseInsensitiveContains(key) ?? false)
      }

    switch sortOption {
    case .byCreatedDesc:
      return base.sorted { $0.createdAt > $1.createdAt }
    case .byNameAsc:
      return base.sorted { $0.name.localizedCompare($1.name) == .orderedAscending }
    case .byCategoryAsc:
      return base.sorted { ($0.category ?? "未分類") < ($1.category ?? "未分類") }
    }
  }

  private var groupedProjects: [(category: String, items: [Project])] {
    // 如果選了特定分類，就只顯示那一組；如果選「全部」，同分類排在一起（用 Section）。
    let dict = Dictionary(grouping: filteredProjects, by: { $0.category ?? "未分類" })
    let orderedKeys = dict.keys.sorted()
    return orderedKeys.map { key in
      (category: key, items: dict[key] ?? [])
    }
  }

  var body: some View {
    NavigationStack {
      List {
        if filteredProjects.isEmpty {
          VStack(spacing: 12) {
            Text("目前尚無專案")
              .font(.headline)

            Text("請點右上角 ＋ 新增第一個專案")
              .font(.subheadline)
              .foregroundStyle(.secondary)
          }
          .frame(maxWidth: .infinity, minHeight: 120)
        } else {
          if selectedCategory == "全部" {
            ForEach(groupedProjects, id: \.category) { group in
              Section(group.category) {
                ForEach(group.items) { project in
                  NavigationLink {
                    ProjectDetailView(projectID: project.id, projects: $projects)
                  } label: {
                    ProjectRowView(project: project)
                  }
                }
                .onDelete { offsets in
                  deleteProjects(in: group.items, at: offsets)
                }
              }
            }
          } else {
            // 選了單一分類時，不用 Section 標題也可；這裡保留一個 Section 讓畫面一致
            Section(selectedCategory) {
              ForEach(filteredProjects) { project in
                NavigationLink {
                  ProjectDetailView(projectID: project.id, projects: $projects)
                } label: {
                  ProjectRowView(project: project)
                }
              }
              .onDelete(perform: deleteProjects)
            }
          }
        }
      }
      .navigationTitle("花園")
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Menu {
            Section("分類") {
              Picker("分類", selection: $selectedCategory) {
                ForEach(availableCategories, id: \.self) { cat in
                  Text(cat).tag(cat)
                }
              }
            }

            Section("排序") {
              Picker("排序", selection: $sortOption) {
                Text("建立時間（新→舊）").tag(SortOption.byCreatedDesc)
                Text("名稱（A→Z）").tag(SortOption.byNameAsc)
                Text("分類（A→Z）").tag(SortOption.byCategoryAsc)
              }
            }
          } label: {
            // 左上角顯示目前分類（你說分類要跟 row 分開並放左上）
            HStack(spacing: 6) {
              Image(systemName: "line.3.horizontal.decrease.circle")
              Text(selectedCategory)
                .lineLimit(1)
            }
          }
        }

        ToolbarItem(placement: .topBarTrailing) {
          Button {
            isPresentingAdd = true
          } label: {
            Image(systemName: "plus")
          }
          .accessibilityLabel("新增專案")
        }
      }
      .searchable(text: $searchText, prompt: "搜尋專案/分類")
      .sheet(isPresented: $isPresentingAdd) {
        AddProjectSheet { newProject in
          projects.insert(newProject, at: 0)
        }
      }
    }
  }

  private func deleteProjects(at offsets: IndexSet) {
    // 單一 Section（例如選特定分類）時可直接用 filteredProjects 對應回原陣列
    let idsToDelete = offsets.map { filteredProjects[$0].id }
    projects.removeAll { idsToDelete.contains($0.id) }
  }

  private func deleteProjects(in sectionItems: [Project], at offsets: IndexSet) {
    let idsToDelete = offsets.map { sectionItems[$0].id }
    projects.removeAll { idsToDelete.contains($0.id) }
  }

  @State private var isPresentingAdd: Bool = false
}

struct ProjectRowView: View {
  let project: Project

  var body: some View {
    HStack(spacing: 12) {
      Image(systemName: project.symbolName)
        .imageScale(.large)

      VStack(alignment: .leading, spacing: 4) {
        Text(project.name)
          .font(.headline)

        Text(project.createdAt, style: .date)
          .font(.caption)
          .foregroundStyle(.secondary)
      }
    }
    .padding(.vertical, 4)
  }
}

// MARK: - Add Project Sheet

struct AddProjectSheet: View {
  @Environment(\.dismiss) private var dismiss

  @State private var name: String = ""
  @State private var category: String = ""
  @State private var symbolName: String = "leaf"

  private let symbolOptions: [String] = ["leaf", "tree", "camera.macro"]

  var onAdd: (Project) -> Void

  var body: some View {
    NavigationStack {
      Form {
        Section("專案資訊") {
          TextField("專案名稱（必填）", text: $name)
          TextField("分類（可選）", text: $category)

          Picker("圖示", selection: $symbolName) {
            ForEach(symbolOptions, id: \.self) { symbol in
              Image(systemName: symbol)
                .tag(symbol)
            }
          }
        }
      }
      .navigationTitle("新增專案")
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("取消") { dismiss() }
        }
        ToolbarItem(placement: .confirmationAction) {
          Button("新增") {
            let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedCategory = category.trimmingCharacters(in: .whitespacesAndNewlines)
            let project = Project(
              name: trimmedName,
              category: trimmedCategory.isEmpty ? nil : trimmedCategory,
              symbolName: symbolName
            )
            onAdd(project)
            dismiss()
          }
          .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
      }
    }
  }
}

// MARK: - Project Detail (Photos + Shot Date)

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
      Button("開啟相機拍照") {
        isShowingCamera = true
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
      // 如果使用者取消而沒有儲存，保留預設即可；如要清除可在這裡做。
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

// MARK: - Results (Archived Projects)

struct ResultsView: View {
  @Binding var projects: [Project]

  private var archivedProjects: [Project] {
    projects.filter { $0.isArchived }
  }

  private var totalProfit: Double {
    archivedProjects.reduce(0) { partial, p in
      partial + (p.profit ?? 0)
    }
  }

  var body: some View {
    NavigationStack {
      List {
        Section {
          HStack {
            Text("＄＄＄")
              .font(.headline)
            Spacer()
            Text(totalProfit, format: .number)
              .font(.headline)
          }
        }

        if archivedProjects.isEmpty {
          VStack(spacing: 12) {
            Text("目前沒有成果")
              .font(.headline)
            Text("到專案詳細頁點『移到成果』即可歸檔")
              .font(.subheadline)
              .foregroundStyle(.secondary)
          }
          .frame(maxWidth: .infinity, minHeight: 160)
        } else {
          Section("已歸檔專案") {
            ForEach(archivedProjects) { project in
              NavigationLink {
                ProjectDetailView(projectID: project.id, projects: $projects)
              } label: {
                ResultsRowView(project: project)
              }
            }
          }
        }
      }
      .navigationTitle("成果")
    }
  }
}

struct ResultsRowView: View {
  let project: Project

  var body: some View {
    HStack(spacing: 12) {
      Image(systemName: project.symbolName)
        .imageScale(.large)

      VStack(alignment: .leading, spacing: 4) {
        Text(project.name)
          .font(.headline)

        Text(project.category ?? "未分類")
          .font(.caption)
          .foregroundStyle(.secondary)
      }

      Spacer()

      Text(project.profit ?? 0, format: .number)
        .font(.headline)
    }
    .padding(.vertical, 4)
  }
}

struct PhotoGridView: View {
  let records: [PhotoRecord]
  var onTap: (Int) -> Void

  private let columns: [GridItem] = [
    GridItem(.flexible(), spacing: 12),
    GridItem(.flexible(), spacing: 12)
  ]

  init(records: [PhotoRecord], onTap: @escaping (Int) -> Void = { _ in }) {
    self.records = records
    self.onTap = onTap
  }

  var body: some View {
    LazyVGrid(columns: columns, spacing: 12) {
      ForEach(Array(records.enumerated()), id: \.element.id) { index, record in
        Button {
          onTap(index)
        } label: {
          VStack(alignment: .leading, spacing: 6) {
            if let uiImage = UIImage(data: record.imageData) {
              Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(height: 140)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
              RoundedRectangle(cornerRadius: 12)
                .fill(.secondary.opacity(0.2))
                .frame(height: 140)
                .overlay {
                  Image(systemName: "photo")
                    .foregroundStyle(.secondary)
                }
            }

            Text("拍攝日期：\(record.shotDate.formatted(date: .abbreviated, time: .omitted))")
              .font(.caption)
              .foregroundStyle(.secondary)
          }
        }
        .buttonStyle(.plain)
      }
    }
  }
}

struct PhotoPagerView: View {
  @Environment(\.dismiss) private var dismiss

  let records: [PhotoRecord]
  let startIndex: Int

  @State private var selection: Int

  init(records: [PhotoRecord], startIndex: Int) {
    self.records = records
    self.startIndex = max(0, min(startIndex, records.count - 1))
    _selection = State(initialValue: max(0, min(startIndex, records.count - 1)))
  }

  var body: some View {
    NavigationStack {
      ZStack {
        Color.black.ignoresSafeArea()

        if records.isEmpty {
          ContentUnavailableView("沒有照片", image: "photo")
        } else {
          TabView(selection: $selection) {
            ForEach(records.indices, id: \.self) { idx in
              let record = records[idx]
              VStack(spacing: 12) {
                if let uiImage = UIImage(data: record.imageData) {
                  Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                  ContentUnavailableView("載入失敗", image: "photo")
                }

                Text("拍攝日期：\(record.shotDate.formatted(date: .abbreviated, time: .omitted))")
                  .font(.subheadline)
                  .foregroundStyle(.white.opacity(0.85))
                  .padding(.bottom, 16)
              }
              .padding(.horizontal)
              .tag(idx)
            }
          }
          .tabViewStyle(.page(indexDisplayMode: .automatic))
        }
      }
      .navigationTitle(records.isEmpty ? "" : "\(selection + 1)/\(records.count)")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button {
            dismiss()
          } label: {
            Image(systemName: "xmark")
              .foregroundStyle(.white)
          }
          .accessibilityLabel("關閉")
        }
      }
    }
  }
}

struct AddRecordConfirmSheet: View {
  @Environment(\.dismiss) private var dismiss

  @Binding var image: UIImage?
  @Binding var shotDate: Date

  var onSave: (UIImage, Date) -> Void
  var onCancel: () -> Void

  var body: some View {
    NavigationStack {
      VStack(spacing: 16) {
        if let img = image {
          Image(uiImage: img)
            .resizable()
            .scaledToFit()
            .frame(maxHeight: 260)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)
        } else {
          ContentUnavailableView("沒有選到照片", image: "leaf")
        }

        DatePicker("拍攝日期", selection: $shotDate, displayedComponents: .date)
          .datePickerStyle(.compact)
          .padding(.horizontal)

        Spacer(minLength: 0)
      }
      .padding(.top, 8)
      .navigationTitle("新增照片紀錄")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("取消") {
            onCancel()
            dismiss()
          }
        }
        ToolbarItem(placement: .confirmationAction) {
          Button("儲存") {
            guard let img = image else { return }
            onSave(img, shotDate)
            dismiss()
          }
          .disabled(image == nil)
        }
      }
    }
  }
}

// MARK: - Camera Picker (UIKit)

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

// MARK: - Model (Temp)

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

enum SortOption: String, CaseIterable, Identifiable {
  case byCreatedDesc
  case byNameAsc
  case byCategoryAsc

  var id: String { rawValue }
}

#Preview {
  ContentView()
}
