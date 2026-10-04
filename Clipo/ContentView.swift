import SwiftUI
import SwiftData
import AppKit

struct ContentView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \ClipItem.createdAt, order: .reverse) private var items: [ClipItem]
    @State private var search = ""
    @State private var confirmingClear = false
    @AppStorage("windowWidth") private var width = 380.0
    @AppStorage("windowHeight") private var height = 480.0

    private var filtered: [ClipItem] {
        let term = search.trimmingCharacters(in: .whitespaces)
        guard !term.isEmpty else { return items }
        return items.filter { $0.text.localizedCaseInsensitiveContains(term) }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            list
            footer
        }
        .frame(width: width, height: height)
        .overlay { ResizeEdges(width: $width, height: $height) }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 10) {
            HStack {
                Label("Clipo", systemImage: "list.clipboard")
                    .font(.headline)
                Spacer()
                Text("\(items.count)/\(ClipboardMonitor.maxItems)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Buscar no histórico", text: $search)
                    .textFieldStyle(.plain)
                if !search.isEmpty {
                    Button { search = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(.quaternary.opacity(0.6), in: RoundedRectangle(cornerRadius: 8))
        }
        .padding(.horizontal, 14)
        .padding(.top, 14)
        .padding(.bottom, 10)
    }

    // MARK: - List

    @ViewBuilder
    private var list: some View {
        if filtered.isEmpty {
            ContentUnavailableView(
                items.isEmpty ? "Nada copiado ainda" : "Sem resultados",
                systemImage: items.isEmpty ? "doc.on.clipboard" : "magnifyingglass",
                description: Text(items.isEmpty ? "Copie algo e ele aparece aqui." : "Tente outro termo.")
            )
            .frame(maxHeight: .infinity)
        } else {
            ScrollView {
                LazyVStack(spacing: 4) {
                    ForEach(filtered) { item in
                        ClipRow(item: item) { context.delete(item) }
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
            }
        }
    }

    // MARK: - Footer

    private var footer: some View {
        HStack(spacing: 8) {
            Button {
                if confirmingClear {
                    try? context.delete(model: ClipItem.self)
                    confirmingClear = false
                } else {
                    confirmingClear = true
                    Task {
                        try? await Task.sleep(for: .seconds(3))
                        confirmingClear = false
                    }
                }
            } label: {
                Label(confirmingClear ? "Confirmar?" : "Limpar",
                      systemImage: confirmingClear ? "exclamationmark.triangle.fill" : "trash")
            }
            .buttonStyle(FooterButtonStyle(tint: confirmingClear ? .red : .secondary))
            .disabled(items.isEmpty)

            Spacer()

            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                Label("Sair", systemImage: "power")
            }
            .buttonStyle(FooterButtonStyle(tint: .secondary))
        }
        .padding(10)
        .overlay(alignment: .top) { Divider() }
    }
}

// MARK: - Row

private struct ClipRow: View {
    let item: ClipItem
    let onDelete: () -> Void

    @State private var hovering = false
    @State private var copied = false

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                Text(item.text)
                    .font(.system(size: 13))
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                Text(item.createdAt, format: .relative(presentation: .named))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 2) {
                if hovering {
                    iconButton("trash", tint: .secondary, action: onDelete)
                        .transition(.opacity)
                }
                iconButton(copied ? "checkmark" : "doc.on.doc",
                           tint: copied ? .green : .secondary,
                           action: copy)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(hovering ? Color.primary.opacity(0.08) : Color.primary.opacity(0.03))
        )
        .contentShape(RoundedRectangle(cornerRadius: 8))
        .onTapGesture(perform: copy)
        .onHover { hovering = $0 }
        .animation(.easeOut(duration: 0.12), value: hovering)
    }

    private func iconButton(_ name: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: name)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(tint)
                .frame(width: 26, height: 26)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func copy() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(item.text, forType: .string)
        copied = true
        Task {
            try? await Task.sleep(for: .seconds(1.2))
            copied = false
        }
    }
}

// MARK: - Footer button

private struct FooterButtonStyle: ButtonStyle {
    let tint: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.caption.weight(.medium))
            .foregroundStyle(tint)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(tint.opacity(configuration.isPressed ? 0.2 : 0.1))
            )
    }
}

// MARK: - Resize edges

/// Zonas invisíveis nas bordas direita/inferior e no canto, que redimensionam a janela.
private struct ResizeEdges: View {
    @Binding var width: Double
    @Binding var height: Double

    @State private var start: (mouse: CGPoint, size: CGSize)?

    private let thickness: CGFloat = 8
    private let minSize = CGSize(width: 320, height: 300)
    private let maxSize = CGSize(width: 800, height: 900)

    var body: some View {
        ZStack {
            edge(.trailing, horizontal: true, vertical: false)
                .frame(width: thickness)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
                .padding(.bottom, thickness)

            edge(.bottom, horizontal: false, vertical: true)
                .frame(height: thickness)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .padding(.trailing, thickness)

            edge(.bottomTrailing, horizontal: true, vertical: true)
                .frame(width: thickness * 2, height: thickness * 2)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
        }
    }

    private func edge(_ position: FrameResizePosition, horizontal: Bool, vertical: Bool) -> some View {
        Color.clear
            .contentShape(Rectangle())
            .pointerStyle(.frameResize(position: position))
            .gesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .global)
                    .onChanged { _ in
                        // Posição global do mouse: não depende da janela, que se move ao redimensionar.
                        let mouse = NSEvent.mouseLocation
                        let origin = start ?? (mouse, CGSize(width: width, height: height))
                        start = origin
                        if horizontal {
                            width = min(max(origin.size.width + mouse.x - origin.mouse.x, minSize.width), maxSize.width)
                        }
                        if vertical {
                            height = min(max(origin.size.height - (mouse.y - origin.mouse.y), minSize.height), maxSize.height)
                        }
                    }
                    .onEnded { _ in start = nil }
            )
    }
}
