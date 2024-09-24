//
//  password_gen.swift
//  simple-pwd-generator
//
//  Created by Eli Selkin on 7/19/24.
//

import Foundation

let DIFFICULT_TO_DISTINGUISH="01OIloQSs5"
let NUMBERS = "0123456789"
let NUMBERS_EASY_TO_DISTINGUISH = NUMBERS.filter {
    !DIFFICULT_TO_DISTINGUISH.contains($0)
}
let LOWERCASE = "abcdefghijklmnopqrstuvwxyz"
let LOWERCASE_EASY_TO_DISTINGUISH = LOWERCASE.filter {
    !DIFFICULT_TO_DISTINGUISH.contains($0)
}
let UPPERCASE = LOWERCASE.uppercased()
let UPPERCASE_EASY_TO_DISTINGUISH = LOWERCASE.uppercased().filter {
    !DIFFICULT_TO_DISTINGUISH.contains($0)
}

let SEPARATORS = "_-,.!*?"

enum PASSWORD_CHARACTER_INCLUDES: String, CaseIterable {
    case special
    case uppercase
    case lowercase
    case number
}

enum PASSWORD_TYPE: String, CaseIterable {
    case unselected
    case random_characters
    case words
}

enum PASSWORD_SEPARATOR: String, CaseIterable {
    case none
    case underscore
    case dash
    case comma
    case period
    case asterisk
    case exclamation
    case questionmark
    case random
}

enum PasswordCreationError: Error {
    case tooManyConstraints
    case couldNotFindIndexOfMostFrequentCharacterType
    case tooFewWordsToSelectFrom
    case mustSelectAtLeastOneCharacterType
    case includesSCButEmpty
    case couldNotSelectRandomCharacter
}

func random_character(
    characters_to_include: [PASSWORD_CHARACTER_INCLUDES],
    special_to_include: String?,
    no_difficult_to_distinguish: Bool = false
) -> (String, PASSWORD_CHARACTER_INCLUDES) {
    var character = ""
    let choice_option = characters_to_include.randomElement()!
    switch choice_option {
    case .special:
        if let random_special = special_to_include?.randomElement() {
            character.append(random_special)
        }
        break
    case .number:
        if let random_number = (no_difficult_to_distinguish ? NUMBERS_EASY_TO_DISTINGUISH : NUMBERS).randomElement() {
            character.append(random_number)
        }
        break
    case .lowercase:
        if let random_lowercase = (no_difficult_to_distinguish ? LOWERCASE_EASY_TO_DISTINGUISH: LOWERCASE).randomElement() {
            character.append(random_lowercase)
        }
        break
    default:
        if let random_uppercase = (no_difficult_to_distinguish ? UPPERCASE_EASY_TO_DISTINGUISH : UPPERCASE).randomElement() {
            character.append(random_uppercase)
        }
        break
    }
    return (character, choice_option)
}

func removeChar(
    hasChar: [PASSWORD_CHARACTER_INCLUDES: Int], password: [String],
    special: String
) throws -> ([PASSWORD_CHARACTER_INCLUDES: Int], [String], String) {
    let largest = hasChar.max {
        a, b in a.value < b.value
    }
    var passwordCopy = password.map({ $0 })
    var toRemove = ""
    var hasCharCopy = hasChar.reduce(into: [PASSWORD_CHARACTER_INCLUDES: Int]())
    { acc, el in
        acc[el.key] = el.value
    }
    if let (lt, lv) = largest {
        if lv <= 1 {
            throw PasswordCreationError.tooManyConstraints
        }
        var fi: Int? = nil
        if lt == .lowercase {
            fi = password.firstIndex(where: { LOWERCASE.contains($0) })
        } else if lt == .uppercase {
            fi = password.firstIndex(where: { UPPERCASE.contains($0) })
        } else if lt == .number {
            fi = password.firstIndex(where: { NUMBERS.contains($0) })
        } else if lt == .special {
            fi = password.firstIndex(where: { special.contains($0) })
        }

        if let firstI = fi {
            toRemove = passwordCopy[Int(firstI)]
            passwordCopy.remove(at: Int(firstI))
            hasCharCopy[lt] = lv - 1
        } else {
            throw PasswordCreationError
                .couldNotFindIndexOfMostFrequentCharacterType
        }
    }
    return (hasCharCopy, passwordCopy, toRemove)
}

