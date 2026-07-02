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
                        // Atualiza a última posição para o próximo gesto
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
            ) // zoom
            .navigationDestination(item: $vm.openCanvasWithStyle, destination: { style in
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
            })
            .navigationDestination(isPresented: $vm.showCredits) {
                CreditsView()
            }
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
                // Só mostra o + quando NÃO está focado no tsuru e NÃO está focado no coreto
                if !(vm.isFocusedOnTsuru || vm.isFocusedOnBandstand) {
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
                if !vm.isFocusedOnTsuru && !vm.isFocusedOnBandstand {
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
                            try? await Task.sleep(nanoseconds: 1_200_000_000)
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

    @State private var isPaperMenuOpen = false
    @State private var isVisionHUDVisible = true

    private let visionMenuAnchorName = "visionMenuAnchor"
    private let focusOnTsuruAnchorName = "focusOnTsuruAnchor"
    private let removeFocusOnTsuruAnchorName = "removeFocusOnTsuruAnchor"
    private let moveToLeftTsuruAnchorName = "moveToLeftTsuruAnchor"
    private let moveToRightTsuruAnchorName = "moveToRightTsuruAnchor"

    private var visionHUDAnchorNames: [String] {
        [
            visionMenuAnchorName,
            focusOnTsuruAnchorName,
            removeFocusOnTsuruAnchorName,
            moveToLeftTsuruAnchorName,
            moveToRightTsuruAnchorName
        ]
    }

    var body: some View {
        RealityView { content, attachments in
            if let scene = vm.scene {
                content.add(scene)
            }

            updateVisionHUD(content: content, attachments: attachments)

        } update: { content, attachments in

            // Dummy read: força o bloco update a rodar quando o tsuru muda
            _ = vm.selectedPage
            _ = vm.isFocusedOnTsuru
            _ = vm.thereIsTsuruAtLeft
            _ = vm.thereIsTsuruAtRight

            if let scene = vm.scene, scene.parent == nil {
                content.add(scene)
            }

            updateVisionHUD(content: content, attachments: attachments)

        } attachments: {
            Attachment(id: "visionMenu") {
                if isVisionHUDVisible {
                    VisionScrapMenu(
                        isPaperMenuOpen: $isPaperMenuOpen,
                        onVisualizeOrigamis: {
                            if !vm.orderedPages.isEmpty {
                                vm.repositioningCameraToTsuru(vm.pickLastTsuru())
                            }

                            Task {
                                vm.isCameraNotMoving = false
                                try? await Task.sleep(nanoseconds: 700_000_000)
                                vm.isCameraNotMoving = true
                            }
                        },
                        onSelectStyle: { styleName in
                            isPaperMenuOpen = false
                            isVisionHUDVisible = false

                            openWindow(
                                id: "CanvasWindow",
                                value: styleName
                            )
                        }
                    )
                }
            }

            Attachment(id: "focusOnTsuru") {
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
                    Image("customPlus")
                        .scaledToFit()
                        .frame(width: 44, height: 44)
                        .background(
                            RoundedRectangle(cornerRadius: 22)
                                .fill(Color.white.opacity(0.85))
                        )
                }
            }

            Attachment(id: "removeFocusOnTsuru") {
                Button {
                    vm.repositioningCameraToTree()
                    vm.isFocusedOnBandstand = false
                    vm.saveMotivation()

                } label: {
                    Image(systemName: "xmark")
                        .scaledToFit()
                        .frame(width: 44, height: 44)
                        .background(
                            RoundedRectangle(cornerRadius: 22)
                                .fill(Color.white.opacity(0.85))
                        )
                        .foregroundStyle(.black)
                }
            }

            Attachment(id: "moveToLeftTsuru") {
                Button {
                    vm.navigateToTsuru(at: "left")
                } label: {
                    Image(systemName: "chevron.left")
                        .scaledToFit()
                        .frame(width: 44, height: 44)
                        .background(
                            RoundedRectangle(cornerRadius: 22)
                                .fill(Color.white.opacity(0.85))
                        )
                        .foregroundStyle(.black)
                }
            }

            Attachment(id: "moveToRightTsuru") {
                Button {
                    vm.navigateToTsuru(at: "right")

                } label: {
                    Image(systemName: "chevron.right")
                        .scaledToFit()
                        .frame(width: 44, height: 44)
                        .background(
                            RoundedRectangle(cornerRadius: 22)
                                .fill(Color.white.opacity(0.85))
                        )
                        .foregroundStyle(.black)
                }
            }
        }
        .task {
            if vm.scene == nil {
                await vm.loadScene()
                vm.repositioningCameraToTree(animated: true)
            }

            vm.loadMotivation()
            vm.evaluateTipsVisibility()
        }
    }

    private func updateVisionHUD(
        content: RealityViewContent,
        attachments: RealityViewAttachments
    ) {
        guard isVisionHUDVisible else {
            removeVisionHUD(from: content)
            return
        }

        updateHeadAttachment(
            content: content,
            attachments: attachments,
            id: "visionMenu",
            anchorName: visionMenuAnchorName,
            position: [0, -0.25, -0.85]
        )

        updateHeadAttachment(
            content: content,
            attachments: attachments,
            id: "focusOnTsuru",
            anchorName: focusOnTsuruAnchorName,
            position: [0.5, -0.3, -0.8]
        )

        updateHeadAttachment(
            content: content,
            attachments: attachments,
            id: "removeFocusOnTsuru",
            anchorName: removeFocusOnTsuruAnchorName,
            position: [-0.5, -0.3, -0.8]
        )

        updateHeadAttachment(
            content: content,
            attachments: attachments,
            id: "moveToLeftTsuru",
            anchorName: moveToLeftTsuruAnchorName,
            position: [-0.5, -0.1, -0.8],
            isEnabled: vm.isFocusedOnTsuru && vm.thereIsTsuruAtLeft
        )

        updateHeadAttachment(
            content: content,
            attachments: attachments,
            id: "moveToRightTsuru",
            anchorName: moveToRightTsuruAnchorName,
            position: [0.5, -0.1, -0.8],
            isEnabled: vm.isFocusedOnTsuru && vm.thereIsTsuruAtRight
        )
    }

    private func updateHeadAttachment(
        content: RealityViewContent,
        attachments: RealityViewAttachments,
        id: String,
        anchorName: String,
        position: SIMD3<Float>,
        isEnabled: Bool? = nil
    ) {
        guard let attachment = attachments.entity(for: id) else { return }

        let headAnchor: Entity

        if let existingAnchor = content.entities.first(where: { $0.name == anchorName }) {
            headAnchor = existingAnchor
        } else {
            let newAnchor = AnchorEntity(.head)
            newAnchor.name = anchorName
            content.add(newAnchor)
            headAnchor = newAnchor
        }

        attachment.position = position

        if let isEnabled {
            attachment.isEnabled = isEnabled
        }

        if attachment.parent == nil {
            headAnchor.addChild(attachment)
        }
    }

    private func removeVisionHUD(from content: RealityViewContent) {
        for anchorName in visionHUDAnchorNames {
            if let existingAnchor = content.entities.first(where: { $0.name == anchorName }) {
                content.remove(existingAnchor)
            }
        }
    }
}

