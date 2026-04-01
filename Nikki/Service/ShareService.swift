//
//  ShareService.swift
//  Nikki
//
//  Created by Alex Fraga on 31/03/26.
//

import UIKit
import Photos
import MessageUI
import UniformTypeIdentifiers

final class ShareService: NSObject, MFMessageComposeViewControllerDelegate {
    /// Presents the native iOS share sheet for other apps sharing.
    func shareWithOtherApps(_ image: UIImage) {
        guard let presenter = topMostViewController() else {
            return
        }

        let activityViewController = UIActivityViewController(
            activityItems: [image],
            applicationActivities: nil
        )
        activityViewController.excludedActivityTypes = [
            .print,
            .assignToContact,
            .saveToCameraRoll,
            .markupAsPDF,
            .addToReadingList,
            .collaborationCopyLink,
            .collaborationInviteWithLink,
            .mail,
        ]

        presenter.present(activityViewController, animated: true)
    }

    /// Saves an exported image into the users photo library.
    func saveImageToLibrary(_ image: UIImage, completion: @escaping (Bool) -> Void) {
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            guard status == .authorized || status == .limited else {
                DispatchQueue.main.async {
                    completion(false)
                }
                return
            }

            PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            } completionHandler: { success, _ in
                DispatchQueue.main.async {
                    completion(success)
                }
            }
        }
    }

    /// Shares only the exported image as the Instagram Stories background.
    func shareToInstagramStories(_ image: UIImage) -> Bool {
        guard let imageData = image.pngData(),
              let storiesURL = instagramStoriesURL(),
              UIApplication.shared.canOpenURL(storiesURL) else {
            return false
        }

        let pasteboardPayload: [String: Any] = [
            "com.instagram.sharedSticker.backgroundImage": imageData,
            "com.instagram.sharedSticker.backgroundTopColor": "#FFCC00",
            "com.instagram.sharedSticker.backgroundBottomColor": "#FF8800"
        ]

        UIPasteboard.general.setItems(
            [pasteboardPayload],
            options: [.expirationDate: Date().addingTimeInterval(300)]
        )

        UIApplication.shared.open(storiesURL)
        return true
    }

    /// Opens the Messages composer with the exported image attached.
    func shareToMessages(_ image: UIImage) -> Bool {
        guard MFMessageComposeViewController.canSendText(),
              MFMessageComposeViewController.canSendAttachments(),
                            let rootViewController = topMostViewController() else {
            return false
        }

        let composer = MFMessageComposeViewController()
        composer.messageComposeDelegate = self
        composer.body = ""

        if let imageData = image.jpegData(compressionQuality: 0.95) {
            composer.addAttachmentData(
                imageData,
                typeIdentifier: UTType.jpeg.identifier,
                filename: "nikki-export.jpg"
            )
        }

        rootViewController.present(composer, animated: true)
        return true
    }

    /// Handles message composer dismissal after send/cancel/fail events.
    func messageComposeViewController(
        _ controller: MFMessageComposeViewController,
        didFinishWith result: MessageComposeResult
    ) {
        controller.dismiss(animated: true)
    }

    /// Builds the Instagram Stories deep link using the configured Meta app id.
    private func instagramStoriesURL() -> URL? {
        // Accept both keys to keep compatibility with existing setups.
        let appId = (Bundle.main.object(forInfoDictionaryKey: "InstagramAppID") as? String)
            ?? (Bundle.main.object(forInfoDictionaryKey: "FacebookAppID") as? String)

        guard let appId, !appId.isEmpty else {
            return nil
        }

        return URL(string: "instagram-stories://share?source_application=\(appId)")
    }

    /// Finds the top-most visible controller to present new share flows safely.
    private func topMostViewController() -> UIViewController? {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first,
              let rootViewController = window.rootViewController else {
            return nil
        }

        var top = rootViewController
        while let presented = top.presentedViewController {
            top = presented
        }

        return top
    }
}
