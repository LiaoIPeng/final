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
  @State private var dailyScores: [DailyScore] = []

  var body: some View {
    TabView {
      HomeView(projects: $projects)
        .tabItem { Label("首頁", systemImage: "house") }

      DailyPickView(projects: $projects, dailyScores: $dailyScores)
        .tabItem { Label("精選", systemImage: "sparkles") }

      ResultsView(projects: $projects)
        .tabItem { Label("成果", systemImage: "archivebox") }

      OverviewView(projects: $projects, dailyScores: $dailyScores)
        .tabItem { Label("總覽", systemImage: "gear") }
    }
    .onAppear {
      if let p: [Project] = LocalStore.load([Project].self, from: "projects.json") {
        projects = p
      }
      if let s: [DailyScore] = LocalStore.load([DailyScore].self, from: "dailyScores.json") {
        dailyScores = s
      }
    }
    .onChange(of: projects) { _, newValue in
      LocalStore.save(newValue, to: "projects.json")
    }
    .onChange(of: dailyScores) { _, newValue in
      LocalStore.save(newValue, to: "dailyScores.json")
    }
  }
}

// MARK: - Home (Projects List)
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

// MARK: - Daily Pick
struct DailyPickView: View {
  @Binding var projects: [Project]
  @Binding var dailyScores: [DailyScore]

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
      set: { newValue in selfScore = Int(newValue.rounded()) }
    )
  }

  private var todayStart: Date {
    Calendar.current.startOfDay(for: Date())
  }

  private var todaySavedScore: DailyScore? {
    dailyScores.first(where: { Calendar.current.isDate($0.day, inSameDayAs: todayStart) })
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
                  if let latest = project.records.sorted(by: { $0.shotDate > $1.shotDate }).first,
                     let uiImage = ImageStore.loadUIImage(filename: latest.imageFilename) {

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

              HStack(spacing: 10) {
                if let saved = todaySavedScore {
                  Text("今天已紀錄：\(saved.score) 分")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                } else {
                  Text("今天尚未紀錄")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                  saveTodayScore()
                } label: {
                  Text(todaySavedScore == nil ? "儲存今日評分" : "更新今日評分")
                    .font(.subheadline)
                    .bold()
                }
                .buttonStyle(.borderedProminent)
              }
              .padding(.top, 4)
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
        if pickedProjectID == nil {
          pickedProjectID = activeProjects.randomElement()?.id
        }
        if let saved = todaySavedScore {
          selfScore = saved.score
        }
      }
    }
  }

  private func saveTodayScore() {
    let d = todayStart
    if let idx = dailyScores.firstIndex(where: { Calendar.current.isDate($0.day, inSameDayAs: d) }) {
      dailyScores[idx].score = selfScore
    } else {
      dailyScores.append(DailyScore(day: d, score: selfScore))
    }
    dailyScores.sort { $0.day > $1.day }
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
            .onDelete(perform: deleteArchived)
          }
        }
      }
      .navigationTitle("成果")
    }
  }

  private func deleteArchived(at offsets: IndexSet) {
    let idsToDelete = offsets.map { archivedProjects[$0].id }
    projects.removeAll { idsToDelete.contains($0.id) }
  }
}

// MARK: - Overview

struct OverviewView: View {
  @Binding var projects: [Project]
  @Binding var dailyScores: [DailyScore]

  private var totalProjectsCount: Int { projects.count }
  private var activeProjectsCount: Int { projects.filter { !$0.isArchived }.count }
  private var archivedProjectsCount: Int { projects.filter { $0.isArchived }.count }

  private var totalProfitPositive: Double {
    projects.compactMap { $0.profit }.filter { $0 > 0 }.reduce(0, +)
  }

  private var totalLossPositive: Double {
    projects.compactMap { $0.profit }.filter { $0 < 0 }.map { abs($0) }.reduce(0, +)
  }

  private var dailyScoreCount: Int { dailyScores.count }

  private var dailyScoreAverage: Double {
    guard !dailyScores.isEmpty else { return 0 }
    let total = dailyScores.reduce(0) { $0 + $1.score }
    return Double(total) / Double(dailyScores.count)
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

        Section("每日評分") {
          OverviewMoneyRow(title: "平均分數", amount: dailyScoreAverage, systemImage: "star.circle")
          OverviewStatRow(title: "累計天數", value: dailyScoreCount, systemImage: "calendar")
        }
      }
      .navigationTitle("總覽")
    }
  }
}

#Preview {
  ContentView()
}
