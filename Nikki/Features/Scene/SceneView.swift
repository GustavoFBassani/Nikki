//
//  SceneView.swift
//  Nikki
//
//  Created by Gustavo Ferreira bassani on 17/11/25.
//

import RealityKit
import SwiftData
import SwiftUI
import TipKit

struct SceneView: View {
    @Environment(SceneViewModel.self) var vm

    var body: some View {
        #if os(visionOS)
            VisionOSImmersiveSceneView()
        #else
            NormalSceneView()
        #endif
    }
}

struct NormalSceneView: View {

    @Environment(SceneViewModel.self) var vm
    @State private var showMotivationRoll = false
    @State private var isEditingMotivation = false
    @Environment(\.modelContext) var context
    @Query var pages: [Page]
    var DEBUG_SHOULD_DELETE = false

    var body: some View {
        @Bindable var vm = vm

        NavigationStack {
            ZStack {
                // RealityView para o conteúdo 3D
                RealityView { content in

                } update: { content in
                    // Durante o canvas aberto, a cena fica apenas desabilitada no ViewModel.
                    // Nao removemos entidades aqui para evitar tela branca no retorno.
                    if vm.isScenePaused {
                        return
                    }

                    // Relocates the scene when the canvas is dismissed
                    if let scene = vm.scene, content.entities.isEmpty {
                        content.add(scene)
                    }

                    if !vm.finishingResumeScene {
                        vm.finishingResumeScene = true
                    }
                }
                .edgesIgnoringSafeArea(.all)
                .allowsHitTesting(!showMotivationRoll)

            }
            .task {
                if vm.scene == nil {
                    await vm.loadScene()
                    try? await Task.sleep(nanoseconds: 200_000_000)
                    vm.repositioningCameraToTree()
                }

                vm.loadMotivation()

                if DEBUG_SHOULD_DELETE {
                    pages.forEach { page in
                        ///provisorio
                        context.delete(page)
                    }
                    try? context.save()
                }
                vm.evaluateTipsVisibility()

                // Começa o áudio ambiente conforme o clima assim que a cena aparece.
                vm.startEnvironment()
            }
            .gesture(
                /// DragGesture permite detectar movimento de um dedo na tela
                /// Usado para rotacionar a câmera orbital
                ///
                /// **Fluxo:**
                /// 1. Usuário toca e arrasta
                /// 2. onChanged é chamado continuamente durante o movimento
                /// 3. Calcula a diferença entre posição atual e última
                /// 4. Passa os deltas (dx, dy) para o ViewModel rotacionar a câmera
                /// 5. onEnded reseta a posição ao soltar o dedo
                DragGesture()
                    .onChanged { value in
                        guard !vm.isFocusedOnBandstand else { return }
                        // Na primeira chamada, apenas salva a posição inicial
                        if vm.lastDragPosition == .zero {
                            vm.lastDragPosition = value.location
                            return
                        }

                        // Calcula quanto o dedo se moveu desde o último frame
                        // dTheta: movimento horizontal (+ = direita, - = esquerda)
                        let dTheta = Float(
                            value.location.x - vm.lastDragPosition.x
                        )
                        // dPhi: movimento vertical (+ = baixo, - = cima)
                        let dPhi = Float(
                            value.location.y - vm.lastDragPosition.y
                        )

                        // Envia os deltas para o ViewModel atualizar theta e phi
                        vm.rotate(dTheta: dTheta, dPhi: dPhi)
                        // Atualiza a última posição para o próximo frame
                    }
                    .onEnded { _ in
                        // Reseta a posição quando o usuário solta o dedo
                        // Prepara para o próximo gesto
                        vm.lastDragPosition = .zero
                    }
            )  // movimentar para o lado
            .gesture(
                // MARK: - Gesto de Zoom (Pinch)

                /// MagnificationGesture detecta movimento de pinça com dois dedos
                /// Usado para controlar a distância da câmera (zoom)
                ///
                /// **Fluxo:**
                /// 1. Usuário coloca dois dedos na tela
                /// 2. `onChanged` é chamado enquanto afasta/aproxima os dedos
                /// 3. Calcula a escala acumulada
                /// 4. Passa a escala para o ViewModel calcular nova distância
                /// 5. `onEnded` salva a escala final para o próximo gesto
                MagnificationGesture()
                    .onChanged { value in
                        vm.currentScale = vm.lastScale * value
                        vm.zoom(scale: Float(vm.currentScale))
                    }
                    .onEnded { _ in
                        vm.lastScale = vm.currentScale
                    }
            )  // zoom
            .navigationDestination(
                item: $vm.openCanvasWithStyle,
                destination: { style in
                    CanvasView(
                        page: vm.currentPage,
                        paperStyle: style,
                        addNewTsuru: vm.parseCanvasDateAndAddNewTsuruAtScene,
                        reloadTsurus: vm.deleteTsurusAtScene,
                        onCanvasAppear: { vm.setScenePaused(true) },
                        onCanvasWillDismiss: {
                            vm.setScenePaused(false)
                            await vm.waitUntilSceneResumed()
                        },
                        onCanvasDisappear: { vm.setScenePaused(false) }
                    )
                }
            )
            .navigationDestination(isPresented: $vm.showCredits) { CreditsView() }
            .simultaneousGesture(
                TapGesture()
                    .targetedToAnyEntity()
                    .onEnded { value in
                        vm.handleTap(on: value.entity)
                        Task {
                            vm.isCameraNotMoving = false
                            try? await Task.sleep(nanoseconds: 1_200_000_000)
                            vm.isCameraNotMoving = true
                        }
                    }
            )  // tocar nos objetos
            .onChange(of: vm.isFocusedOnBandstand) { _, newValue in
                if newValue {
                    //focou no coreto
                    showMotivationRoll = false
                    isEditingMotivation = false

                    Task {
                        try? await Task.sleep(nanoseconds: 1_000_500_000)

                        // só mostra se ainda estiver focado no coreto
                        if vm.isFocusedOnBandstand {
                            await MainActor.run {
                                withAnimation(.easeInOut) {
                                    showMotivationRoll = true
                                }
                            }
                        }
                    }
                } else {
                    //saiu do foco no coreto, some na hora
                    withAnimation(.easeOut) {
                        showMotivationRoll = false
                        isEditingMotivation = false
                    }
                }
            }
            .overlay(alignment: .topTrailing) {
                // Só mostra o + quando a cena carregou e NÃO está focado no tsuru nem no coreto
                if vm.scene != nil, !(vm.isFocusedOnTsuru || vm.isFocusedOnBandstand) {
                    VStack(alignment: .trailing, spacing: 8) {

                        Menu {
                            ForEach(PaperStyles.allCases, id: \.self) { style in
                                Button {
                                    vm.openCanvasWithStyle = style.name
                                } label: {
                                    Text(style.title)
                                        .font(.custom("CaveatBrush-Regular", size: 5))
                                }
                            }

                            // MOCK APRESENTAÇÃO - REMOVER DEPOIS
                            Button("Alternar dia/noite") { vm.mockToggleDayPeriod() }
                            Button("Mudar clima") { vm.mockCycleWeather() }

                        } label: {
                            Image("customPlus")
                                .scaledToFit()
                                .frame(width: 44, height: 44)
                                .background(
                                    RoundedRectangle(cornerRadius: 999)
                                        .fill(Color.white.opacity(0.85))
                                )
                        }
                        .padding(.trailing, 16)
                        .padding(.top, 26)

                        // tip popup
                        if vm.showNewPageTip {

                            ZStack(alignment: .topTrailing) {
                                TipView(vm.newPageTip)
                                    .tipViewStyle(BubbleTipStyle())
                                    .tipBackground(.clear)
                                    .padding(.trailing, 16)

                                Button {
                                    vm.dismissNewPageTip()
                                } label: {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.gray)
                                        .padding(8)
                                        .font(.custom("CaveatBrush-Regular", size: 5))
                                }
                                .padding(.trailing, 32)
                                .padding(.top, 20)
                            }

                        }

                    }
                } else if vm.isFocusedOnTsuru {
                    Button {
                        vm.openTsuru()
                    } label: {
                        Text(StringCatalog.openOrigami)
                            .font(Fonts.Footnote)
                            .foregroundColor(.blueNikki)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 999)
                                    .fill(Color.white.opacity(0.85))
                            )
                            .padding(.trailing, 16)
                            .padding(.top, 24)
                    }

                }

            }  //  custom xmark toolbar
            .overlay(alignment: .bottom) {
                if vm.isFocusedOnTsuru {
                    OrigamiSelectorToolBar(
                        selectedDate: vm.selectedPage?.createdAt ?? Date(),
                        thereIsTsuruAtRight: vm.thereIsTsuruAtRight,
                        thereIsTsuruAtLeft: vm.thereIsTsuruAtLeft,
                        navigateToTsuru: vm.navigateToTsuru
                    )
                    .padding(.bottom, 32)
                    .transition(.move(edge: .bottom))
                }

            }  // custom data and chevrons tabbar
            .overlay(alignment: .bottomLeading) {
                if vm.scene != nil, !vm.isFocusedOnTsuru, !vm.isFocusedOnBandstand {
                    VStack(alignment: .leading, spacing: 8) {

                        if vm.showFocusTsuruTip {
                            ZStack(alignment: .topTrailing) {
                                TipView(vm.focusTsuruTip)
                                    .tipViewStyle(BottomLeftBubbleTipStyle())
                                    .tipBackground(.clear)

                                Button {
                                    vm.dismissFocusTsuruTip()

                                } label: {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.gray)
                                        .padding(8)
                                }
                                .padding(.trailing, 8)
                                .padding(.top, 12)

                            }
                            .offset(x: 18)
                        }

                        Button {
                            if !vm.orderedPages.isEmpty {
                                vm.repositioningCameraToTsuru(vm.pickLastTsuru())
                            }

                            Task {
                                vm.isCameraNotMoving = false
                                try? await Task.sleep(nanoseconds: 700_000_000)
                                vm.isCameraNotMoving = true
                            }

                        } label: {
                            Image(systemName: "location")
                                .foregroundStyle(.blueNikki)
                                .font(Fonts.Footnote)
                                .frame(width: 44, height: 44)
                                .background(Circle().fill(Color.white.opacity(0.85)))
                        }
                        .padding(.leading, 20)
                        .disabled(vm.isCamerMovingToTree)
                    }
                } else {

                }
            }
            .overlay {
                if showMotivationRoll {
                    MotivationRoll(
                        motivation: $vm.motivationText,
                        isEditing: isEditingMotivation
                    )
                    .padding(
                        EdgeInsets(
                            top: 423,
                            leading: 46,
                            bottom: 156,
                            trailing: 38
                        )
                    )
                    .contentShape(Rectangle())  // garante área de toque
                    .onTapGesture {
                        withAnimation(.easeInOut) {
                            isEditingMotivation = true
                        }
                    }
                    .zIndex(1)
                }
            }
            .overlay(alignment: .topLeading) {
                if vm.isFocusedOnBandstand || vm.isFocusedOnTsuru {
                    Button {
                        vm.repositioningCameraToTree()
                        vm.isFocusedOnBandstand = false
                        isEditingMotivation = false
                        vm.saveMotivation()

                        Task {
                            vm.isCamerMovingToTree = true
                            try? await Task.sleep(
                                nanoseconds: 1_200_000_000
                            )
                            vm.isCamerMovingToTree = false
                        }

                    } label: {
                        Image("customXmark")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                            .padding(8)
                            .background(
                                Circle()
                                    .fill(Color.white.opacity(0.85))
                            )
                    }
                    .padding(.leading, 16)
                    .padding(.top, 24)
                    .zIndex(3)
                }
            }
            .overlay {
                // Loading enquanto a cena 3D é montada pela primeira vez
                if vm.scene == nil {
                    ProgressView()
                        .controlSize(.large)
                        .tint(.white)
                }
            }
            .sensoryFeedback(.impact, trigger: vm.selectedPage)

        }
        .navigationBarBackButtonHidden(true)
    }
}

