//
//  CanvasView.swift
//  Nikki
//
//  Created by Alex Fraga on 06/11/25.
//

import SwiftUI
import PaperKit
import PhotosUI
import MusicKit
import AVFoundation
import UIKit

#if os(visionOS)
private enum VisionCanvasToolbarItem {
    case text
    case pencil
    case images
    case music
    case stickers
}
#endif

// MARK: - CanvasView

struct CanvasView: View {
    private enum PendingShareAction {
        case otherApps(UIImage)
        case messages(UIImage)
    }

    // MARK: - Properties

    @State private var viewModel: CanvasViewModel
    @State private var showDeleteAlert = false
    @State private var isTabBarHidden = true
    @State private var showCheckMark = false
    @State private var isPreparingShare = false
    @State private var showCustomShare = false
    @State private var pendingShareAction: PendingShareAction?
    @State private var exportedImageToShare: UIImage?
    @State private var showShareFeedback = false
    @State private var shareFeedbackMessage = ""
    @State private var isSavingPage = false
    @State private var isDismissingCanvas = false
    @State private var dismissLoadingMessage: String?

#if os(visionOS)
    @State private var selectedVisionToolbarItem: VisionCanvasToolbarItem?
#endif

    @Environment(\.dismiss) private var dismiss

    var addNewTsuru: () async -> Void
    var reloadTsurus: () async -> Void
    var onCanvasAppear: (() -> Void)?
    var onCanvasWillDismiss: (() async -> Void)?
    var onCanvasDisappear: (() -> Void)?
    var isPageNil: Bool = false

    // MARK: - Initialization

    init(
        page: Page? = nil,
        paperStyle: String? = nil,
        addNewTsuru: @escaping () async -> Void,
        reloadTsurus: @escaping () async -> Void,
        onCanvasAppear: (() -> Void)? = nil,
        onCanvasWillDismiss: (() async -> Void)? = nil,
        onCanvasDisappear: (() -> Void)? = nil
    ) {
        if page == nil {
            isPageNil = true
        }

        _viewModel = State(
            initialValue: CanvasViewModel(
                page: page,
                paperStyle: paperStyle
            )
        )

        self.addNewTsuru = addNewTsuru
        self.reloadTsurus = reloadTsurus
        self.onCanvasAppear = onCanvasAppear
        self.onCanvasWillDismiss = onCanvasWillDismiss
        self.onCanvasDisappear = onCanvasDisappear
    }

    // MARK: - Body

    var body: some View {
        canvasWithDismissHelpers
    }

    private var canvasBase: some View {
        editorContent
            .overlay(alignment: .top) {
                topControlsOverlay
            }
    }

    @ViewBuilder
    private var canvasWithToolbar: some View {
#if os(visionOS)
        canvasBase
            .ornament(
                attachmentAnchor: .scene(.bottom),
                contentAlignment: .center
            ) {
                tabBarOverlay
            }
#else
        canvasBase
            .overlay(alignment: .bottom) {
                tabBarOverlay
            }
#endif
    }

    private var canvasWithSheets: some View {
        canvasWithToolbar
            .preferredColorScheme(.light)
            .sheet(isPresented: $viewModel.showITunesSearch) {
                itunesSearchSheet
            }
            .sheet(isPresented: $viewModel.showAudioPicker) {
                audioPickerSheet
            }
            .sheet(isPresented: $viewModel.showStickers) {
                stickersSheet
            }
            .sheet(isPresented: $showCustomShare, onDismiss: handleShareSheetDismiss) {
                customShareSheet
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(24)
            }
            .photosPicker(
                isPresented: $viewModel.showImagePicker,
                selection: $viewModel.photoItem
            )
    }

    private var canvasWithLifecycle: some View {
        canvasWithSheets
            .onChange(of: viewModel.photoItem) { _, _ in
                handlePhotoSelection()
            }
            .onChange(of: viewModel.showITunesSearch) { _, isPresented in
                resetMusicToolbarSelectionIfNeeded(isPresented)
            }
            .onChange(of: viewModel.showStickers) { _, isPresented in
                resetStickersToolbarSelectionIfNeeded(isPresented)
            }
            .onChange(of: viewModel.showImagePicker) { _, isPresented in
                resetImagesToolbarSelectionIfNeeded(isPresented)
            }
            .onAppear {
                onCanvasAppear?()
            }
            .onDisappear {
                handleCanvasExit()
            }
    }

