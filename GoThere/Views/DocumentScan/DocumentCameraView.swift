import SwiftUI
import VisionKit

/// Thin SwiftUI wrapper over VisionKit's edge-detecting document scanner. Returns
/// the first scanned page as a `UIImage` (v1 is single-page; the analyze function
/// accepts multi-page, so this can grow to return all pages later).
struct DocumentCameraView: UIViewControllerRepresentable {
    /// Called with the first captured page, or nil if the user cancelled.
    let onCapture: (UIImage?) -> Void

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let vc = VNDocumentCameraViewController()
        vc.delegate = context.coordinator
        return vc
    }

    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onCapture: onCapture) }

    final class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let onCapture: (UIImage?) -> Void
        init(onCapture: @escaping (UIImage?) -> Void) { self.onCapture = onCapture }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController,
                                          didFinishWith scan: VNDocumentCameraScan) {
            let image = scan.pageCount > 0 ? scan.imageOfPage(at: 0) : nil
            controller.dismiss(animated: true) { self.onCapture(image) }
        }

        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            controller.dismiss(animated: true) { self.onCapture(nil) }
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController,
                                          didFailWithError error: Error) {
            controller.dismiss(animated: true) { self.onCapture(nil) }
        }
    }
}
