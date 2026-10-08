import SwiftUI

/// The root of the app: three tabs, plus the Add Food sheet.
struct ContentView: View {
    @State private var addFoodRequest: AddFoodRequest?

    var body: some View {
        TabView {
            Tab("Today", systemImage: "calendar") {
                TodayView { meal in
                    addFoodRequest = AddFoodRequest(meal: meal)
                }
            }
            Tab("Foods", systemImage: "magnifyingglass") {
                FoodsPlaceholderView()
            }
            Tab("Settings", systemImage: "gearshape") {
                SettingsView()
            }
        }
        .tint(AppColor.accent)
        .sheet(item: $addFoodRequest) { request in
            AddFoodSheet(request: request)
        }
    }
}

#Preview {
    ContentView()
}
