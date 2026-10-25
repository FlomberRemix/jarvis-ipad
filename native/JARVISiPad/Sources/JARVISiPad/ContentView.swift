import SwiftUI

struct ContentView: View {
    @StateObject private var speech = SpeechManager()
    @State private var messages: [ChatMessage] = [
        ChatMessage(role: .assistant, text: "Вітаю, Flomber. Я J.A.R.V.I.S. Готовий до роботи. Додай Gemini API key у налаштуваннях, щоб увімкнути ШІ.")
    ]
    @State private var input = ""
    @State private var apiKeyInput = ""
    @State private var showSettings = false
    @State private var isSending = false
    @State private var errorText: String?

    private let service = GeminiService()

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.015, green: 0.035, blue: 0.09), .black], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            VStack(spacing: 0) {
                header
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 14) {
                            ForEach(messages) { message in
                                messageBubble(message).id(message.id)
                            }
                            if isSending {
                                HStack { ProgressView().tint(.cyan); Text("JARVIS обробляє запит…").foregroundStyle(.secondary); Spacer() }
                                    .padding(.horizontal)
                            }
                        }
                        .padding()
                    }
                    .onChange(of: messages.count) { _ in
                        if let last = messages.last { withAnimation { proxy.scrollTo(last.id, anchor: .bottom) } }
                    }
                }
                if let errorText {
                    Text(errorText).font(.footnote).foregroundStyle(.orange).padding(.horizontal)
                }
                composer
            }
        }
        .sheet(isPresented: $showSettings) { settingsSheet }
        .onChange(of: speech.recognizedText) { newValue in
            if !newValue.isEmpty { input = newValue }
        }
    }

    private var header: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().stroke(Color.cyan.opacity(0.8), lineWidth: 2).frame(width: 48, height: 48)
                Circle().fill(Color.cyan.opacity(0.12)).frame(width: 38, height: 38)
                Image(systemName: "sparkle").font(.system(size: 23, weight: .light)).foregroundStyle(.cyan)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text("J.A.R.V.I.S.").font(.title2.bold()).tracking(2).foregroundStyle(.white)
                Text(speech.status).font(.caption).foregroundStyle(.cyan)
            }
            Spacer()
            Button { showSettings = true } label: {
                Image(systemName: "gearshape").font(.title3).foregroundStyle(.cyan).padding(10)
            }
            .accessibilityLabel("Налаштування")
        }
        .padding()
        .background(.black.opacity(0.35))
    }

    private func messageBubble(_ message: ChatMessage) -> some View {
        HStack {
            if message.role == .user { Spacer(minLength: 42) }
            VStack(alignment: .leading, spacing: 6) {
                Text(message.role == .user ? "ТИ" : "JARVIS")
                    .font(.caption2.bold()).tracking(1.5)
                    .foregroundStyle(message.role == .user ? .white.opacity(0.7) : .cyan)
                Text(message.text).font(.body).foregroundStyle(.white).textSelection(.enabled)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(message.role == .user ? Color.blue.opacity(0.22) : Color.cyan.opacity(0.08))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(message.role == .user ? Color.blue.opacity(0.3) : Color.cyan.opacity(0.25), lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            if message.role != .user { Spacer(minLength: 22) }
        }
    }

    private var composer: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                Button {
                    if speech.isListening { speech.stopListening() } else { speech.startListening() }
                } label: {
                    Image(systemName: speech.isListening ? "stop.fill" : "mic.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(speech.isListening ? .black : .cyan)
                        .frame(width: 48, height: 48)
                        .background(speech.isListening ? Color.cyan : Color.cyan.opacity(0.12))
                        .clipShape(Circle())
                }
                .accessibilityLabel(speech.isListening ? "Зупинити прослуховування" : "Голосове введення")
                TextField("Введи команду JARVIS…", text: $input, axis: .vertical)
                    .lineLimit(1...4)
                    .padding(12)
                    .background(Color.white.opacity(0.07))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .foregroundStyle(.white)
                Button(action: send) {
                    Image(systemName: "arrow.up").font(.headline.bold())
                        .foregroundStyle(.black).frame(width: 44, height: 44)
                        .background(Color.cyan).clipShape(Circle())
                }
                .disabled(input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSending)
                .accessibilityLabel("Надіслати")
            }
            Text("Голосове введення • Українська мова").font(.caption2).foregroundStyle(.secondary)
        }
        .padding()
        .background(.black.opacity(0.6))
    }

    private var settingsSheet: some View {
        NavigationStack {
            Form {
                Section("Gemini AI") {
                    SecureField("Gemini API key", text: $apiKeyInput)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    Button("Зберегти ключ у Keychain") {
                        do {
                            try KeychainStore.save(apiKeyInput.trimmingCharacters(in: .whitespacesAndNewlines))
                            apiKeyInput = ""
                            showSettings = false
                        } catch {
                            errorText = "Не вдалося зберегти ключ: \(error.localizedDescription)"
                            showSettings = false
                        }
                    }
                    Text("Ключ зберігається в захищеному сховищі iPad. Не додавай його до GitHub.")
                        .font(.footnote).foregroundStyle(.secondary)
                    Button("Видалити збережений ключ", role: .destructive) {
                        KeychainStore.delete()
                    }
                }
                Section("Про застосунок") {
                    LabeledContent("Збірка", value: "Native iPadOS starter")
                    Text("Ця початкова версія має нативний інтерфейс, голосове введення та відповіді Gemini. Команди Windows на iPad потрібно замінити окремими функціями iPadOS.")
                        .font(.footnote)
                }
            }
            .navigationTitle("Налаштування JARVIS")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") { showSettings = false }
                }
            }
            .onAppear { apiKeyInput = "" }
        }
        .presentationDetents([.medium, .large])
    }

    private func send() {
        let prompt = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !prompt.isEmpty, !isSending else { return }
        input = ""
        errorText = nil
        messages.append(ChatMessage(role: .user, text: prompt))
        isSending = true
        Task {
            do {
                let answer = try await service.reply(to: prompt, history: Array(messages.dropLast()))
                let response = ChatMessage(role: .assistant, text: answer)
                messages.append(response)
                speech.speak(answer)
            } catch {
                errorText = error.localizedDescription
                messages.append(ChatMessage(role: .assistant, text: "Не вдалося отримати відповідь. Перевір інтернет і налаштування Gemini API key."))
            }
            isSending = false
        }
    }
}
