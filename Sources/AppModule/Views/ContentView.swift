import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            List {
                NavigationLink("Image Classification") {
                    EmptyView()
                }
                .disabled(true)
                NavigationLink("Object Detection") {
                    ObjectDetectionView()
                }
            }
            .navigationTitle("Core ML Demos")
            Text("Choose an item from the sidebar.")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