func password_gen(
    characters_to_include: [PASSWORD_CHARACTER_INCLUDES],
    special_to_include: String,
    password_type: PASSWORD_TYPE,
    length: Int,
    separator: PASSWORD_SEPARATOR,
    separatorEvery: Int,
    dictionaries: Dictionaries,
    minWordLength: Int?,
    maxWordLength: Int?,
    dictionariesToUse: [String]?,
    doNotUseDifficult: Bool = false
) throws -> String {
    // If password is random characters and the number of characters to include is less than the length of the required type of characters, throw an error. This is a shortcut failure, since the system wouldn't succeed even if this condition were not here.
    if password_type == .random_characters
        && length < characters_to_include.count
    {
        throw PasswordCreationError.tooManyConstraints
    }

    if password_type == .random_characters && characters_to_include.count == 0 {
        throw PasswordCreationError.mustSelectAtLeastOneCharacterType
    }

    // Initialize hasChar. Creates a dictionary of types and number present (assigned values > 0 when chosen character is picked). Initialized to only have keys for the types of characters to include. Only applies to .random_character passwords
    var hasChar = [PASSWORD_CHARACTER_INCLUDES: Int]()
    for charType in characters_to_include {
        hasChar[charType] = 0
    }

    if hasChar[.special] == 0 && special_to_include.isEmpty {
        throw PasswordCreationError.includesSCButEmpty
    }

    // We use a String array to hold chosen password characters until joining them at the end.
    var password: [String] = []

    var wordlistFiltered: [String.SubSequence] = []
    if password_type == .words {
        var min = 1
        if minWordLength != nil {
            min = minWordLength!
        }
        var max = 100
        if maxWordLength != nil {
            max = maxWordLength!
        }
        if let dictionariesToUseEx = dictionariesToUse {
            if dictionariesToUseEx.contains("English") {
                wordlistFiltered = dictionaries.english.filter { word in
                    word.count > min && word.count < max
                }
            }
            if dictionariesToUseEx.contains("Spanish") {
                let spanishWords = dictionaries.spanish.filter { word in
                    word.count > min && word.count < max
                }
                wordlistFiltered.append(contentsOf: spanishWords)
            }
        }
        if wordlistFiltered.count < 1000 {
            throw PasswordCreationError.tooFewWordsToSelectFrom
        }
        wordlistFiltered.shuffle()
    }
    for _ in 0..<length {
        if password_type == .random_characters {
            let (random_selection, selection_type) = random_character(
                characters_to_include: characters_to_include,
                special_to_include: special_to_include, no_difficult_to_distinguish: doNotUseDifficult)
            if !random_selection.isEmpty {
                hasChar[selection_type]! += 1
            } else {
                throw PasswordCreationError.couldNotSelectRandomCharacter
            }
            password.append(random_selection)
        } else if password_type == .words {
            if let word = wordlistFiltered.randomElement() {
                password.append(String(word))
            }
        }
    }
    var missing_char_types = [PASSWORD_CHARACTER_INCLUDES]()
    if password_type == .random_characters {
        for (key, value) in hasChar {
            if value == 0 {
                missing_char_types.append(key)
            }
        }
    }
    for missing_char_type in missing_char_types {
        let (new_random_sel, _) = random_character(
            characters_to_include: [missing_char_type],
            special_to_include: special_to_include, no_difficult_to_distinguish: doNotUseDifficult)
        
        if (new_random_sel.isEmpty) {
            throw PasswordCreationError.tooManyConstraints
        }
        
        // overwrites password and hasChar
        (hasChar, password, _) = try removeChar(
            hasChar: hasChar, password: password, special: special_to_include)
        
        // Appends to new return from above
        password.append(new_random_sel)
    }

    var separatedPassword = [String]()

    for i in 0..<password.count {
        if (i > 0 || (i > 0 && password_type == .words))
            && (i).isMultiple(of: separatorEvery)
        {
            switch separator {
            case .dash:
                separatedPassword.append("-")
                break
            case .asterisk:
                separatedPassword.append("*")
                break
            case .comma:
                separatedPassword.append(",")
                break
            case .exclamation:
                separatedPassword.append("!")
                break
            case .period:
                separatedPassword.append(".")
                break
            case .questionmark:
                separatedPassword.append("?")
                break
            case .underscore:
                separatedPassword.append("_")
                break
            case .random:
                separatedPassword.append(String(SEPARATORS.randomElement()!))
                break
            default:
                separatedPassword.append("")
            }

        }
        separatedPassword.append(password[i])
    }

    return separatedPassword.joined()
}
