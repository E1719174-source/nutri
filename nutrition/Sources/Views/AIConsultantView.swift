import SwiftUI

struct AIConsultantView: View {
    @EnvironmentObject var viewModel: AIViewModel
    @State private var inputText = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header (if NavigationView title is not enough)
                // Navigation title "AI 营养顾问" handles it.
                
                ScrollView {
                    LazyVStack(spacing: 20) {
                        ForEach(viewModel.messages) { message in
                            HStack(alignment: .top, spacing: 10) {
                                if message.isUser {
                                    Spacer()
                                    Text(message.text)
                                        .padding()
                                        .background(Color.green)
                                        .foregroundColor(.white)
                                        .cornerRadius(15)
                                        .frame(maxWidth: UIScreen.main.bounds.width * 0.7, alignment: .trailing)
                                } else {
                                    // AI Avatar
                                    ZStack {
                                        Circle()
                                            .fill(Color.purple.opacity(0.1))
                                            .frame(width: 40, height: 40)
                                        Image(systemName: "brain.head.profile")
                                            .foregroundColor(.purple)
                                    }
                                    
                                    Text(message.text)
                                        .padding()
                                        .background(Color(.systemGray6))
                                        .foregroundColor(.black)
                                        .cornerRadius(15)
                                        .frame(maxWidth: UIScreen.main.bounds.width * 0.7, alignment: .leading)
                                    
                                    Spacer()
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        if viewModel.isThinking {
                            HStack {
                                ZStack {
                                    Circle()
                                        .fill(Color.purple.opacity(0.1))
                                        .frame(width: 40, height: 40)
                                    Image(systemName: "brain.head.profile")
                                        .foregroundColor(.purple)
                                }
                                Text("正在思考...")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .padding(.leading, 10)
                                Spacer()
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.top, 20)
                }
                
                // Input Area
                HStack {
                    TextField("问问AI营养师...", text: $inputText)
                        .padding(12)
                        .background(Color(.systemGray6))
                        .cornerRadius(25)
                        .disabled(viewModel.isThinking)
                    
                    Button(action: {
                        guard !inputText.isEmpty else { return }
                        viewModel.sendMessage(inputText)
                        inputText = ""
                    }) {
                        Image(systemName: "arrow.up.circle.fill")
                            .resizable()
                            .frame(width: 35, height: 35)
                            .foregroundColor(inputText.isEmpty ? .gray : .green)
                    }
                    .disabled(viewModel.isThinking || inputText.isEmpty)
                }
                .padding()
                .background(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: -2)
            }
            .navigationTitle("AI 营养顾问")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
