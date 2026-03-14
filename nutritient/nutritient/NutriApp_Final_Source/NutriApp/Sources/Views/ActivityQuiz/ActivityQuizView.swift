import SwiftUI

struct ActivityQuizView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var selectedActivityLevel: ActivityLevel // Result binds back to parent
    
    @State private var currentQuestionIndex = 0
    // answers store score (1-4). 0 means skipped/unanswered
    @State private var answers: [Int] = Array(repeating: 0, count: 20)
    @State private var isAnalyzing = false
    @State private var analysisResult: ActivityLevel?
    @State private var showResult = false
    
    // 20 Questions
    struct Question {
        let text: String
        let options: [String]
    }
    
    let questions: [Question] = [
        Question(text: "您的工作性质主要是？", options: ["一直坐着 (如程序员)", "偶尔走动 (如教师)", "经常走动 (如服务员)", "重体力劳动 (如建筑工人)"]),
        Question(text: "您每天上下班的通勤方式？", options: ["开车/打车", "公共交通 (少步行)", "公共交通 (多步行)", "骑车/步行"]),
        Question(text: "您每天平均步数大约是多少？", options: ["< 3000步", "3000-6000步", "6000-10000步", "> 10000步"]),
        Question(text: "您每周进行有氧运动 (如跑步、游泳) 的频率？", options: ["从不", "1-2次", "3-4次", "5次以上"]),
        Question(text: "每次有氧运动持续时间？", options: ["无", "< 30分钟", "30-60分钟", "> 60分钟"]),
        Question(text: "您每周进行力量训练 (如举铁) 的频率？", options: ["从不", "1-2次", "3-4次", "5次以上"]),
        Question(text: "您在工作/学习时感到身体疲劳的程度？", options: ["完全不累", "有点累", "比较累", "非常累"]),
        Question(text: "周末您通常如何度过？", options: ["宅家休息", "轻松逛街/散步", "户外运动/爬山", "高强度运动"]),
        Question(text: "您平时做家务 (如打扫、做饭) 的频率？", options: ["几乎不做", "偶尔做", "经常做", "每天做且量大"]),
        Question(text: "您是否有午睡习惯？", options: ["经常午睡 > 1小时", "偶尔午睡", "小憩 15分钟", "从不午睡"]),
        Question(text: "您觉得现在的体能状况如何？", options: ["很差", "动一下就喘", "一般", "不错", "非常好"]),
        Question(text: "您是否经常搬运重物？", options: ["从不", "偶尔 (如取快递)", "经常", "每天"]),
        Question(text: "您每天站立的时间大约是？", options: ["< 1小时", "1-3小时", "3-6小时", "> 6小时"]),
        Question(text: "您是否参加体育俱乐部或社团活动？", options: ["无", "偶尔参加", "定期参加", "是主力队员"]),
        Question(text: "您晚上的休闲活动通常是？", options: ["看电视/玩手机", "散步", "跑步/健身", "高强度竞技"]),
        Question(text: "如果需要去2公里外的地方，您会选择？", options: ["打车", "坐公交", "骑车", "走路"]),
        Question(text: "您最近一个月是否有运动受伤或身体不适？", options: ["有，严重影响活动", "有，轻微影响", "偶尔不适", "完全没有"]),
        Question(text: "您对运动的态度是？", options: ["不喜欢", "为了健康被迫做", "比较喜欢", "非常热爱"]),
        Question(text: "您每天的睡眠质量如何？", options: ["很差", "一般", "较好", "非常好"]),
        Question(text: "您是否感觉日常活动量不足？", options: ["严重不足", "有点不足", "刚刚好", "活动量很大"])
    ]
    
    var answeredCount: Int {
        answers.filter { $0 > 0 }.count
    }
    
    var canSubmit: Bool {
        answeredCount >= 5
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if showResult, let result = analysisResult {
                    ResultView(level: result, onConfirm: {
                        selectedActivityLevel = result
                        presentationMode.wrappedValue.dismiss()
                    }, onRetry: {
                        resetQuiz()
                    })
                } else {
                    // Header
                    HStack {
                        Text("问题 \(currentQuestionIndex + 1) / \(questions.count)")
                            .font(.headline)
                            .foregroundColor(.gray)
                        Spacer()
                        Text("已答: \(answeredCount)题")
                            .font(.caption)
                            .padding(6)
                            .background(canSubmit ? Color.green.opacity(0.1) : Color.gray.opacity(0.1))
                            .cornerRadius(8)
                            .foregroundColor(canSubmit ? .green : .gray)
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    
                    // Question Card
                    VStack(spacing: 20) {
                        Text(questions[currentQuestionIndex].text)
                            .font(.title3)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        
                        ScrollView {
                            VStack(spacing: 12) {
                                ForEach(0..<questions[currentQuestionIndex].options.count, id: \.self) { optionIndex in
                                    Button(action: {
                                        selectAnswer(optionIndex)
                                    }) {
                                        HStack {
                                            Text(questions[currentQuestionIndex].options[optionIndex])
                                                .foregroundColor(.primary)
                                            Spacer()
                                            if answers[currentQuestionIndex] == optionIndex + 1 {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundColor(.green)
                                            } else {
                                                Image(systemName: "circle")
                                                    .foregroundColor(.gray)
                                            }
                                        }
                                        .padding()
                                        .background(Color(.systemBackground))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(answers[currentQuestionIndex] == optionIndex + 1 ? Color.green : Color.gray.opacity(0.3), lineWidth: 1)
                                        )
                                        .cornerRadius(12)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding()
                    
                    // Navigation Controls
                    HStack {
                        Button(action: {
                            if currentQuestionIndex > 0 {
                                withAnimation { currentQuestionIndex -= 1 }
                            }
                        }) {
                            Image(systemName: "arrow.left")
                                .padding()
                                .background(Color(.systemGray6))
                                .clipShape(Circle())
                        }
                        .disabled(currentQuestionIndex == 0)
                        
                        Spacer()
                        
                        // Submit Button (Center)
                        if canSubmit {
                            Button(action: analyzeResult) {
                                Text("生成分析报告")
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 30)
                                    .padding(.vertical, 12)
                                    .background(Color.green)
                                    .cornerRadius(25)
                            }
                        } else {
                            Text("还需回答 \(5 - answeredCount) 题")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            if currentQuestionIndex < questions.count - 1 {
                                withAnimation { currentQuestionIndex += 1 }
                            }
                        }) {
                            HStack {
                                Text("下一题")
                                Image(systemName: "arrow.right")
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(25)
                        }
                        .disabled(currentQuestionIndex == questions.count - 1)
                    }
                    .padding()
                }
            }
            .navigationTitle("活动强度评估")
            .navigationBarItems(trailing: Button("关闭") {
                presentationMode.wrappedValue.dismiss()
            })
            .overlay(
                Group {
                    if isAnalyzing {
                        ZStack {
                            Color.black.opacity(0.4).edgesIgnoringSafeArea(.all)
                            VStack {
                                ProgressView()
                                    .scaleEffect(1.5)
                                    .padding()
                                Text("AI 正在分析您的回答...")
                                    .foregroundColor(.white)
                                    .fontWeight(.bold)
                            }
                        }
                    }
                }
            )
        }
    }
    
    private func selectAnswer(_ index: Int) {
        answers[currentQuestionIndex] = index + 1 // Score 1-4
        
        // Auto-advance after short delay if not last question
        if currentQuestionIndex < questions.count - 1 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation {
                    currentQuestionIndex += 1
                }
            }
        }
    }
    
    private func analyzeResult() {
        isAnalyzing = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            // Logic: Average score of answered questions mapped to full scale
            let answeredScores = answers.filter { $0 > 0 }
            guard !answeredScores.isEmpty else { return }
            
            let average = Double(answeredScores.reduce(0, +)) / Double(answeredScores.count)
            // Scale: 1.0 - 4.0
            // Sedentary: 1.0 - 1.6
            // Light: 1.6 - 2.2
            // Moderate: 2.2 - 2.8
            // Active: 2.8 - 3.4
            // Athlete: 3.4 - 4.0
            
            if average <= 1.6 { analysisResult = .sedentary }
            else if average <= 2.2 { analysisResult = .light }
            else if average <= 2.8 { analysisResult = .moderate }
            else if average <= 3.4 { analysisResult = .active }
            else { analysisResult = .athlete }
            
            isAnalyzing = false
            withAnimation {
                showResult = true
            }
        }
    }
    
    private func resetQuiz() {
        currentQuestionIndex = 0
        answers = Array(repeating: 0, count: 20)
        showResult = false
        analysisResult = nil
    }
}

struct ResultView: View {
    let level: ActivityLevel
    let onConfirm: () -> Void
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: iconForLevel(level))
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 100, height: 100)
                .foregroundColor(.green)
            
            VStack(spacing: 10) {
                Text("评估结果")
                    .font(.headline)
                    .foregroundColor(.gray)
                
                Text(level.rawValue)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(level.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            VStack(spacing: 15) {
                Button(action: onConfirm) {
                    Text("采纳此结果")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(12)
                }
                
                Button(action: onRetry) {
                    Text("重新测试")
                        .font(.headline)
                        .foregroundColor(.green)
                }
            }
            .padding(.horizontal, 40)
        }
        .padding()
    }
    
    func iconForLevel(_ level: ActivityLevel) -> String {
        switch level {
        case .sedentary: return "chair.lounge.fill"
        case .light: return "figure.walk"
        case .moderate: return "figure.run"
        case .active: return "figure.boxing"
        case .athlete: return "trophy.fill"
        }
    }
}