    private var canvasWithAlertsAndOverlays: some View {
        canvasWithLifecycle
            .alert("Delete page?", isPresented: $showDeleteAlert) {
                deleteAlertButtons
            } message: {
                deleteAlertMessage
            }
            .overlay(alignment: .center) {
                if isPreparingShare {
                    loadingOverlay(message: "Preparing share...")
                }
            }
            .overlay(alignment: .center) {
                if isSavingPage {
                    loadingOverlay(message: "Preparing folds")
                }
            }
            .overlay(alignment: .center) {
                if isDismissingCanvas {
                    loadingOverlay(message: dismissLoadingMessage)
                }
            }
            .alert("Share", isPresented: $showShareFeedback) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(shareFeedbackMessage)
            }
    }

    private var canvasWithDismissHelpers: some View {
        canvasWithAlertsAndOverlays
            .background(KeyboardDismissOnOutsideTap())
            .background(DisableCanvasBackSwipe())
    }

    // MARK: - View Components

    private var editorContent: some View {
        EditorView(size: viewModel.canvasSize, data: viewModel.editorData)
            .ignoresSafeArea()
    }

    @ViewBuilder
    private var topControlsOverlay: some View {
#if os(visionOS)
        visionTopControlsOverlay
#else
        defaultTopControlsOverlay
#endif
    }

    @ViewBuilder
    private var defaultTopControlsOverlay: some View {
        HStack {
            if !showCheckMark {
                CanvasFloatingButton(
                    isDisabled: isSavingPage || isDismissingCanvas,
                    action: handleBackButtonTap
                ) {
                    Image("leftChevron")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 22, height: 22)
                        .padding(8)
                }
            }

            Spacer()

            if showCheckMark {
                Button(action: handleCheckMark) {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.white)
                        .font(.system(size: 17, weight: .semibold))
                        .frame(width: 44, height: 44)
                        .background {
                            Circle()
                                .fill(.cyan)
                        }
                }
                .buttonStyle(.plain)
                .disabled(isSavingPage || isDismissingCanvas)
            } else {
                HStack(spacing: 12) {
                    CanvasFloatingButton(
                        isDisabled: isSavingPage || isDismissingCanvas,
                        action: {
                            showDeleteAlert = true
                        }
                    ) {
                        Image(.customGarbage)
                    }

                    CanvasFloatingButton(
                        isDisabled: isSavingPage || isDismissingCanvas,
                        action: handleUndo
                    ) {
                        Image("undo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 25, height: 25)
                    }

                    CanvasFloatingButton(
                        isDisabled: isSavingPage || isDismissingCanvas,
                        action: handleShareButtonTap
                    ) {
                        Image("shareCustom")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 25, height: 25)
                    }

                    CanvasFloatingButton(
                        isDisabled: isSavingPage || isDismissingCanvas,
                        action: handleSave
                    ) {
                        Image(.tsuruBird)
                            .accessibilityIdentifier("canvas_save_button")
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .zIndex(10)
    }

#if os(visionOS)
    @ViewBuilder
    private var visionTopControlsOverlay: some View {
        HStack {
            if !showCheckMark {
                VisionTopControlButton(
                    accessibilityLabel: "Back",
                    isDisabled: isSavingPage || isDismissingCanvas,
                    isSelected: false,
                    action: handleBackButtonTap
                ) {
                    Image(.leftVision)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 44, height: 44)
                }
            }

            Spacer()

            if showCheckMark {
                VisionTopControlButton(
                    accessibilityLabel: "Done",
                    isDisabled: isSavingPage || isDismissingCanvas,
                    isSelected: false,
                    defaultBackgroundColor: .cyan.opacity(0.9),
                    action: handleCheckMark
                ) {
                    Image(.checkVision)
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                }
            } else {
                HStack(spacing: 16) {
                    VisionTopControlButton(
                        accessibilityLabel: "Delete",
                        isDisabled: isSavingPage || isDismissingCanvas,
                        isSelected: false,
                        action: {
                            showDeleteAlert = true
                        }
                    ) {
                        Image(.trashVision)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 44, height: 44)
                    }

                    VisionTopControlButton(
                        accessibilityLabel: "Undo",
                        isDisabled: isSavingPage || isDismissingCanvas,
                        isSelected: false,
                        action: handleUndo
                    ) {
                        Image(.backVision)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 44, height: 44)
                    }

                    let isShareSelected = showCustomShare || isPreparingShare

                    VisionTopControlButton(
                        accessibilityLabel: "Share",
                        isDisabled: isSavingPage || isDismissingCanvas || isPreparingShare,
                        isSelected: isShareSelected,
                        selectedBackgroundColor: Color.white.opacity(0.22),
                        action: handleShareButtonTap
                    ) {
                        Image(isShareSelected ? "shareSelected" : "shareVision")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 44, height: 44)
                    }

                    VisionTopControlButton(
                        accessibilityLabel: "Save",
                        isDisabled: isSavingPage || isDismissingCanvas,
                        isSelected: false,
                        action: handleSave
                    ) {
                        Image(.origamiVision)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 44, height: 44)
                            .accessibilityIdentifier("canvas_save_button")
                    }
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .zIndex(10)
    }
