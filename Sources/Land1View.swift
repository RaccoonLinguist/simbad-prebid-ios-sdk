import SwiftUI

struct Land1View: View {
    var body: some View {
        VStack(spacing: 0) {
            Text("Land1")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Spacer()
                .frame(height: 30)
            
            Text("land 1 text")
            
            Spacer() 
        }
        .padding()
    }
}