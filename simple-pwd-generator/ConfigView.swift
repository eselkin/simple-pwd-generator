//
//  ConfigView.swift
//  simple-pwd-generator
//
//  Created by Eli Selkin on 8/10/24.
//

import SwiftData
import SwiftUI

struct ConfigView: View {
    @AppStorage("pwuseendict") private var useEnglishDictionary: Bool = true
    @AppStorage("pwuseesdict") private var useSpanishDictionary: Bool = false
    @AppStorage("pwdonotusedifficult") private var doNotUseDifficult: Bool = false
    
    var body: some View {

        Form {
            Section(header: Text("Dictionaries")) {
                Toggle("English", isOn: $useEnglishDictionary).onChange(
                    of: useEnglishDictionary
                ) {
                    if !useEnglishDictionary && !useSpanishDictionary {
                        useEnglishDictionary = true
                    }
                }
                Toggle("Spanish", isOn: $useSpanishDictionary).onChange(
                    of: useSpanishDictionary
                ) {
                    if !useEnglishDictionary && !useSpanishDictionary {
                        useSpanishDictionary = true
                    }
                }
            }
            Section(header: Text("Confusing numbers and letters")) {
                Toggle(
                    "Do not use confusing numbers and letters (e.g. 01OIloS5s)",
                    isOn: $doNotUseDifficult)

            }
        }
    }
}
#Preview {
    ConfigView()
}
