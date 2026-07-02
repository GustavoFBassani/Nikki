//
//  AppDelegate.swift
//  Nikki
//
//  Created by Gustavo Ferreira bassani on 17/11/25.
//

import UIKit
import SwiftUI
import SwiftData
import TipKit

class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]?
    ) -> Bool {

        do {
            try Tips.configure()
        } catch {
            print("Failed to configure TipKit: \(error)")
        }

        let rootView = RootView()

        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            return false
        }

        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = UIHostingController(rootView: rootView)
        self.window = window
        window.makeKeyAndVisible()

        return true
    }

    func applicationWillResignActive(_ application: UIApplication) { }
    func applicationDidEnterBackground(_ application: UIApplication) { }
    func applicationWillEnterForeground(_ application: UIApplication) { }
    func applicationDidBecomeActive(_ application: UIApplication) { }
}

@main
struct NikkiApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    private let dataContainer = PersistenceController.shared.container
    @State private var sceneVM = SceneViewModel()
    
    // O 'body' do App sempre retorna uma 'Scene' (Cena).
    // É aqui que dizemos ao iOS/visionOS quais tipos de janelas ou ambientes nosso app tem.
    var body: some Scene {
        
        // ---------------------------------------------------------
        // 1. A JANELA PRINCIPAL (WindowGroup)
        // ---------------------------------------------------------
        // O WindowGroup é o contêiner padrão do SwiftUI. No iOS, ele representa a tela inteira do celular.
        // No visionOS, ele representa uma janela 2D de vidro que flutua no espaço.
        // Como não passamos nenhum 'id' pra ele, ele é considerado a "Janela Principal e Padrão" do app.
        // É a primeira coisa que o sistema tenta abrir quando você clica no ícone do aplicativo.
        WindowGroup {
            RootView() // A tela que vai aparecer dentro dessa janela
                .environment(sceneVM) // Passando nosso ViewModel para todas as telas filhas
        }
        // O .modelContainer conecta o banco de dados (SwiftData) a essa janela,
        // para que qualquer @Query lá dentro consiga ler e salvar dados.
        .modelContainer(dataContainer)

        // As linhas abaixo só serão compiladas e existirão se o app estiver rodando no visionOS.
        #if os(visionOS)
        // .plain remove o vidro padrão do sistema, para que a própria view controle o
        // vidro colorido via .background(Color...opacity) + .glassBackgroundEffect().
        // .defaultSize define o tamanho inicial da janela 2D flutuante.
        .windowStyle(.plain)
        .defaultSize(width: 1280, height: 720)
        // .contentSize faz a janela física acompanhar o tamanho do conteúdo.
        // Assim, quando a VisionSplashView anima a largura do frame,
        // a própria janela do visionOS se abre lateralmente junto.
        .windowResizability(.contentSize)
        #endif

        #if os(visionOS)
        
        // ---------------------------------------------------------
        // 2. A JANELA SECUNDÁRIA (WindowGroup com 'id' e 'for')
        // ---------------------------------------------------------
        // Aqui estamos declarando uma janela EXTRA. Nós damos um `id: "CanvasWindow"`
        // para que possamos pedir para o sistema abri-la futuramente usando:
        // openWindow(id: "CanvasWindow", value: "craft")
        WindowGroup(id: "CanvasWindow", for: String.self) { $style in
            
            // O parâmetro 'for: String.self' e o '$style' servem para passar dados pra janela.
            // Quando pedimos pro sistema abrir essa janela, nós também mandamos um texto (String)
            // dizendo qual o estilo do papel (ex: "craft", "notebook"). O SwiftUI recebe isso
            // e injeta na variável '$style' para montarmos a tela correta.
            if let style = style {
                CanvasWindowWrapper(style: style) // A tela de desenho que vai renderizar o papel
                    .environment(sceneVM) // Injetando o nosso ViewModel global aqui também
            }
        }
        .modelContainer(dataContainer) // Dando acesso ao banco de dados para a tela de desenho
        
        // ---------------------------------------------------------
        // 3. O ESPAÇO IMERSIVO (ImmersiveSpace)
        // ---------------------------------------------------------
        // ImmersiveSpace é uma 'Cena' exclusiva do visionOS. Em vez de criar uma janelinha de vidro,
        // ele pega os seus elementos 3D (RealityView) e joga eles no mundo físico do usuário.
        // Nós damos um `id: "TreeView"` para que possamos "invocá-lo" programaticamente
        // de dentro de outra view usando: await openImmersiveSpace(id: "TreeView").
        ImmersiveSpace(id: "TreeView") {
            SceneView() // A tela que carrega a nossa árvore 3D no RealityView
                .environment(sceneVM)
        }
        .modelContainer(dataContainer) // Dando acesso ao banco de dados (caso a árvore use)
        
        // O immersionStyle dita como o fundo dessa cena vai se comportar.
        // - '.mixed': A árvore se mistura com a sala real do usuário (Realidade Aumentada)
        // - '.full': Esconderia a sala do usuário e criaria um mundo de Realidade Virtual.
        // Ao colocar (.constant(.full), in: .mixed, .full), estamos dizendo pro sistema quais
        // estilos nós damos suporte, permitindo que a Coroa Digital (Digital Crown) do óculos
        // controle o quanto o usuário quer mergulhar na experiência.
        .immersionStyle(selection: .constant(.mixed), in: .mixed, .full)
        #endif
    }
}