#if os(visionOS)
    // ---------------------------------------------------------
    // TELA TOTALMENTE IMERSIVA PARA VISIONOS
    // ---------------------------------------------------------
    struct VisionOSImmersiveSceneView: View {
        @Environment(SceneViewModel.self) var vm
        @Environment(\.openWindow) private var openWindow
        @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace

        @State private var isPaperMenuOpen = false

        var body: some View {
            RealityView { content, attachments in
                if let scene = vm.scene {
                    content.add(scene)
                }

                if let buttonNextTsuru = attachments.entity(for: "moveToLeftTsuru") {
                    buttonNextTsuru.position = [-1.48, -0.2, 6.4]
                    buttonNextTsuru.isEnabled = false
                    content.add(buttonNextTsuru)
                }

                if let buttonPreviousTsuru = attachments.entity(for: "moveToRightTsuru") {
                    buttonPreviousTsuru.position = [-1.435, -0.2, 6.4]
                    buttonPreviousTsuru.isEnabled = false
                    content.add(buttonPreviousTsuru)
                }

                if let doneBtn = attachments.entity(for: "doneTsuruTab") {
                    doneBtn.position = [-1.55, -0.2, 6.4]
                    doneBtn.isEnabled = false
                    content.add(doneBtn)
                }

                if let bg = attachments.entity(for: "tabBarBackground") {
                    bg.position = [-1.5, -0.2, 6.39999]  // Ligeiramente atrás para o efeito de fundo
                    bg.isEnabled = false
                    content.add(bg)
                }

                if let buttonScrapMenu = attachments.entity(for: "ScrapMenu") {
                    buttonScrapMenu.position = [-1.3, 0, 6]
                    content.add(buttonScrapMenu)
                }

                if let exitImmersiveButton = attachments.entity(for: "ExitImmersiveButton") {
                    exitImmersiveButton.position = [0.5, 0, 6]
                    exitImmersiveButton.orientation = simd_quatf(angle: -.pi / 3, axis: [0, 1, 0])
                    exitImmersiveButton.isEnabled = vm.isNearBridge
                    content.add(exitImmersiveButton)
                }

            } update: { content, attachments in

                // Dummy read: força o bloco update a rodar quando o tsuru muda
                _ = vm.selectedPage

                if let scene = vm.scene, scene.parent == nil {
                    content.add(scene)
                }

                if let buttonNextTsuru = attachments.entity(for: "moveToLeftTsuru") {
                    buttonNextTsuru.isEnabled =
                        vm.isFocusedOnTsuru && vm.thereIsTsuruAtLeft && !vm.isCanvasPresented
                }

                if let buttonPreviousTsuru = attachments.entity(for: "moveToRightTsuru") {
                    buttonPreviousTsuru.isEnabled =
                        vm.isFocusedOnTsuru && vm.thereIsTsuruAtRight && !vm.isCanvasPresented
                }

                if let doneBtn = attachments.entity(for: "doneTsuruTab") {
                    doneBtn.isEnabled = vm.isFocusedOnTsuru && !vm.isCanvasPresented
                }

                if let bg = attachments.entity(for: "tabBarBackground") {
                    bg.isEnabled = vm.isFocusedOnTsuru && !vm.isCanvasPresented
                }

                if let buttonScrapMenu = attachments.entity(for: "ScrapMenu") {
                    buttonScrapMenu.isEnabled = vm.isLookingAtTree && !vm.isFocusedOnTsuru
                }

                if let exitImmersiveButton = attachments.entity(for: "ExitImmersiveButton") {
                    exitImmersiveButton.isEnabled = vm.isNearBridge
                }

            } attachments: {

                Attachment(id: "ScrapMenu") {
                    VisionScrapMenu(
                        isPaperMenuOpen: $isPaperMenuOpen,
                        onVisualizeOrigamis: {
                            vm.isLookingAtTree = false
                            if !vm.orderedPages.isEmpty {
                                vm.repositioningCameraToTsuru(vm.pickLastTsuru())
                            }

                            Task {
                                vm.isCameraNotMoving = false
                                try? await Task.sleep(nanoseconds: 700_000_000)
                                vm.isCameraNotMoving = true
                            }
                        },
                        onSelectStyle: { style in
                            vm.isLookingAtTree = false
                            isPaperMenuOpen = false
                            openWindow(
                                id: "CanvasWindow",
                                value: style
                            )
                        },
                        // MOCK APRESENTAÇÃO - REMOVER DEPOIS
                        onMockToggleDayPeriod: { vm.mockToggleDayPeriod() },
                        onMockCycleWeather: { vm.mockCycleWeather() }
                    )
                }

                Attachment(id: "ExitImmersiveButton") {
                    ExitImmersiveButton {
                        Task { @MainActor in
                            // Reabrir a janela antes de fechar o espaco, senao o
                            // app fica sem nenhuma cena aberta e e suspenso.
                            openWindow(id: "Launcher")
                            await dismissImmersiveSpace()
                            vm.isNearBridge = false
                        }
                    }
                }

                Attachment(id: "moveToLeftTsuru") {
                    Button {
                        vm.navigateToTsuru(at: "left")
                    } label: {
                        Image(systemName: "chevron.left")
                            .frame(width: 52, height: 52)
                            .background(.thinMaterial, in: Circle())
                    }
                    .buttonStyle(.plain)
                    .padding(16)
                }  // ESSE AQUI JA TEM O DESIGN OFICIAL

                Attachment(id: "moveToRightTsuru") {
                    Button {
                        vm.navigateToTsuru(at: "right")
                    } label: {
                        Image(systemName: "chevron.right")
                            .frame(width: 52, height: 52)
                            .background(.thinMaterial, in: Circle())
                    }
                    .buttonStyle(.plain)
                    .padding(16)
                }  // ESSE AQUI JA TEM O DESIGN OFICIAL

                Attachment(id: "doneTsuruTab") {
                    Button {
                        vm.repositioningCameraToTree()
                        vm.isFocusedOnBandstand = false
                        vm.saveMotivation()
                    } label: {
                        Text("Done")
                            .padding(.horizontal, 20)
                            .padding(.vertical, 14)
                            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 500))
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)
                    .padding(16)
                }

                Attachment(id: "tabBarBackground") {
                    Color.clear
                        .frame(width: 280, height: 84)
                        .glassBackgroundEffect(
                            in: RoundedRectangle(cornerRadius: 42)
                        )
                }

            }
            .gesture(
                SpatialTapGesture()
                    .targetedToAnyEntity()
                    .onEnded { value in
                        let clickedEntity = value.entity

                        if value.entity.name == "v176CherryTree02_Shape_v176CherryFlower_0"
                            || value.entity.name == "v176CherryTree02_Shape_v176CherryBranch01_0"
                        {
                            vm.isLookingAtTree.toggle()
                        } else if !vm.handleBridgeTap(on: clickedEntity) {
                            let page =
                                vm.dict[clickedEntity] ?? vm.dict.first(where: {
                                    $0.key.parent == clickedEntity
                                })?.value
                                ?? (clickedEntity.parent != nil
                                    ? vm.dict[clickedEntity.parent!] : nil)

                            if let page {
                                vm.currentPage = page

                                let style = page.paperStyle ?? "Papel em Branco"
                                openWindow(id: "CanvasWindow", value: style)
                            }
                        }
                    }
            )
            .gesture(
                SpatialTapGesture()
                    .targetedToAnyEntity()
                    .onEnded { value in
                        vm.handleTap(on: value.entity)
                    }
            )
            .task {
                if vm.scene == nil {
                    await vm.loadScene()
                    vm.repositioningCameraToTree(animated: true)
                }

                vm.loadMotivation()
                vm.evaluateTipsVisibility()

                // Começa o áudio ambiente conforme o clima assim que a cena aparece.
                vm.startEnvironment()
            }

        }
    }
#endif

#Preview {
    SceneView()
        .environment(SceneViewModel())
}
