//
//  EditorView.swift
//  POCCanvas
//
//  Created by Alex Fraga on 06/11/25.
//

import SwiftUI
import UIKit
import PaperKit

struct EditorView: View {
    // Tamanho da área do editor
    var size: CGSize
    // Referência ao EditorData (não cria novo State)
    @Bindable var canvasData: EditorData

    // Inicializador customizado (recebe tamanho e referência ao EditorData)
    init(size: CGSize, data: EditorData) {
        self.size = size
        self.canvasData = data
    }

    var body: some View {
        // Se já existe um controller inicializado...
        if let controller = canvasData.controller {
            // ...mostra o controller UIKit dentro do SwiftUI
            PaperControllerView(controller: controller)
        } else {
            // Caso ainda não tenha sido inicializado, mostra um loading
            ProgressView()
                .onAppear {
                    // Quando a tela aparece, inicializa o controller e markup
                    canvasData.initializeController(.init(origin: .zero, size: size))
                }
        }
    }
}

// MARK: - Representa o UIViewController do PaperKit dentro do SwiftUI
private struct PaperControllerView: UIViewControllerRepresentable {
    var controller: PaperMarkupViewController

    // Cria o UIViewController a partir do controller existente
    func makeUIViewController(context: Context) -> PaperMarkupViewController {
        controller
    }

    // Atualiza o UIViewController se o SwiftUI mudar algo (aqui não faz nada)
    func updateUIViewController(_ uiViewController: PaperMarkupViewController, context: Context) { }
    
    
}

#Preview {
    EditorView(size: .init(width: 390, height: 844), data: EditorData(data: .init(), paperStyle: "recycledPaper"))
}
