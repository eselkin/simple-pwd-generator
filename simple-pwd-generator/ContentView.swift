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
    // State stored to AppStorage between uses
    @AppStorage("pwpasswordType") private var passwordType: PASSWORD_TYPE =
        .unselected
    @AppStorage("pwincludeLC") private var includeLC: Bool = false
    @AppStorage("pwincludeUC") private var includeUC: Bool = false
    @AppStorage("pwincludeNC") private var includeNC: Bool = false
    @AppStorage("pwincludeSC") private var includeSC: Bool = false
    @AppStorage("pwspecial") private var special = "!.,@"
    @AppStorage("pwlength") private var length = 0
    @AppStorage("pwmin") private var min = 1
    @AppStorage("pwseparator") private var separator: PASSWORD_SEPARATOR = .none
    @AppStorage("pwminwordlength") private var minWordLength: Int = 6

    // Password and ZXCVBN output - not stored in AppStorage. You can copy the result to the clipboard, but it is not stored between uses
    @State private var generatedPassword = ""
    @State private var result: MostGuessableMatchSequenceResult? = nil

    // State variables not stored
    @State private var errorMessage = ""
    @State private var showError = false
    @State private var copiedMsg: String = "Password copied to clipboard"
    @State private var showCopied: Bool = false
    @State private var timer: Timer?
    @State private var showRefreshAlert = false

    // This is a convenience method to update the minimum shown in the picker wheel
    private func setMin() {
        var tempmin = 1
        if includeLC {
            tempmin += 1
        }
        if includeNC {
            tempmin += 1
        }
        if includeSC {
            tempmin += 1
        }
        if includeUC {
            tempmin += 1
        }
        min = tempmin
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
        if passwordType != .unselected {
            do {
                generatedPassword = try password_gen(
                    characters_to_include: toInclude,
                    special_to_include: specialToInc,
                    password_type: passwordType,
                    length: length, separator: separator,
                    minWordLength: minWordLength)
                result = zxcvbn(generatedPassword)
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
            } catch PasswordCreationError.tooManyConstraints {
                errorMessage =
                    "Too many constraints, try reducing the number of words"
                showError = true
            } catch PasswordCreationError.includesSCButEmpty {
                errorMessage =
                    "Include special characters to check is checked but list is empty. Add some special characters."
                showError = true
            }
            catch {
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
                    Text("Select a type").tag(PASSWORD_TYPE.unselected)
                    Text("Random character").tag(
                        PASSWORD_TYPE.random_characters)
                    Text("Words").tag(PASSWORD_TYPE.words)
                }.onChange(of: passwordType) {
                    if passwordType == .random_characters {
                        length = 12
                        separator = .none
                        minWordLength = 6
                    } else if passwordType == .words {
                        min = 4
                        length = 4
                        minWordLength = 6
                        separator = .random
                        includeLC = true
                        includeNC = true
                        includeSC = true
                        includeUC = true
                    } else {
                        // selected none
                        length = 4
                        includeLC = true
                        includeNC = true
                        includeSC = true
                        includeUC = true
                        separator = .underscore
                        minWordLength = 6
                    }
                }

                if passwordType == .random_characters {
                    Toggle("Include lowercase letters", isOn: $includeLC)
                        .onChange(of: includeLC) {
                            setMin()
                        }
                    Toggle("Include uppercase letters", isOn: $includeUC)
                        .onChange(of: includeUC) { setMin() }
                    Toggle("Include numbers", isOn: $includeNC).onChange(
                        of: includeNC
                    ) {
                        setMin()
                    }
                    Toggle("Include special characters", isOn: $includeSC)
                        .onChange(of: includeSC) {
                            setMin()
                        }

                    // special characters requires the provision of a string of characters to choose from
                    if includeSC {
                        LabeledContent {
                            TextField("", text: $special)
                        } label: {
                            Text("Special characters")
                        }
                    }
                } else if passwordType == .words {
                    // word specific form options. 6-50 word length, which is arbitrary. Once you go over 15 in the english language dictionary, there are too few options to choose from so the function will display an error.

                    Picker("Minimum word length", selection: $minWordLength) {
                        ForEach(6..<50) { i in
                            Text(String(i)).tag(i)
                        }
                    }

                }
                if passwordType != .unselected {

                    Picker("Length of password", selection: $length) {
                        ForEach(1..<200) { i in
                            if i >= min {
                                Text(String(i)).tag(i)
                            }
                        }
                    }

                    Picker("Separator", selection: $separator) {
                        Text("none").tag(PASSWORD_SEPARATOR.none)
                        Text("underscore").tag(
                            PASSWORD_SEPARATOR.underscore)
                        Text("comma").tag(PASSWORD_SEPARATOR.comma)
                        Text("dash").tag(PASSWORD_SEPARATOR.dash)
                        Text("random separator").tag(
                            PASSWORD_SEPARATOR.random)
                    }

                    if passwordType != .unselected {
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
        }.refreshable {
            passwordType = .unselected
            includeLC = true
            includeNC = true
            includeUC = true
            includeSC = true
            length = 12
            minWordLength = 6
            min = 5
            showRefreshAlert = false
            special = ""
            generatedPassword = ""
            result = nil
        }
    }
}

#Preview {
    ContentView()
}