#endif

    @ViewBuilder
    private var tabBarOverlay: some View {
        if isTabBarHidden {
#if os(visionOS)
            tabBarButtons
                .padding(.bottom, 8)
#else
            tabBarButtons
                .padding(.bottom, 16)
#endif
        }
    }

    private var tabBarButtons: some View {
#if os(visionOS)
        VisionTabBarToolKit(
            selectedItem: selectedVisionToolbarItem,
            showTextEditor: {
                selectedVisionToolbarItem = .text
                handleTextEditor()
                selectedVisionToolbarItem = nil
            },
            showPencilTool: {
                selectedVisionToolbarItem = .pencil
                handlePencilTool()
            },
            showImages: {
                selectedVisionToolbarItem = .images
                viewModel.showImagePicker = true
            },
            showMusics: {
                selectedVisionToolbarItem = .music
                viewModel.showITunesSearch = true
            },
            showStickers: {
                selectedVisionToolbarItem = .stickers
                viewModel.showStickers = true
            }
        )
#else
        TabBarToolKit(
            showTextEditor: handleTextEditor,
            showPencilTool: handlePencilTool,
            showImages: {
                viewModel.showImagePicker.toggle()
            },
            showMusics: {
                viewModel.showITunesSearch.toggle()
            },
            showStickers: {
                viewModel.showStickers.toggle()
            }
        )
#endif
    }

    @ViewBuilder
    private var customShareSheet: some View {
        ShareSheet(
            onStories: {
                handleShareToStories()
            },
            onMessages: {
                handleShareToMessages()
            },
            onSaveImage: {
                handleSaveImage()
            },
            onShareOtherApps: {
                handleShareWithOtherApps()
            }
        )
    }

    private var itunesSearchSheet: some View {
        ITunesSearchView { track in
            viewModel.handleITunesTrackSelection(track)
        }
        .presentationDetents([.medium])
    }

    private var audioPickerSheet: some View {
        AudioPickerSheet(audioRecorder: viewModel.audioRecorder)
            .presentationDetents([.medium])
    }

    private var stickersSheet: some View {
        StickersSheet(
            stickers: viewModel.stickers,
            onSelect: { stickerName in
                viewModel.insertSticker(named: stickerName)
            }
        )
        .presentationDetents([.medium])
    }

    @ViewBuilder
    private var deleteAlertButtons: some View {
        Button("Cancel", role: .cancel) {}

        Button("Delete", role: .destructive) {
            Task {
                await handleDeletePage()
            }
        }
    }

    private var deleteAlertMessage: some View {
        Text(StringCatalog.deleteAlertMessage)
    }

    // MARK: - Actions

    private func resetMusicToolbarSelectionIfNeeded(_ isPresented: Bool) {
#if os(visionOS)
        if !isPresented, selectedVisionToolbarItem == .music {
            selectedVisionToolbarItem = nil
        }
#endif
    }

    private func resetStickersToolbarSelectionIfNeeded(_ isPresented: Bool) {
#if os(visionOS)
        if !isPresented, selectedVisionToolbarItem == .stickers {
            selectedVisionToolbarItem = nil
        }
#endif
    }

    private func resetImagesToolbarSelectionIfNeeded(_ isPresented: Bool) {
#if os(visionOS)
        if !isPresented, selectedVisionToolbarItem == .images {
            selectedVisionToolbarItem = nil
        }
#endif
    }

    private func handleTextEditor() {
        viewModel.insertDefaultText()
    }

    private func handlePencilTool() {
        viewModel.showTools.toggle()
        viewModel.editorData.showPencilKitTools(viewModel.showTools)
        isTabBarHidden.toggle()
        showCheckMark.toggle()
    }

    private func handleCheckMark() {
        guard !isSavingPage, !isDismissingCanvas else { return }

        if viewModel.showTools {
            viewModel.showTools = false
            viewModel.editorData.showPencilKitTools(false)
        }

        showCheckMark = false
        isTabBarHidden = true

#if os(visionOS)
        selectedVisionToolbarItem = nil
#endif
    }

    private func handleUndo() {
        viewModel.undoAction()
    }

    private func handleShareButtonTap() {
        guard !isPreparingShare else { return }

        isPreparingShare = true

        Task {
            defer {
                isPreparingShare = false
            }

            guard let image = await viewModel.exportWithCanvas() else {
                shareFeedbackMessage = "It was not possible to export the scrap."
                showShareFeedback = true
                return
            }

            presentShareMenu(with: image)
        }
    }

    private func presentShareMenu(with image: UIImage) {
        exportedImageToShare = image
        showCustomShare = true
    }

    private func handleSaveImage() {
        guard let image = exportedImageToShare else { return }

        viewModel.shareService.saveImageToLibrary(image) { success in
            shareFeedbackMessage = success
                ? "Image saved to Photos"
                : "Unable to save image. Check Photos permission"

            showShareFeedback = true
        }
    }

    private func handleShareWithOtherApps() {
        guard let image = exportedImageToShare else { return }

        showCustomShare = false
        pendingShareAction = .otherApps(image)
    }

    private func handleShareToStories() {
        guard let image = exportedImageToShare else { return }

        let openedInstagram = viewModel.shareService.shareToInstagramStories(image)

        showCustomShare = false

        if openedInstagram {
            return
        }

        shareFeedbackMessage = "It was not possible to open Instagram. Please, try again later."
        showShareFeedback = true
    }

    private func handleShareToMessages() {
        guard let image = exportedImageToShare else { return }

        showCustomShare = false
        pendingShareAction = .messages(image)
    }

    private func handleShareSheetDismiss() {
        guard let pendingShareAction else { return }

        self.pendingShareAction = nil

        switch pendingShareAction {
        case .otherApps(let image):
            viewModel.shareService.shareWithOtherApps(image)

        case .messages(let image):
            let openedComposer = viewModel.shareService.shareToMessages(image)

            if !openedComposer {
                shareFeedbackMessage = "It was not possible to open Messages. Please, try again later."
                showShareFeedback = true
            }
        }
    }

    private func handleSave() {
        guard !isSavingPage, !isDismissingCanvas else { return }

        isSavingPage = true

        Task {
            do {
                try await viewModel.savePage()

                if isPageNil {
                    await addNewTsuru()
                }

                await dismissCanvas(with: "Preparing folds")
            } catch {
                await MainActor.run {
                    isSavingPage = false
                }

                print("Error saving page: \(error)")
            }
        }
    }

    private func handleBackButtonTap() {
        guard !isSavingPage, !isDismissingCanvas else { return }

        Task {
            await dismissCanvas(with: nil)
        }
    }

    private func handleDeletePage() async {
        guard !isDismissingCanvas else { return }

        guard viewModel.currentPage != nil else {
            await dismissCanvas(with: nil, prepareScene: false)
            return
        }

        try? viewModel.deleteCurrentPage()
        await reloadTsurus()
        await dismissCanvas(with: nil)
    }

    private func handlePhotoSelection() {
        Task {
            await viewModel.handlePhotoSelection()
        }
    }

    private func handleCanvasExit() {
        viewModel.stopAudio()
        onCanvasDisappear?()
    }

    @MainActor
    private func dismissCanvas(
        with message: String?,
        prepareScene: Bool = true
    ) async {
        guard !isDismissingCanvas else { return }

        isDismissingCanvas = true
        dismissLoadingMessage = message

        if prepareScene {
            await onCanvasWillDismiss?()
        }

        dismiss()
    }

    @ViewBuilder
    private func loadingOverlay(message: String? = nil) -> some View {
        ZStack {
            Color.black.opacity(0.25)
                .ignoresSafeArea()

            VStack(spacing: 12) {
                if let message {
                    Text(message)
                        .font(.custom("CaveatBrush-Regular", size: 25))
                        .foregroundStyle(.blueNikki)
                }

                ProgressView()
            }
            .padding(20)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }
}