// MARK: - Menu customizado visionOS

private struct VisionScrapMenu: View {
    @Binding var isPaperMenuOpen: Bool

    let onVisualizeOrigamis: () -> Void
    let onSelectStyle: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 26) {
            Button {
                onVisualizeOrigamis()
            } label: {
                HStack(spacing: 24) {
                    Image("origamiVision")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 48, height: 48)

                    Text("Visualize your origamis")
                        .font(.custom("CaveatBrush-Regular", size: 30))
                        .foregroundStyle(.white)

                    Spacer()
                }
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 24) {
                Button {
                    withAnimation(.easeInOut(duration: 0.22)) {
                        isPaperMenuOpen.toggle()
                    }
                } label: {
                    HStack(spacing: 24) {
                        Image("plusVision")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 58, height: 58)

                        Text("Create your scrap")
                            .font(.custom("CaveatBrush-Regular", size: 30))
                            .foregroundStyle(.white)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.9))
                            .rotationEffect(.degrees(isPaperMenuOpen ? 90 : 0))
                    }
                }
                .buttonStyle(.plain)

                if isPaperMenuOpen {
                    VStack(alignment: .leading, spacing: 26) {
                        PaperOptionButton(
                            imageName: "dotted",
                            title: "Dotted"
                        ) {
                            openStyle(at: 0)
                        }

                        PaperOptionButton(
                            imageName: "lantern",
                            title: "Oriental Lanterns"
                        ) {
                            openStyle(at: 1)
                        }

                        PaperOptionButton(
                            imageName: "fan",
                            title: "Floral Fans"
                        ) {
                            openStyle(at: 2)
                        }
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
        }
        .padding(.horizontal, 48)
        .padding(.vertical, 30)
        .frame(width: 500, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 48)
                .fill(Color.gray.opacity(0.7))
        )
    }

    private func openStyle(at index: Int) {
        let styles = Array(PaperStyles.allCases)

        guard styles.indices.contains(index) else { return }

        onSelectStyle(styles[index].name)
    }
}

// MARK: - Botão de opção de papel

private struct PaperOptionButton: View {
    let imageName: String
    let title: String
    let action: () -> Void

    var body: some View {
        Button {
            action()
        } label: {
            HStack(spacing: 34) {
                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 74, height: 74)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.white)
                    )

                Text(title)
                    .font(.custom("CaveatBrush-Regular", size: 30))
                    .foregroundStyle(.white)

                Spacer()
            }
        }
        .buttonStyle(.plain)
    }
}
#endif
    
#Preview {
    SceneView()
        .environment(SceneViewModel())
}
