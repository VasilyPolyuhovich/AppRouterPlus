import Foundation
import SwiftUI
import Observation

@MainActor
@Observable
public final class SimpleRouter<Destination, Sheet> where Destination: DestinationType, Sheet: SheetType {

    public var path: [Destination] = []
    public var presentedSheets: [Sheet] = []

    public init() {}

    public var pathBinding: Binding<[Destination]> {
        Binding(get: { self.path }, set: { self.path = $0 })
    }

    public var activeSheetBinding: Binding<Sheet?> {
        Binding<Sheet?>(
            get: { self.presentedSheets.last },
            set: { newValue in
                if let v = newValue {
                    if self.presentedSheets.last != v {
                        self.presentedSheets.append(v)
                    }
                } else {
                    _ = self.presentedSheets.popLastSafe()
                }
            }
        )
    }

    public func presentSheet(_ sheet: Sheet) { presentedSheets.append(sheet) }
    public func dismissSheet() { _ = presentedSheets.popLastSafe() }
    public func dismissSheets(count: Int) {
        guard count > 0 else { return }
        (0..<count).forEach { _ in _ = presentedSheets.popLastSafe() }
    }

    public func navigateTo(_ destination: Destination, policy: NavigationPolicy = .append) {
        switch policy {
        case .replace: path = [destination]
        case .append: path.append(destination)
        case .replaceTop:
            if path.isEmpty { path = [destination] }
            else { _ = path.popLastSafe(); path.append(destination) }
        }
    }

    public func navigateTo(_ destinations: [Destination], policy: NavigationPolicy = .replace) {
        switch policy {
        case .replace: path = destinations
        case .append: path.append(contentsOf: destinations)
        case .replaceTop:
            if destinations.isEmpty { return }
            if path.isEmpty { path = destinations }
            else { _ = path.popLastSafe(); path.append(contentsOf: destinations) }
        }
    }

    public func pop() { _ = path.popLastSafe() }
    public func popToRoot() { path = [] }
}
