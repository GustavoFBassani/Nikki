//
//  RootView.swift
//  Nikki
//
//  Created by Rafael Toneto on 11/12/25.
//


import SwiftUI
import SwiftData

struct RootView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    private let dataContainer = PersistenceController.shared.container
    var body: some View {
        Group {
            if hasSeenOnboarding {
                #if os(visionOS)
                VisionOSLauncherView()
                #else
                SceneView()
                #endif
            } else {
                NavigationStack {
                    OnboardingFirstView()
                }
            }
        }
        .modelContainer(dataContainer)
    }
}

#if os(visionOS)
// ---------------------------------------------------------
// TELA DE LANÇAMENTO INVISÍVEL PARA VISIONOS
// ---------------------------------------------------------
// No visionOS, a primeira janela (o WindowGroup padrão do AppDelegate) é aberta automaticamente.
// Porém, nós não queremos que o usuário fique vendo uma janela 2D, nós queremos jogar ele 
// direto para o ImmersiveSpace (onde tem a árvore 3D no ambiente).
// O problema é que o ImmersiveSpace NÃO abre sozinho no momento em que o app inicia.
// 
// Para resolver isso, criamos essa 'VisionOSLauncherView'. Ela é a tela que vai aparecer
// dentro da primeira janela padrão.
struct VisionOSLauncherView: View {
    // Variáveis de ambiente nativas para controlar janelas e espaços
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissWindow) private var dismissWindow

    var body: some View {
        VStack {
            ProgressView("Carregando ambiente...")
        }
        .onAppear {
            Task {
                // Assim que essa tela invisível aparece, ela instantaneamente diz pro sistema:
                // "Por favor, abra o ImmersiveSpace com o ID 'TreeView' que está lá no AppDelegate"
                await openImmersiveSpace(id: "TreeView")
                
                // Depois que o espaço imersivo abrir com sucesso, nós mandamos fechar ESSA
                // janela 2D onde o ProgressView estava, deixando o usuário livre na sala com a árvore!
                dismissWindow()
            }
        }
    }
}
#endif
