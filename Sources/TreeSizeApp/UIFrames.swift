import SwiftUI

/// Рамки размеченных вью в координатах, переданных через NSHostingView.
/// Нужны только самотесту.
struct UIFramesKey: PreferenceKey {
    static var defaultValue: [String: CGRect] = [:]
    static func reduce(value: inout [String: CGRect], nextValue: () -> [String: CGRect]) {
        value.merge(nextValue()) { $1 }
    }
}

extension View {
    func uiTag(_ tag: String) -> some View {
        background(GeometryReader { g in
            Color.clear.preference(key: UIFramesKey.self, value: [tag: g.frame(in: .named("uitest"))])
        })
    }
}

/// Модификатор, устанавливающий координатное пространство "uitest"
/// на корневой ContentView.
struct UITestSpace: ViewModifier {
    func body(content: Content) -> some View {
        content.coordinateSpace(name: "uitest")
    }
}