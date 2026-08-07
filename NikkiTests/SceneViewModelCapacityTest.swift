//
//  SceneViewModelCapacityTest.swift
//  NikkiTests
//

import Testing
@testable import Nikki
import Foundation

/// Cobre a capacidade da árvore: quantos tsurus cabem, quando o botão de criar
/// some e — o caso que quebrou — se apagar um scrap devolve a vaga.
@Suite("Capacidade da árvore no SceneViewModel", .serialized)
@MainActor
struct SceneViewModelCapacityTest {

    @Test
    func treeStartsEmptyAndAcceptsNewPages() {
        resetDatabase()
        let vm = SceneViewModel()
        vm.fetchUpdatedTsurusAtOrderedPages()

        #expect(vm.nextTsuruIndex == 0)
        #expect(vm.canAddNewPage)
    }

    @Test
    func capacityMatchesTheModelledPositions() {
        let vm = SceneViewModel()

        // O limite não pode ser um número solto: tem que ser o total de posições
        // modeladas, senão indexar `tsuruPositions` estoura.
        #expect(vm.maxTsurus == TsuruPosition.allCases.count)
        #expect(vm.maxTsurus == vm.tsuruPositions.count)
    }

    @Test
    func createButtonHidesWhenTreeIsFull() {
        resetDatabase()
        let vm = SceneViewModel()
        let manager = ScrapService.shared

        savePages(count: vm.maxTsurus, using: manager)
        vm.fetchUpdatedTsurusAtOrderedPages()

        #expect(vm.nextTsuruIndex == vm.maxTsurus)
        #expect(!vm.canAddNewPage)

        // A guarda tem que cobrir o índice: sem ela, `tsuruPositions[maxTsurus]`
        // estaria fora do range.
        #expect(!vm.tsuruPositions.indices.contains(vm.nextTsuruIndex))
    }

    @Test
    func deletingAScrapFreesTheSlotAgain() {
        resetDatabase()
        let vm = SceneViewModel()
        let manager = ScrapService.shared

        savePages(count: vm.maxTsurus, using: manager)
        vm.fetchUpdatedTsurusAtOrderedPages()
        #expect(!vm.canAddNewPage)

        // Apaga um scrap, exatamente como o botão de deletar do canvas faz.
        if let first = try? manager.fetchAllPages().first {
            try? manager.deletePage(first)
        }
        vm.fetchUpdatedTsurusAtOrderedPages()

        #expect(vm.nextTsuruIndex == vm.maxTsurus - 1)
        #expect(vm.canAddNewPage)
        #expect(vm.tsuruPositions.indices.contains(vm.nextTsuruIndex))
    }

    @Test
    func indexStaysInsideRangeWhileFillingTheTree() {
        resetDatabase()
        let vm = SceneViewModel()
        let manager = ScrapService.shared

        for expectedIndex in 0..<vm.maxTsurus {
            vm.fetchUpdatedTsurusAtOrderedPages()

            #expect(vm.canAddNewPage)
            #expect(vm.nextTsuruIndex == expectedIndex)
            #expect(vm.tsuruPositions.indices.contains(vm.nextTsuruIndex))

            savePages(count: 1, using: manager)
        }

        vm.fetchUpdatedTsurusAtOrderedPages()
        #expect(!vm.canAddNewPage)
    }

    // MARK: - Aux

    private func savePages(count: Int, using manager: ScrapService) {
        for index in 0..<count {
            let page = Page(
                title: "Page \(index)",
                markupData: nil,
                paperStyle: "recycledPaper"
            )
            try? manager.savePage(page)
        }
    }

    private func resetDatabase() {
        let manager = ScrapService.shared
        if let pages = try? manager.fetchAllPages() {
            for page in pages {
                try? manager.deletePage(page)
            }
        }
    }
}
