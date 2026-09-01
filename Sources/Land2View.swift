import SwiftUI

struct Land2View: View {
    var body: some View {
        VStack(spacing: 0) {
            Text("Land2")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Spacer()
                .frame(height: 30)
            
            Text("land 2 text")
            
            Spacer()
        }
        .padding()
    }
}