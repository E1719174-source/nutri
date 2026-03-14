import SwiftUI

struct AIConsultantView: View {
    var body: some View {
        VStack {
            Image(systemName: "bubble.left.and.bubble.right.fill")
                .resizable()
                .frame(width: 80, height: 80)
                .foregroundColor(.green)
                .padding()
            Text("AI 营养顾问")
                .font(.title)
                .fontWeight(.bold)
            Text("即将上线，敬请期待...")
                .foregroundColor(.gray)
        }
    }
}
