//
//  dictionaries.swift
//  simple-pwd-generator
//
//  Created by Eli Selkin on 7/19/24.
//

import Foundation

struct Dictionaries {
    var english: [String.SubSequence] = []
    init() {
        if let filePath = Bundle.main.path(forResource: "en", ofType: "txt") {
            let fileData = try! String(contentsOfFile: filePath, encoding: .utf8)
            english = fileData.split(separator: "\n")
        }
    }
}
