//
//  ContentView.swift
//  simple-pwd-generator
//
//  Created by Eli Selkin on 7/19/24.
//

import SwiftData
import SwiftUI
import zxcvbn

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var GeneratedPassword: [PasswordItem]
    @State private var passwordType: PASSWORD_TYPE? = nil

    @State private var includeLC: Bool = false
    @State private var includeUC: Bool = false
    @State private var includeNC: Bool = false
    @State private var includeSC: Bool = false
    @State private var special = "!.,@"
    @State private var length = 0
    @State private var min = 1
    @State private var generatedPassword = ""
    @State private var separator: PASSWORD_SEPARATOR = .none
    @State private var minWordLength: Int? = nil
    @State private var errorMessage = ""
    @State private var showError = false
    @State private var result: MostGuessableMatchSequenceResult? = nil
    @State private var copiedMsg: String = "Password copied to clipboard"
    @State private var showCopied: Bool = false
    @State private var timer: Timer?

    private func delayText() async {
        // Delay of 7.5 seconds (1 second = 1_000_000_000 nanoseconds)
        showCopied = true
        try? await Task.sleep(nanoseconds: 2_500_000_000)
        showCopied = false
    }

    private func changeMin(_ includeBool: Bool) {
        if includeBool {
            min += 1
        } else {
            min -= 1
        }
    }
    private func generate() {
        showError = false
        errorMessage = ""
        var toInclude: [PASSWORD_CHARACTER_INCLUDES] = []
        var specialToInc: String = ""
        if includeLC {
            toInclude.append(.lowercase)
        }
        if includeNC {
            toInclude.append(.number)
        }
        if includeUC {
            toInclude.append(.uppercase)
        }
        if includeSC {
            toInclude.append(.special)
            specialToInc = special
        }
        if let pwType = passwordType {
            debugPrint(separator)
            do {
                generatedPassword = try password_gen(
                    characters_to_include: toInclude,
                    special_to_include: specialToInc, password_type: pwType,
                    length: length, separator: separator,
                    minWordLength: minWordLength)
                result = zxcvbn(generatedPassword)
                debugPrint(result)
            } catch PasswordCreationError
                .couldNotFindIndexOfMostFrequentCharacterType
            {

                errorMessage = "Error"
                showError = true
            } catch PasswordCreationError.mustSelectAtLeastOneCharacterType {
                errorMessage = "Need to include at least one character type."
                showError = true
            } catch PasswordCreationError.tooFewWordsToSelectFrom {
                errorMessage = "Try reducing the minimum word length"
                showError = true
            } catch {
                errorMessage = "Something happened, try again"
                showError = true
            }
        }
    }
    var body: some View {
        Form {
            Section(header: Text("Password generation")) {
                Picker("Type of password generation", selection: $passwordType)
                {
                    Text("Random character").tag(
                        PASSWORD_TYPE.random_characters)
                    Text("Words").tag(PASSWORD_TYPE.words)
                }.onChange(of: passwordType) {
                    if passwordType == .random_characters {
                        length = 12
                        separator = .none
                        minWordLength = nil
                    } else {
                        min = 1
                        length = 4
                        minWordLength = 6
                        separator = .random
                        includeLC = false
                        includeNC = false
                        includeSC = false
                        includeUC = false
                        
                    }
                }

                if passwordType == .random_characters {
                    Toggle("Include lowercase letters", isOn: $includeLC)
                        .onChange(of: includeLC, perform: changeMin)
                    Toggle("Include uppercase letters", isOn: $includeUC)
                        .onChange(of: includeUC, perform: changeMin)
                    Toggle("Include numbers", isOn: $includeNC).onChange(
                        of: includeNC, perform: changeMin
                    )
                    Toggle("Include special characters", isOn: $includeSC)
                        .onChange(of: includeSC, perform: changeMin)
                    if includeSC {
                        LabeledContent {
                            TextField("", text: $special)
                        } label: {
                            Text("Special characters")
                        }
                    }
                } else if passwordType == .words {
                    LabeledContent {
                        Picker("", selection: $minWordLength) {
                            ForEach(6..<50) { i in
                                Text(String(i)).tag(i)
                            }
                        }
                    } label: {
                        Text("Minimum word length")

                    }
                }
                if passwordType != nil {
                    LabeledContent {
                        Picker("", selection: $length) {
                            ForEach(1..<200) { i in
                                if i >= min {
                                    Text(String(i)).tag(i).disabled(i <= min)
                                }
                            }
                        }
                    } label: {
                        Text("Length of password")
                    }

                    LabeledContent {
                        Picker("", selection: $separator) {
                            Text("none").tag(PASSWORD_SEPARATOR.none)
                            Text("underscore").tag(
                                PASSWORD_SEPARATOR.underscore)
                            Text("comma").tag(PASSWORD_SEPARATOR.comma)
                            Text("dash").tag(PASSWORD_SEPARATOR.dash)
                            Text("random separator").tag(
                                PASSWORD_SEPARATOR.random)
                        }
                    } label: {
                        Text("Separator")
                    }

                    Button(
                        "Generate", systemImage: "plus.circle.fill",
                        action: generate
                    ).buttonStyle(.automatic).alert(
                        isPresented: $showError
                    ) {
                        Alert(title: Text(errorMessage))
                    }
                }
            }
            if generatedPassword != "" {
                Section(header: Text("Output password")) {
                    Text(generatedPassword).onTapGesture {
                        UIPasteboard.general.string = generatedPassword
                        showCopied = true
                        timer = Timer.scheduledTimer(
                            withTimeInterval: 2.0, repeats: false
                        ) { timer in
                            showCopied = false
                        }

                        if !showCopied {
                            timer?.invalidate()
                        }
                    }
                    if let realResult = result {

                        HStack {
                            if let realResultScore = realResult.score {
                                if realResultScore <= 2 {
                                    Text(
                                        "Please consider increasing the length of your password"
                                    )
                                }
                                if realResultScore > 0 {
                                    Image(systemName: "star.fill")
                                        .foregroundStyle(
                                            .yellow)
                                }
                                if realResultScore > 1 {
                                    Image(systemName: "star.fill")
                                        .foregroundStyle(
                                            .yellow)
                                }
                                if realResultScore > 2 {
                                    Image(systemName: "star.fill")
                                        .foregroundStyle(
                                            .yellow)
                                }
                                if realResultScore > 3 {
                                    Image(systemName: "star.fill")
                                        .foregroundStyle(
                                            .yellow)
                                }
                            }
                        }
                        if let crackTimesDisplay = realResult.crackTimesDisplay
                        {
                            LabeledContent {
                                Text(
                                    crackTimesDisplay
                                        .offlineFastHashing1e10PerSecond)
                            } label: {
                                Text("ZXCVBN length of time to crack")
                            }
                        }
                    }

                    if showCopied {
                        Text(copiedMsg)
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: PasswordItem.self, inMemory: true)
}
