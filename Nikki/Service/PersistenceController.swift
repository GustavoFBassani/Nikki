//
//  PersistenceController.swift
//  Nikki
//
//  Created by Alex Fraga on 28/03/26.
//

import SwiftData

final class PersistenceController {
    static let shared = PersistenceController()

    let container: ModelContainer

    private init() {
        do {
            // Single schema/container avoids table mismatch in default.store.
            container = try ModelContainer(for: Page.self, Motivation.self)
        } catch {
            fatalError("Erro ao criar ModelContainer compartilhado: \(error)")
        }
    }
}
