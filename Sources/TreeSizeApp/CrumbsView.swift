// Хлебные крошки — UI-SPEC раздел 6, как renderCrumbs() в template.html
// Переиспользуется во всех вкладках правой панели.
import SwiftUI
import TreeSizeCore

/// Хлебные крошки: кнопка «↑ Вверх» и путь по сегментам.
/// Каждый сегмент кликабелен — выделяет соответствующий узел.
struct CrumbsView: View {
    /// Текущий узел (viewDir), для которого строятся крошки
    let node: Node?

    @EnvironmentObject var store: AppStore

    var body: some View {
        HStack(spacing: 2) {
            Button(action: {
                if let parent = node?.parent {
                    store.select(parent, expand: true)
                }
            }) {
                Text("↑ Вверх")
                    .font(.system(size: 12))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
            }
            .buttonStyle(.plain)
            .overlay(
                RoundedRectangle(cornerRadius: 5)
                    .stroke(Color.lineColor, lineWidth: 1)
            )
            .disabled(node?.parent == nil)
            .opacity(node?.parent == nil ? 0.4 : 1)

            if let node = node {
                ForEach(chain(for: node), id: \.id) { ancestor in
                    Text("›")
                        .foregroundColor(Color.faintColor)
                        .font(.system(size: 13))
                        .padding(.horizontal, 1)

                    Button(action: {
                        store.select(ancestor, expand: true)
                    }) {
                        Text(displayName(for: ancestor))
                            .font(.system(size: 12))
                            .foregroundColor(Color.accentLinkColor)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 2)
                    .padding(.vertical, 2)
                    .contentShape(Rectangle())
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(Color.panelBg)
    }

    /// Построить цепочку предков от корня до node (как в renderCrumbs: for (let a = view; a; a = a.p) chain.unshift(a))
    private func chain(for node: Node) -> [Node] {
        var result: [Node] = []
        var cur: Node? = node
        while let n = cur {
            result.append(n)
            cur = n.parent
        }
        return result.reversed()
    }

    /// Имя для отображения: у корня — полный путь, у остальных — displayName
    private func displayName(for node: Node) -> String {
        if node.parent == nil {
            return store.result?.root ?? node.name
        }
        return node.name
    }
}
