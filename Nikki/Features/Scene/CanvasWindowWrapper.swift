//
//  CanvasWindowWrapper.swift
//  Nikki
//

import SwiftUI

struct CanvasWindowWrapper: View {
    let style: String

    @Environment(SceneViewModel.self) private var vm

    var body: some View {
        CanvasView(
            page: vm.currentPage,
            paperStyle: style,
            addNewTsuru: vm.parseCanvasDateAndAddNewTsuruAtScene,
            reloadTsurus: vm.deleteTsurusAtScene,
            onCanvasAppear: {
                vm.setScenePaused(true)
            },
            onCanvasWillDismiss: {
                vm.setScenePaused(false)
                await vm.waitUntilSceneResumed()
            },
            onCanvasDisappear: {
                vm.setScenePaused(false)
            }
        )
    }
}
