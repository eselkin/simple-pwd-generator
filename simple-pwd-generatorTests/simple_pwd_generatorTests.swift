//
//  simple_pwd_generatorTests.swift
//  simple-pwd-generatorTests
//
//  Created by Eli Selkin on 7/19/24.
//

import Foundation
import Testing

@testable import simple_pwd_generator

@Suite("Individual subcomponents")
struct subcomponentTests {
    @Test func testDictionaryCreation() async {
        let dictionaries = Dictionaries()
        #expect(dictionaries.english.count == 274926)
    }
    @Test func randomCharacterWithNumber() async throws {
        let randomchar = random_character(
            characters_to_include: [.number], special_to_include: "")
        let regex = try NSRegularExpression(
            pattern: "^[0-9]$")
        #expect(
            regex.firstMatch(in: randomchar, range: NSMakeRange(0, 1)) != nil)
    }
    @Test func randomCharacterWithLC() async throws {
        let randomchar = random_character(
            characters_to_include: [.lowercase], special_to_include: "")
        let regex = try NSRegularExpression(
            pattern: "^[a-z]$")
        #expect(
            regex.firstMatch(in: randomchar, range: NSMakeRange(0, 1)) != nil)
    }
    @Test func randomCharacterWithUC() async throws {
        let randomchar = random_character(
            characters_to_include: [.uppercase], special_to_include: "")
        let regex = try NSRegularExpression(
            pattern: "^[A-Z]$")
        #expect(
            regex.firstMatch(in: randomchar, range: NSMakeRange(0, 1)) != nil)
    }
    @Test func randomCharacterWithSpecial() async throws {
        let randomchar = random_character(
            characters_to_include: [.special], special_to_include: ".,")
        let regex = try NSRegularExpression(
            pattern: "^[.,]$")
        #expect(
            regex.firstMatch(in: randomchar, range: NSMakeRange(0, 1)) != nil)
    }
    @Test func removeCharLargestTooSmall() async throws {
        let password = ["a", "A"]
        let hasChar: [PASSWORD_CHARACTER_INCLUDES: Int] = [
            .lowercase: 1, .uppercase: 1,
        ]
        #expect(throws: PasswordCreationError.tooManyConstraints) {
            let (_, _, _) = try removeChar(
                hasChar: hasChar, password: password, special: "")
        }
    }
    @Test func removeCharLargestUC() async throws {
        let password = ["a", "A", "B"]
        let hasChar: [PASSWORD_CHARACTER_INCLUDES: Int] = [
            .lowercase: 1, .uppercase: 2,
        ]
        let (_, _, removed) = try removeChar(
            hasChar: hasChar, password: password, special: "")
        #expect(UPPERCASE.contains(removed))
    }
    @Test func removeCharLargestLC() async throws {
        let password = ["a", "b", "B"]
        let hasChar: [PASSWORD_CHARACTER_INCLUDES: Int] = [
            .lowercase: 2, .uppercase: 1,
        ]
        let (_, _, removed) = try removeChar(
            hasChar: hasChar, password: password, special: "")
        #expect(LOWERCASE.contains(removed))
    }
    @Test func removeCharLargestNUM() async throws {
        let password = ["1", "2", "B"]
        let hasChar: [PASSWORD_CHARACTER_INCLUDES: Int] = [
            .number: 2, .uppercase: 1,
        ]
        let (_, _, removed) = try removeChar(
            hasChar: hasChar, password: password, special: "")
        #expect(NUMBERS.contains(removed))
    }
    @Test func removeCharLargestSP() async throws {
        let special = ".,!"
        let password = [".", ",", "B"]
        let hasChar: [PASSWORD_CHARACTER_INCLUDES: Int] = [
            .special: 2, .uppercase: 1,
        ]
        let (_, _, removed) = try removeChar(
            hasChar: hasChar, password: password, special: special)
        #expect(special.contains(removed))
    }
    @Test func removeCharLargestCannotFind() async throws {
        let password = ["a", "b", "B"]
        let hasChar: [PASSWORD_CHARACTER_INCLUDES: Int] = [
            .special: 2, .uppercase: 1,
        ]
        #expect(
            throws: PasswordCreationError
                .couldNotFindIndexOfMostFrequentCharacterType
        ) {
            let (_, _, _) = try removeChar(
                hasChar: hasChar, password: password, special: "!.")
        }
    }

}
@Suite("Test creation of passwords")
struct completePasswordTests {
    var dictionaries = Dictionaries()

