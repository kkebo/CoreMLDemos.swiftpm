import SwiftUI

enum Demo {
    case imageClassification
    case objectDetection
}

extension Demo: CaseIterable {}

extension Demo: Identifiable {
    var id: Self { self }
}

extension Demo: CustomStringConvertible {
    var description: String {
        switch self {
        case .imageClassification: "Image Classification"
        case .objectDetection: "Object Detection"
        }
    }
}

struct ContentView {
    @State private var item: Demo?
}

extension ContentView: View {
    var body: some View {
        NavigationSplitView {
            List(Demo.allCases, selection: self.$item) {
                Text(LocalizedStringKey($0.description))
            }
            .navigationTitle("Core ML Demos")
        } detail: {
            switch self.item {
            case .imageClassification: Text("Not implemented.")
            case .objectDetection: ObjectDetectionView()
            case .none: Text("Choose an item from the sidebar.")
            }
        }
    }
}

#Preview {
    ContentView()
}