// MARK: - Floating Button

private struct CanvasFloatingButton<Content: View>: View {
    let isDisabled: Bool
    let action: () -> Void
    let content: Content

    init(
        isDisabled: Bool = false,
        action: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.isDisabled = isDisabled
        self.action = action
        self.content = content()
    }

    var body: some View {
        Button(action: action) {
            content
                .foregroundStyle(.primary)
                .frame(width: 44, height: 44)
                .background {
                    Circle()
                        .fill(.regularMaterial)
                }
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.5 : 1)
        .contentShape(Circle())
    }
}

#if os(visionOS)
// MARK: - Vision Top Control Button

private struct VisionTopControlButton<Content: View>: View {
    let accessibilityLabel: String
    let isDisabled: Bool
    let isSelected: Bool
    let defaultBackgroundColor: Color
    let selectedBackgroundColor: Color
    let hoverColor: Color
    let action: () -> Void
    let content: Content

    @State private var isHovered = false

    init(
        accessibilityLabel: String,
        isDisabled: Bool = false,
        isSelected: Bool = false,
        defaultBackgroundColor: Color = Color.white.opacity(0.12),
        selectedBackgroundColor: Color = Color.white.opacity(0.22),
        hoverColor: Color = Color.black.opacity(0.32),
        action: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.accessibilityLabel = accessibilityLabel
        self.isDisabled = isDisabled
        self.isSelected = isSelected
        self.defaultBackgroundColor = defaultBackgroundColor
        self.selectedBackgroundColor = selectedBackgroundColor
        self.hoverColor = hoverColor
        self.action = action
        self.content = content()
    }

