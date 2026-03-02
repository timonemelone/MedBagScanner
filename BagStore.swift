import Foundation
import SwiftUI

final class BagStore: ObservableObject {
    private let key = "bagConsumedFlags_v1"
    @Published var consumed: [Bool] = Array(repeating: false, count: 31)

    init() {
        load()
    }

    func barcodeString(for index: Int) -> String {
        // 0 -> "0000000", 30 -> "0000030"
        String(format: "%07d", index)
    }

    func index(from barcode: String) -> Int? {
        guard barcode.count == 7, let n = Int(barcode) else { return nil }
        guard (0...30).contains(n) else { return nil }
        return n
    }

    func markConsumed(index: Int) {
        guard (0..<consumed.count).contains(index) else { return }
        consumed[index] = true
        save()
    }

    func markAvailable(index: Int) {
        guard (0..<consumed.count).contains(index) else { return }
        consumed[index] = false
        save()
    }

    func resetAll() {
        consumed = Array(repeating: false, count: 31)
        save()
    }

    private func save() {
        UserDefaults.standard.set(consumed, forKey: key)
    }

    private func load() {
        if let arr = UserDefaults.standard.array(forKey: key) as? [Bool], arr.count == 31 {
            consumed = arr
        }
    }
}