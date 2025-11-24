import SwiftUI
import Combine

#if os(macOS)
import AppKit

class KeyboardShortcuts: ObservableObject {
    static let shared = KeyboardShortcuts()
    
    let keySubject = PassthroughSubject<Key, Never>()
    
    enum Key {
        case space
        case leftArrow
        case rightArrow
        case upArrow
        case downArrow
        case escape
    }
    
    private var monitor: Any?
    
    init() {
        startMonitoring()
    }
    
    deinit {
        stopMonitoring()
    }
    
    func startMonitoring() {
        guard monitor == nil else { return }
        
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self else { return event }
            
            switch event.keyCode {
            case 49: // Space
                self.keySubject.send(.space)
                return nil
                
            case 123: // Left Arrow
                self.keySubject.send(.leftArrow)
                return nil
                
            case 124: // Right Arrow
                self.keySubject.send(.rightArrow)
                return nil
                
            case 126: // Up Arrow
                self.keySubject.send(.upArrow)
                return nil
                
            case 125: // Down Arrow
                self.keySubject.send(.downArrow)
                return nil
                
            case 53: // Escape
                self.keySubject.send(.escape)
                return nil
                
            default:
                return event
            }
        }
    }
    
    func stopMonitoring() {
        if let monitor = monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
    }
}
#else
class KeyboardShortcuts: ObservableObject {
    static let shared = KeyboardShortcuts()
    // No-op for iOS
}
#endif
