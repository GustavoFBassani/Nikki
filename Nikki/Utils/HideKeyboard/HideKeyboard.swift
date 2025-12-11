//
//  HideKeyboard.swift
//  Nikki
//
//  Created by Rafael Toneto on 11/12/25.
//

import SwiftUI

extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                        to: nil, from: nil, for: nil)
    }
}
