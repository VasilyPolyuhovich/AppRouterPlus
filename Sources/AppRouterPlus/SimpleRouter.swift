import Foundation
import SwiftUI
import Observation

@MainActor
@Observable
public final class SimpleRouter<Destination, Sheet> where Destination: DestinationType, Sheet: SheetType {

    public var path: [Destination] = []
    public var presentedSheets: [Sheet] = []
    public var presentedFullScreenCovers: [Sheet] = []
    private var interceptors: [any NavigationInterceptor<Destination>] = []

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

    public var activeFullScreenCoverBinding: Binding<Sheet?> {
        Binding<Sheet?>(
            get: { self.presentedFullScreenCovers.last },
            set: { newValue in
                if let v = newValue {
                    if self.presentedFullScreenCovers.last != v {
                        self.presentedFullScreenCovers.append(v)
                    }
                } else {
                    _ = self.presentedFullScreenCovers.popLastSafe()
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

    public func presentFullScreenCover(_ sheet: Sheet) { presentedFullScreenCovers.append(sheet) }
    public func dismissFullScreenCover() { _ = presentedFullScreenCovers.popLastSafe() }
    public func dismissFullScreenCovers(count: Int) {
        guard count > 0 else { return }
        (0..<count).forEach { _ in _ = presentedFullScreenCovers.popLastSafe() }
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
    
    // MARK: - Interceptor Management
    
    public func addInterceptor(_ interceptor: any NavigationInterceptor<Destination>) {
        interceptors.append(interceptor)
    }
    
    public func removeAllInterceptors() {
        interceptors.removeAll()
    }
    
    private func runInterceptors(from: Destination?, to: Destination) async -> Bool {
        for interceptor in interceptors {
            if !await interceptor.shouldNavigate(from: from, to: to) {
                return false
            }
        }
        return true
    }
    
    // MARK: - Navigation API (async with interceptors)
    
    @discardableResult
    public func navigateToAsync(_ destination: Destination, policy: NavigationPolicy = .append) async -> Bool {
        let current = path.last
        
        if !await runInterceptors(from: current, to: destination) {
            return false
        }
        
        navigateTo(destination, policy: policy)
        return true
    }
    
    @discardableResult
    public func navigateToAsync(_ destinations: [Destination], policy: NavigationPolicy = .replace) async -> Bool {
        guard let firstDestination = destinations.first else {
            return true
        }
        
        let current = path.last
        
        if !await runInterceptors(from: current, to: firstDestination) {
            return false
        }
        
        navigateTo(destinations, policy: policy)
        return true
    }
}
