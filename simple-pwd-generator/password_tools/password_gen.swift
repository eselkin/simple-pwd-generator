//
//  password_gen.swift
//  simple-pwd-generator
//
//  Created by Eli Selkin on 7/19/24.
//

import Foundation

var NUMBERS = "0123456789"
var LOWERCASE = "abcdefghijklmnopqrstuvwxyz"
var UPPERCASE = LOWERCASE.uppercased()
var SEPARATORS = "_-,."

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
    case random
}

enum PasswordCreationError: Error {
    case tooManyConstraints
    case couldNotFindIndexOfMostFrequentCharacterType
    case tooFewWordsToSelectFrom
    case mustSelectAtLeastOneCharacterType
}

func random_character(
    characters_to_include: [PASSWORD_CHARACTER_INCLUDES],
    special_to_include: String?
) -> String {
    var character = ""
    if characters_to_include.contains(.special) && special_to_include != nil {
        if let random_special = special_to_include?.randomElement() {
            character.append(random_special)
        }
    }
    if characters_to_include.contains(.uppercase) {
        if let random_uppercase = UPPERCASE.randomElement() {
            character.append(random_uppercase)
        }
    }
    if characters_to_include.contains(.lowercase) {
        if let random_lowercase = LOWERCASE.randomElement() {
            character.append(random_lowercase)
        }
    }
    if characters_to_include.contains(.number) {
        if let random_number = NUMBERS.randomElement() {
            character.append(random_number)
        }
    }
    let randomIndex = Int.random(in: 0..<character.count)
    return String(
        character[character.index(character.startIndex, offsetBy: randomIndex)])
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
    minWordLength: Int?
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

    // We use a String array to hold chosen password characters until joining them at the end.
    var password: [String] = []

    var englishFiltered: [String.SubSequence] = []
    if password_type == .words {
        let dictionaries = Dictionaries()
        var min = 1
        if minWordLength != nil {
            min = minWordLength!
        }
        englishFiltered = dictionaries.english.filter { word in
            word.count > min
        }
        if englishFiltered.count < 2000 {
            throw PasswordCreationError.tooFewWordsToSelectFrom
        }
    }
    for _ in 0..<length {
        if password_type == .random_characters {
            let random_selection = random_character(
                characters_to_include: characters_to_include,
                special_to_include: special_to_include)
            if NUMBERS.contains(random_selection) {
                hasChar[.number]! += 1
            } else if UPPERCASE.contains(random_selection) {
                hasChar[.uppercase]! += 1
            } else if LOWERCASE.contains(random_selection) {
                hasChar[.lowercase]! += 1
            } else if special_to_include.contains(random_selection) {
                hasChar[.special]! += 1
            }
            password.append(random_selection)
        } else if password_type == .words {
            if let word = englishFiltered.randomElement() {
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

    while missing_char_types.count > 0 {
        let new_random_sel = random_character(
            characters_to_include: missing_char_types,
            special_to_include: special_to_include)
        if NUMBERS.contains(new_random_sel) {
            missing_char_types = missing_char_types.filter { mct in
                mct != .number
            }
        } else if UPPERCASE.contains(new_random_sel) {
            missing_char_types = missing_char_types.filter { mct in
                mct != .uppercase
            }
        } else if LOWERCASE.contains(new_random_sel) {
            missing_char_types = missing_char_types.filter { mct in
                mct != .lowercase
            }
        } else if special_to_include.contains(new_random_sel) {
            missing_char_types = missing_char_types.filter { mct in
                mct != .special
            }
        }
        (hasChar, password, _) = try removeChar(
            hasChar: hasChar, password: password, special: special_to_include)
        password.append(new_random_sel)
    }

    if separator == .dash {
        return password.joined(separator: "-")
    } else if separator == .underscore {
        return password.joined(separator: "_")
    } else if separator == .comma {
        return password.joined(separator: ",")
    } else if separator == .period {
        return password.joined(separator: ".")
    } else if separator == .random {
        return password.joined(separator: String(SEPARATORS.randomElement()!))
    } else {
        return password.joined(separator: "")
    }

}
