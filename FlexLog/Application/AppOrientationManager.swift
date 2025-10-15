import SwiftUI
import UIKit

enum TrainingOrientationManager {
    private static var currentMask: UIInterfaceOrientationMask = .portrait

    static func configure(for outcome: GatekeeperOutcome?) {
        let desiredMask: UIInterfaceOrientationMask = {
            guard case .showTraining = outcome else { return .portrait }
            return .all
        }()
        apply(mask: desiredMask)
    }

    static func supportedOrientations() -> UIInterfaceOrientationMask {
        currentMask
    }

    static func setTrainingScreenActive(_ isActive: Bool) {
        apply(mask: isActive ? .all : .portrait)
    }

    static func set(mask: UIInterfaceOrientationMask) {
        apply(mask: mask)
    }

    private static func apply(mask: UIInterfaceOrientationMask) {
        currentMask = mask
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
        windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: mask), errorHandler: nil)
        DispatchQueue.main.async {
            if let rootController = windowScene.keyWindow?.rootViewController {
                rootController.setNeedsUpdateOfSupportedInterfaceOrientations()
            }
        }
    }
}

final class OrientationAppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        TrainingOrientationManager.supportedOrientations()
    }
}

