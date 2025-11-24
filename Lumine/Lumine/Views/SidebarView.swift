import SwiftUI

struct SidebarView: View {
  @Bindable var viewModel: MainViewModel

  var body: some View {
    List(selection: Binding<SidebarCategory?>(
      get: { viewModel.selectedCategory },
      set: { newValue in
        if let category = newValue {
          viewModel.send(.viewAction(.didSelectCategory(category)))
        }
      }
    )) {
      Section("Library") {
        ForEach(SidebarCategory.allCases) { category in
          Button {
            viewModel.send(.viewAction(.didSelectCategory(category)))
          } label: {
            Label(category.rawValue, systemImage: category.iconName)
          }
          .foregroundStyle(.primary)
          .listRowBackground(
              viewModel.selectedCategory == category ? Color.accentColor.opacity(0.2) : nil
          )
        }
      }

      Section("Settings") {
        Picker("Seek Interval", selection: Binding(
          get: { viewModel.seekInterval },
          set: { viewModel.send(.viewAction(.didChangeSeekInterval($0))) }
        )) {
          Text("5s").tag(5.0)
          Text("10s").tag(10.0)
          Text("15s").tag(15.0)
          Text("30s").tag(30.0)
          Text("60s").tag(60.0)
        }
      }
    }
    .listStyle(.sidebar)
    .background(.ultraThinMaterial) // Liquid Glass effect base
    .navigationTitle("Lumine")
  }
}
