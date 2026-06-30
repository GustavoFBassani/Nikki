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
                vm.setCanvasPresented(true)
            },
            onCanvasWillDismiss: {
                vm.setCanvasPresented(false)
            },
            onCanvasDisappear: {
                vm.setCanvasPresented(false)
            }
        )
    }
}
