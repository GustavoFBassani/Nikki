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

        _viewModel = State(initialValue: CanvasViewModel(page: page, paperStyle: paperStyle))
        self.addNewTsuru = addNewTsuru
        self.reloadTsurus = reloadTsurus
        self.onCanvasAppear = onCanvasAppear
        self.onCanvasWillDismiss = onCanvasWillDismiss
        self.onCanvasDisappear = onCanvasDisappear
    }

    // MARK: - Body

    var body: some View {
        editorContent
            .overlay(alignment: .top) {
                topControlsOverlay
            }

#if os(visionOS)
            .ornament(
                attachmentAnchor: .scene(.bottom),
                contentAlignment: .center
            ) {
                tabBarOverlay
            }
#else
            .overlay(alignment: .bottom) {
                tabBarOverlay
            }
#endif

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
            .onChange(of: viewModel.photoItem) { _, _ in
                handlePhotoSelection()
            }
            .onAppear {
                onCanvasAppear?()
            }
            .onDisappear {
                handleCanvasExit()
            }
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
            .background(DisableCanvasBackSwipe())
    }

    // MARK: - View Components

    private var editorContent: some View {
        EditorView(size: viewModel.canvasSize, data: viewModel.editorData)
            .ignoresSafeArea()
    }

    @ViewBuilder
    private var topControlsOverlay: some View {
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
                        action: { showDeleteAlert = true }
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

    @ViewBuilder
    private var tabBarOverlay: some View {
        if isTabBarHidden {
#if os(visionOS)
            tabBarButtons
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .glassBackgroundEffect(in: Capsule())
                .padding(.bottom, 8)
#else
            tabBarButtons
                .padding(.bottom, 16)
#endif
        }
    }

    private var tabBarButtons: some View {
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

        Button("Delete") {
            Task {
                await handleDeletePage()
            }
        }
    }

    private var deleteAlertMessage: some View {
        Text(StringCatalog.deleteAlertMessage)
    }

    // MARK: - Actions

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

        Task {
            await dismissCanvas(with: nil)
        }
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
    private func dismissCanvas(with message: String?, prepareScene: Bool = true) async {
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

// MARK: - Preview


#Preview {
    Text("Delete")
        .font(.custom("Caveat-Regular", size: 99))
}
