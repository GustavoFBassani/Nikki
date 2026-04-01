//
//  DisableCanvasBackSwipe.swift
//  Nikki
//
//  Created by Alex Fraga on 31/03/26.
//

import SwiftUI
import UIKit

struct DisableCanvasBackSwipe: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> Controller {
        Controller()
    }

    func updateUIViewController(_ uiViewController: Controller, context: Context) {}

    final class Controller: UIViewController {
        private let blockerDelegate = PopGestureBlockerDelegate()
        private weak var previousDelegate: UIGestureRecognizerDelegate?
        private var previousEdgePanStates: [ObjectIdentifier: Bool] = [:]
        private var edgePans: [UIScreenEdgePanGestureRecognizer] = []

        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            applyBlocking()
        }

        override func viewDidLayoutSubviews() {
            super.viewDidLayoutSubviews()
            // Keeps blocking active even if UINavigationController internally toggles the gesture.
            applyBlocking()
        }

        override func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)
            restoreBehavior()
        }

        private func applyBlocking() {
            guard let popGesture = navigationController?.interactivePopGestureRecognizer else {
                return
            }

            if popGesture.delegate !== blockerDelegate {
                previousDelegate = popGesture.delegate
                popGesture.delegate = blockerDelegate
            }

            popGesture.isEnabled = true

            disableLeftEdgePansIfNeeded()
        }

        private func restoreBehavior() {
            guard let popGesture = navigationController?.interactivePopGestureRecognizer else {
                return
            }

            if popGesture.delegate === blockerDelegate {
                popGesture.delegate = previousDelegate
            }

            popGesture.isEnabled = true

            restoreLeftEdgePans()
        }

        private func disableLeftEdgePansIfNeeded() {
            guard let gestures = navigationController?.view.gestureRecognizers else {
                return
            }

            for gesture in gestures {
                guard let edgePan = gesture as? UIScreenEdgePanGestureRecognizer,
                      edgePan.edges.contains(.left) else {
                    continue
                }

                let id = ObjectIdentifier(edgePan)
                if previousEdgePanStates[id] == nil {
                    previousEdgePanStates[id] = edgePan.isEnabled
                    edgePans.append(edgePan)
                }

                edgePan.isEnabled = false
            }
        }

        private func restoreLeftEdgePans() {
            for edgePan in edgePans {
                let id = ObjectIdentifier(edgePan)
                if let previous = previousEdgePanStates[id] {
                    edgePan.isEnabled = previous
                }
            }

            previousEdgePanStates.removeAll()
            edgePans.removeAll()
        }
    }

    private final class PopGestureBlockerDelegate: NSObject, UIGestureRecognizerDelegate {
        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            false
        }
    }
}