    private var backgroundColor: Color {
        if isHovered {
            return hoverColor
        }

        if isSelected {
            return selectedBackgroundColor
        }

        return defaultBackgroundColor
    }

    private var borderColor: Color {
        if isSelected {
            return Color.white.opacity(0.75)
        }

        if isHovered {
            return Color.black.opacity(0.45)
        }

        return Color.clear
    }

    private var scale: CGFloat {
        isHovered ? 1.08 : 1.0
    }

    private var accessibilityTraits: AccessibilityTraits {
        isSelected ? [.isButton, .isSelected] : .isButton
    }

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(.regularMaterial)

                Circle()
                    .fill(backgroundColor)

                content
            }
            .frame(width: 50, height: 50)
            .overlay {
                Circle()
                    .strokeBorder(borderColor, lineWidth: 1)
            }
            .scaleEffect(scale)
            .animation(.easeInOut(duration: 0.16), value: isHovered)
            .animation(.easeInOut(duration: 0.16), value: isSelected)
            .contentShape(Circle())
        }
        .frame(width: 56, height: 56)
        .contentShape(Rectangle())
        .buttonStyle(.plain)
        .hoverEffect(.highlight)
        .onHover { hovering in
            isHovered = hovering
        }
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.45 : 1)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(accessibilityTraits)
    }
}

// MARK: - Vision Tab Bar ToolKit

private struct VisionTabBarToolKit: View {
    var selectedItem: VisionCanvasToolbarItem?

    var showTextEditor: () -> Void
    var showPencilTool: () -> Void
    var showImages: () -> Void
    var showMusics: () -> Void
    var showStickers: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            VisionToolbarButton(
                imageName: "folhaVision",
                accessibilityLabel: "Text",
                isSelected: selectedItem == .text,
                action: showTextEditor
            )

