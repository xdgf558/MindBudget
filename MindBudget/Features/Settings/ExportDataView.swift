import CoreTransferable
import SwiftUI
import UniformTypeIdentifiers

private struct LedgerCSVFile: Transferable, Sendable {
    let data: Data

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .commaSeparatedText) { file in
            file.data
        }
        .suggestedFileName { _ in
            Bundle.main.localizedString(
                forKey: "export.filename.value",
                value: nil,
                table: nil
            )
        }
    }
}

struct ExportDataView: View {
    let dataActor: DataActor

    @State private var exportFile: LedgerCSVFile?
    @State private var rowCount = 0
    @State private var isPreparing = true
    @State private var failed = false

    var body: some View {
        List {
            Section {
                Label("export.localOnly", systemImage: "lock.shield")
                Text("export.includes")
                    .foregroundStyle(.secondary)
                Text("export.spreadsheetSafety")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("export.file.section") {
                LabeledContent("export.recordCount") {
                    Text(rowCount, format: .number)
                }
                if isPreparing {
                    HStack {
                        ProgressView()
                        Text("export.preparing")
                    }
                    .accessibilityElement(children: .combine)
                } else if let exportFile {
                    ShareLink(
                        item: exportFile,
                        preview: SharePreview("export.filename")
                    ) {
                        Label("export.share", systemImage: "square.and.arrow.up")
                    }
                    .accessibilityIdentifier("settings.export.share")
                }
            }

            if failed {
                Section {
                    Label("export.error", systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.orange)
                    Button("common.retry") {
                        Task { await prepareExport() }
                    }
                }
            }
        }
        .navigationTitle("export.title")
        .task { await prepareExport() }
    }

    private func prepareExport() async {
        isPreparing = true
        failed = false
        do {
            async let expenseRequest = dataActor.fetchExpenseExportRecords()
            async let incomeRequest = dataActor.fetchIncomeExportRecords()
            let (expenses, incomes) = try await (expenseRequest, incomeRequest)
            let result = CSVExporter().export(
                expenses: expenses,
                incomes: incomes
            )
            exportFile = LedgerCSVFile(data: result.data)
            rowCount = result.rowCount
        } catch {
            exportFile = nil
            rowCount = 0
            failed = true
        }
        isPreparing = false
    }
}
