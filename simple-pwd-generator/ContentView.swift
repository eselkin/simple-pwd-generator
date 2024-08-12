//
//  ContentView.swift
//  simple-pwd-generator
//
//  Created by Eli Selkin on 7/19/24.
//

import SwiftData
import SwiftUI
import zxcvbn

extension Array: @retroactive RawRepresentable where Element: Codable {
    public init?(rawValue: String) {
        guard let data = rawValue.data(using: .utf8),
            let result = try? JSONDecoder().decode([Element].self, from: data)
        else {
            return nil
        }
        self = result
    }

    public var rawValue: String {
        guard let data = try? JSONEncoder().encode(self),
            let result = String(data: data, encoding: .utf8)
        else {
            return "[]"
        }
        return result
    }
}

struct ContentView: View {
    // State stored to AppStorage between uses
    @AppStorage("pwpasswordType") private var passwordType: PASSWORD_TYPE =
        .unselected
    @AppStorage("pwincludeLC") private var includeLC: Bool = true
    @AppStorage("pwincludeUC") private var includeUC: Bool = true
    @AppStorage("pwincludeNC") private var includeNC: Bool = true
    @AppStorage("pwincludeSC") private var includeSC: Bool = true
    @AppStorage("pwspecial") private var special = "!.,@#$%*?-_"
    @AppStorage("pwlength") private var length: Int = 20
    @AppStorage("pwmin") private var min = 1
    @AppStorage("pwseparator") private var separator: PASSWORD_SEPARATOR = .none
    @AppStorage("pwminwordlength") private var minWordLength: Int = 5
    @AppStorage("pwmaxwordlength") private var maxWordLength: Int = 10
    @AppStorage("pwseparatorevery") private var separatorEvery: Int = 6
    @AppStorage("pwuseendict") private var useEnglishDictionary: Bool = true
    @AppStorage("pwuseesdict") private var useSpanishDictionary: Bool = false

    // Password and ZXCVBN output - not stored in AppStorage. You can copy the result to the clipboard, but it is not stored between uses
    @State private var generatedPassword: String = ""
    @State private var result: MostGuessableMatchSequenceResult? = nil

    // State variables not stored
    @State private var errorMessage = ""
    @State private var showError = false
    @State private var copiedMsg: String = "Password copied to clipboard"
    @State private var showCopied: Bool = false
    @State private var timer: Timer?
    @State private var showRefreshAlert = false

    var dictionaries = Dictionaries()

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

    private func reset(type: PASSWORD_TYPE) {
        separator = .none
        length = 20
        separatorEvery = 6
        if type == .unselected && passwordType != .unselected {
            passwordType = .unselected
        }
        if type == .words {
            separator = .random
            length = 5
            separatorEvery = 1
        }
        min = 4
        minWordLength = 5
        maxWordLength = 10
        special = "!.,@#$%*?-_"
        includeLC = true
        includeNC = true
        includeSC = true
        includeUC = true
        generatedPassword = ""
        result = nil
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
        var dictionariesToUse: [String] = []
        if useEnglishDictionary {
            dictionariesToUse.append("English")
        }
        if useSpanishDictionary {
            dictionariesToUse.append("Spanish")
        }
        if passwordType != .unselected {
            do {
                generatedPassword = try password_gen(
                    characters_to_include: toInclude,
                    special_to_include: specialToInc,
                    password_type: passwordType,
                    length: length,
                    separator: separator,
                    separatorEvery: separatorEvery,
                    dictionaries: dictionaries,
                    minWordLength: minWordLength,
                    maxWordLength: maxWordLength,
                    dictionariesToUse: dictionariesToUse
                )
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
            } catch {
                errorMessage = "Something happened, try again"
                showError = true
            }
        }
    }
    var body: some View {
        NavigationStack {
            VStack {
                NavigationLink {
                    // destination view to navigation to
                    ConfigView()
                } label: {
                    HStack {
                        Image(systemName: "gear")
                            .imageScale(.large)
                            .foregroundColor(.accentColor)
                        Text("Settings")
                    }
                    .padding()
                }
                
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
                                reset(type: .random_characters)
                            } else if passwordType == .words {
                                reset(type: .words)
                            } else {
                                reset(type: .unselected)
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
                                ForEach(5..<50) { i in
                                    Text(String(i)).tag(i)
                                }
                            }
                            Picker("Maximum word length", selection: $maxWordLength) {
                                ForEach(7..<50) { i in
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
                                Text("underscore (_)").tag(
                                    PASSWORD_SEPARATOR.underscore)
                                Text("comma (,)").tag(PASSWORD_SEPARATOR.comma)
                                Text("dash (-)").tag(PASSWORD_SEPARATOR.dash)
                                Text("exclamation mark (!)").tag(PASSWORD_SEPARATOR.exclamation)
                                Text("question mark (?)").tag(PASSWORD_SEPARATOR.questionmark)
                                Text("asterisk (*)").tag(PASSWORD_SEPARATOR.asterisk)
                                Text("period (.)").tag(PASSWORD_SEPARATOR.period)
                                Text("random separator").tag(
                                    PASSWORD_SEPARATOR.random)
                            }
                            if separator != .none {
                                Picker("Separator every", selection: $separatorEvery) {
                                    if passwordType == .words {
                                        ForEach(1..<200) { i in
                                            if i == 1 {
                                                Text(String(i) + String(" word")).tag(i)
                                            } else if i <= length {
                                                Text(String(i) + String(" words")).tag(i)
                                            }
                                        }
                                    } else {
                                        ForEach(1..<200) { i in
                                            if i == 1 {
                                                Text(String(i) + String(" character")).tag(
                                                    i)
                                            } else {
                                                Text(String(i) + String(" characters")).tag(
                                                    i)
                                            }
                                        }
                                    }
                                }
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
                }.refreshable {
                    reset(type: .unselected)
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