            VisionToolbarButton(
                imageName: "canetaVision",
                accessibilityLabel: "Draw",
                isSelected: selectedItem == .pencil,
                action: showPencilTool
            )

            VisionToolbarButton(
                imageName: "imagemVision",
                accessibilityLabel: "Images",
                isSelected: selectedItem == .images,
                action: showImages
            )

            VisionToolbarButton(
                imageName: "musicaVision",
                accessibilityLabel: "Music",
                isSelected: selectedItem == .music,
                action: showMusics
            )

            VisionToolbarButton(
                imageName: "carimboVision",
                accessibilityLabel: "Stickers",
                isSelected: selectedItem == .stickers,
                action: showStickers
            )
        }
        .padding(.horizontal, 18)
        .frame(height: 68)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 35, style: .continuous))
        .glassBackgroundEffect(
            in: RoundedRectangle(cornerRadius: 35, style: .continuous)
        )
    }
}

private struct VisionToolbarButton: View {
    let imageName: String
    let accessibilityLabel: String
    let isSelected: Bool
    let action: () -> Void

    @State private var isHovered = false

    private var backgroundColor: Color {
        if isSelected {
            return Color.white.opacity(0.2)
        }

        if isHovered {
            return Color.white.opacity(0.6)
        }

        return Color.clear
    }

    private var scale: CGFloat {
        isHovered ? 1.08 : 1.0
    }

    private var accessibilityTraits: AccessibilityTraits {
        isSelected ? [.isButton, .isSelected] : .isButton
    }

    var body: some View {
        Button(action: action) {
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 44, height: 44)
                .background {
                    Circle()
                        .fill(backgroundColor)
                }
                .scaleEffect(scale)
                .animation(.easeInOut(duration: 0.16), value: isHovered)
                .animation(.easeInOut(duration: 0.16), value: isSelected)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .hoverEffect(.highlight)
        .onHover { hovering in
            isHovered = hovering
        }
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(accessibilityTraits)
    }
}
#endif

// MARK: - Keyboard Dismiss

private struct KeyboardDismissOnOutsideTap: UIViewRepresentable {
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> HostingView {
        let view = HostingView()
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = false
        view.coordinator = context.coordinator
        return view
    }

    func updateUIView(_ uiView: HostingView, context: Context) {
        uiView.coordinator = context.coordinator
        context.coordinator.attach(to: uiView.window)
    }

    static func dismantleUIView(_ uiView: HostingView, coordinator: Coordinator) {
        coordinator.detach()
    }

    final class HostingView: UIView {
        weak var coordinator: Coordinator?

        override func didMoveToWindow() {
            super.didMoveToWindow()
            coordinator?.attach(to: window)
        }
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        private weak var window: UIWindow?
        private var tapGesture: UITapGestureRecognizer?

        func attach(to window: UIWindow?) {
            guard let window else { return }

            if self.window === window, tapGesture?.view === window {
                return
            }

            detach()

            let gesture = UITapGestureRecognizer(
                target: self,
                action: #selector(handleTapOutside)
            )

            gesture.name = "CanvasKeyboardDismissOnOutsideTap"
            gesture.cancelsTouchesInView = false
            gesture.delegate = self

            window.addGestureRecognizer(gesture)

            self.window = window
            self.tapGesture = gesture
        }

        func detach() {
            if let tapGesture, let view = tapGesture.view {
                view.removeGestureRecognizer(tapGesture)
            }

            tapGesture = nil
            window = nil
        }

        @objc
        private func handleTapOutside(_ gesture: UITapGestureRecognizer) {
            guard gesture.state == .ended else { return }

            UIApplication.shared.sendAction(
                #selector(UIResponder.resignFirstResponder),
                to: nil,
                from: nil,
                for: nil
            )
        }

        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldReceive touch: UITouch
        ) -> Bool {
            guard let touchedView = touch.view else {
                return true
            }

            return !touchedView.isInsideTextInput
        }

        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool {
            true
        }
    }
}

private extension UIView {
    var isInsideTextInput: Bool {
        if (self as? any UITextInput) != nil {
            return true
        }

        return superview?.isInsideTextInput ?? false
    }
}

// MARK: - Preview

#Preview {
    Text("Delete")
        .font(.custom("Caveat-Regular", size: 99))
}