    @Test func threeWordPasswordSepUnderscoreMinWordLength8() async throws {
        let generatedPassword = try password_gen(
            characters_to_include: [], special_to_include: "",
            password_type: .words, length: 3, separator: .underscore,
            minWordLength: 8)
        let regex = try NSRegularExpression(
            pattern: "[a-zA-Z]{8,}[_][a-zA-Z]{8,}[_][a-zA-Z]{8,}")
        #expect(
            regex.firstMatch(
                in: generatedPassword, options: [],
                range: NSMakeRange(0, generatedPassword.count)) != nil)
    }
    @Test func fourWordPasswordSepDashMinWordLength9() async throws {
        let generatedPassword = try password_gen(
            characters_to_include: [], special_to_include: "",
            password_type: .words, length: 4, separator: .dash, minWordLength: 9
        )
        let regex = try NSRegularExpression(
            pattern: "[a-zA-Z]{9,}[-][a-zA-Z]{9,}[-][a-zA-Z]{9,}[-][a-zA-Z]{9,}"
        )
        #expect(
            regex.firstMatch(
                in: generatedPassword, options: [],
                range: NSMakeRange(0, generatedPassword.count)) != nil)
    }
    @Test func threeWordPasswordSepCommaMinWordLength10() async throws {
        let generatedPassword = try password_gen(
            characters_to_include: [], special_to_include: "",
            password_type: .words, length: 3, separator: .comma,
            minWordLength: 10)
        let regex = try NSRegularExpression(
            pattern: "[a-zA-Z]{10,}[,][a-zA-Z]{10,}[,][a-zA-Z]{10,}")
        #expect(
            regex.firstMatch(
                in: generatedPassword, options: [],
                range: NSMakeRange(0, generatedPassword.count)) != nil)
    }
    @Test func threeWordPasswordSepPeriodMinWordLength12() async throws {
        let generatedPassword = try password_gen(
            characters_to_include: [], special_to_include: "",
            password_type: .words, length: 3, separator: .period,
            minWordLength: 12)
        let regex = try NSRegularExpression(
            pattern: "[a-zA-Z]{12,}[.][a-zA-Z]{12,}[.][a-zA-Z]{12,}")
        #expect(
            regex.firstMatch(
                in: generatedPassword, options: [],
                range: NSMakeRange(0, generatedPassword.count)) != nil)
    }
    @Test func threeRandCharPasswordSepPeriod() async throws {
        let generatedPassword = try password_gen(
            characters_to_include: [.lowercase], special_to_include: "!",
            password_type: .random_characters, length: 3, separator: .period,
            minWordLength: nil)
        let regex = try NSRegularExpression(pattern: "[a-z][.][a-z][.][a-z]")
        #expect(
            regex.firstMatch(
                in: generatedPassword, options: [],
                range: NSMakeRange(0, generatedPassword.count)) != nil)
    }
    @Test func threeRandSpecialCharPasswordSepPeriod() async throws {
        let generatedPassword = try password_gen(
            characters_to_include: [.special], special_to_include: "!,",
            password_type: .random_characters, length: 3, separator: .period,
            minWordLength: nil)
        let regex = try NSRegularExpression(pattern: "[!,][.][,!][.][,!]")
        #expect(
            regex.firstMatch(
                in: generatedPassword, options: [],
                range: NSMakeRange(0, generatedPassword.count)) != nil)
    }
    @Test func threeRandUpperCharPasswordSepPeriod() async throws {
        let generatedPassword = try password_gen(
            characters_to_include: [.uppercase], special_to_include: "!,",
            password_type: .random_characters, length: 3, separator: .period,
            minWordLength: nil)
        let regex = try NSRegularExpression(pattern: "[A-Z][.][A-Z][.][A-Z]")
        #expect(
            regex.firstMatch(
                in: generatedPassword, options: [],
                range: NSMakeRange(0, generatedPassword.count)) != nil)
    }
    @Test func fourRandCharPasswordSepRandom() async throws {
        let generatedPassword = try password_gen(
            characters_to_include: [.uppercase, .lowercase, .number, .special], special_to_include: "!",
            password_type: .random_characters, length: 5, separator: .random,
            minWordLength: nil)
        let regex = try NSRegularExpression(pattern: ".*[,._-].*[,._-].*")
        #expect(
            regex.firstMatch(
                in: generatedPassword, options: [],
                range: NSMakeRange(0, generatedPassword.count)) != nil)
    }

    @Test func tenRandMixedAlphaCharPasswordNoSep() async throws {
        let generatedPassword = try password_gen(
            characters_to_include: [.uppercase, .lowercase],
            special_to_include: ".,!", password_type: .random_characters,
            length: 10, separator: .none, minWordLength: nil)
        let regex = try NSRegularExpression(pattern: "^[a-zA-Z]{10}$")
        #expect(
            regex.firstMatch(
                in: generatedPassword, options: [],
                range: NSMakeRange(0, generatedPassword.count)) != nil)
    }
    @Test func twentyRandMixedAllCharPasswordNoSep() async throws {
        let generatedPassword = try password_gen(
            characters_to_include: [.uppercase, .lowercase, .number, .special],
            special_to_include: ".,!", password_type: .random_characters,
            length: 20, separator: .none, minWordLength: nil)
        let regex = try NSRegularExpression(pattern: "^[a-zA-Z0-9.,!]{20}$")
        #expect(
            regex.firstMatch(
                in: generatedPassword, options: [],
                range: NSMakeRange(0, generatedPassword.count)) != nil)
    }
    @Test func threeOddRandMixedAllCharPasswordNoSep() {
        // All 100 should fail with the exception, this way we know it always fails in any potential given scenario where the characters to include set is larger than the number of characters available
        for _ in 0..<100 {
            #expect(throws: PasswordCreationError.tooManyConstraints) {
                try password_gen(
                    characters_to_include: [
                        .uppercase, .lowercase, .number, .special,
                    ], special_to_include: ".,!",
                    password_type: .random_characters, length: 3,
                    separator: .none, minWordLength: nil)
            }
        }
    }
    @Test func threeWordsThatAreTooBig() {
        #expect(throws: PasswordCreationError.tooFewWordsToSelectFrom) {
            try password_gen(
                characters_to_include: [], special_to_include: "",
                password_type: .words, length: 3,
                separator: .none, minWordLength: 50)
        }
    }
}
