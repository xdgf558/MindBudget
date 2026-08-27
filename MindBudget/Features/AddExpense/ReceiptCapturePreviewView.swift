import ImageIO
import SwiftUI
import UIKit

enum ReceiptImageThumbnail {
    static func image(from data: Data, maximumEdge: Int) -> UIImage? {
        guard maximumEdge > 0,
              let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            return nil
        }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maximumEdge,
            kCGImageSourceShouldCacheImmediately: true,
        ]
        guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
        else {
            return nil
        }
        return UIImage(cgImage: image)
    }

    static func make(from data: Data, maximumEdge: Int = 160) -> Data? {
        image(from: data, maximumEdge: maximumEdge)?.jpegData(compressionQuality: 0.72)
    }
}

struct ReceiptCapturePreviewView: View {
    let input: ReceiptImageInput
    let usePhoto: () -> Void
    let retake: () -> Void
    let cancel: () -> Void

    private var image: UIImage? {
        ReceiptImageThumbnail.image(from: input.data, maximumEdge: 2_048)
    }

    var body: some View {
        ZStack {
            Color(red: 0.047, green: 0.047, blue: 0.055).ignoresSafeArea()
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("receipt.preview.title")
                            .font(.title2.bold())
                            .foregroundStyle(.white)
                        Text("receipt.preview.detail")
                            .font(.subheadline)
                            .foregroundStyle(Color.white.opacity(0.68))
                    }
                    Spacer()
                    Button(action: cancel) {
                        Image(systemName: "xmark")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                    .accessibilityLabel("common.close")
                }
                .padding(.horizontal, 20)

                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.06))
                    if let image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    } else {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 44))
                            .foregroundStyle(Color.white.opacity(0.55))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }

                    Label("receipt.preview.badge", systemImage: "lock.shield.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .frame(minHeight: 28)
                        .background(.ultraThinMaterial, in: Capsule())
                        .overlay { Capsule().stroke(Color.white.opacity(0.16), lineWidth: 1) }
                        .padding(12)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, 20)
                .accessibilityIdentifier("receipt.preview.image")

                VStack(spacing: 12) {
                    Button(action: usePhoto) {
                        Label("receipt.preview.use", systemImage: "checkmark")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(MindBudgetPrimaryButtonStyle())
                    .accessibilityIdentifier("receipt.preview.use")

                    Button(action: retake) {
                        Label("receipt.preview.retake", systemImage: "arrow.counterclockwise")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity, minHeight: 48)
                            .background(Color.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 14))
                            .overlay {
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            }
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("receipt.preview.retake")
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 14)
            }
            .padding(.top, 12)
        }
        .preferredColorScheme(.dark)
        .accessibilityIdentifier("receipt.preview")
    }
}

struct ReceiptThumbnailView: View {
    let data: Data?
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        Group {
            if let data, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "doc.text.image")
                    .resizable()
                    .scaledToFit()
                    .padding(7)
            }
        }
        .frame(width: width, height: height)
        .background(Color.secondary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .clipped()
        .accessibilityHidden(true)
    }
}
