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
        case .imageClassification: return "Image Classification"
        case .objectDetection: return "Object Detection"
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
                NavigationLink(LocalizedStringKey($0.description), value: $0)
            }
            .navigationTitle("Core ML Demos")
        } detail: {
            switch self.item {
            case .imageClassification: EmptyView()
            case .objectDetection: ObjectDetectionView()
            case .none: Text("Choose an item from the sidebar.")
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
