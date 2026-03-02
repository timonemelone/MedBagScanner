import SwiftUI
import VisionKit

struct ScannerView: UIViewControllerRepresentable {
    var onBarcode: (String) -> Void

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let scanner = DataScannerViewController(
            recognizedDataTypes: [.barcode()],
            qualityLevel: .balanced,
            recognizesMultipleItems: true,
            isHighFrameRateTrackingEnabled: true,
            isHighlightingEnabled: true
        )
        scanner.delegate = context.coordinator
        return scanner
    }

    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) { }

    func makeCoordinator() -> Coordinator {
        Coordinator(onBarcode: onBarcode)
    }

    final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        let onBarcode: (String) -> Void
        private var lastValue: String?
        private var lastTime: Date = .distantPast

        init(onBarcode: @escaping (String) -> Void) {
            self.onBarcode = onBarcode
        }

        func dataScanner(_ dataScanner: DataScannerViewController,
                         didAdd addedItems: [RecognizedItem],
                         allItems: [RecognizedItem]) {
            handle(items: allItems)
        }

        func dataScanner(_ dataScanner: DataScannerViewController,
                         didUpdate updatedItems: [RecognizedItem],
                         allItems: [RecognizedItem]) {
            handle(items: allItems)
        }

        private func handle(items: [RecognizedItem]) {
            // Nimm den ersten Barcode, debounce damit er nicht 20x feuert
            guard let first = items.compactMap({ item -> String? in
                if case .barcode(let barcode) = item {
                    return barcode.payloadStringValue
                }
                return nil
            }).first else { return }

            let now = Date()
            if first == lastValue, now.timeIntervalSince(lastTime) < 1.0 { return }

            lastValue = first
            lastTime = now
            onBarcode(first)
        }
    }
}