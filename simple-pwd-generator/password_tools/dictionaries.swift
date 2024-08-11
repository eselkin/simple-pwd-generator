//
//  dictionaries.swift
//  simple-pwd-generator
//
//  Created by Eli Selkin on 7/19/24.
//

import Foundation

struct Dictionaries {
    var english: [String.SubSequence] = []
    var spanish: [String.SubSequence] = []
    init() {
        if let filePathEn = Bundle.main.path(forResource: "en", ofType: "txt") {
            let fileData = try! String(contentsOfFile: filePathEn, encoding: .utf8)
            english = fileData.split(separator: "\n")
        }
        if let filePathEs = Bundle.main.path(forResource: "es", ofType: "txt") {
            let fileData = try! String(contentsOfFile: filePathEs, encoding: .utf8)
            spanish = fileData.split(separator: "\n")
        }
    }
}
