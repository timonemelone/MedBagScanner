import SwiftUI
import VisionKit

struct ContentView: View {
    @StateObject private var store = BagStore()

    @State private var showingScanner = false
    @State private var lastScanned: String = ""
    @State private var resolvedIndex: Int? = nil
    @State private var errorText: String? = nil

    var body: some View {
        NavigationView {
            VStack(spacing: 12) {

                Button {
                    errorText = nil
                    showingScanner = true
                } label: {
                    Label("Scannen", systemImage: "barcode.viewfinder")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Zuletzt gescannt: \(lastScanned.isEmpty ? "—" : lastScanned)")
                        .font(.subheadline)

                    if let idx = resolvedIndex {
                        Text("Erkannt als Tüte #\(idx + 1)  (Code \(store.barcodeString(for: idx)))")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    if let err = errorText {
                        Text(err)
                            .font(.subheadline)
                            .foregroundStyle(.red)
                    }
                }
                .padding(.horizontal)

                Button {
                    guard let idx = resolvedIndex else { return }
                    store.markConsumed(index: idx)
                } label: {
                    Text("Verbrauchen")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(resolvedIndex == nil)
                .padding(.horizontal)

                List {
                    Section("Tüten") {
                        ForEach(0..<31, id: \.self) { i in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Tag \(i + 1)")
                                    Text("Barcode: \(store.barcodeString(for: i))")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                if store.consumed[i] {
                                    Text("verbraucht ✅")
                                        .foregroundStyle(.secondary)
                                } else {
                                    Text("da ⭕️")
                                }
                            }
                            .swipeActions {
                                Button("Verfügbar") {
                                    store.markAvailable(index: i)
                                }.tint(.blue)

                                Button("Verbraucht") {
                                    store.markConsumed(index: i)
                                }.tint(.orange)
                            }
                        }
                    }

                    Section {
                        Button(role: .destructive) {
                            store.resetAll()
                            lastScanned = ""
                            resolvedIndex = nil
                            errorText = nil
                        } label: {
                            Text("Alles zurücksetzen")
                        }
                    }
                }
            }
            .navigationTitle("Medizin-Tüten")
        }
        .sheet(isPresented: $showingScanner) {
            ScannerSheet(
                onFound: { code in
                    lastScanned = code
                    if let idx = store.index(from: code) {
                        resolvedIndex = idx
                        errorText = nil
                    } else {
                        resolvedIndex = nil
                        errorText = "Ungültiger Code. Erwartet: 0000000 bis 0000030."
                    }
                }
            )
        }
    }
}

struct ScannerSheet: View {
    @Environment(\.dismiss) private var dismiss
    var onFound: (String) -> Void

    var body: some View {
        NavigationView {
            Group {
                if DataScannerViewController.isSupported && DataScannerViewController.isAvailable {
                    ScannerView { code in
                        onFound(code)
                        dismiss()
                    }
                    .ignoresSafeArea()
                } else {
                    Text("Scanner ist auf diesem Gerät nicht verfügbar.")
                        .padding()
                }
            }
            .navigationTitle("Scanner")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Schließen") { dismiss() }
                }
            }
        }
    }
}