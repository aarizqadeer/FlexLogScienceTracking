import Foundation
import DeviceCheck

protocol AppGatekeeperProtocol {
    func bootstrapDecision() async throws -> GatekeeperOutcome
    func cachedOutcome() -> GatekeeperOutcome?
}

enum GatekeeperOutcome: Equatable {
    case showTraining(trainingToken: String, trainingLink: URL)
    case showMainApp
}

final class AppGatekeeper: AppGatekeeperProtocol {
    private enum StorageKey {
        static let trainingToken = "flexlog.training.token"
        static let trainingLink = "flexlog.training.link"
    }

    private let storage: UserDefaults
    private let networkService: TrainingNetworkServicing

    init(storage: UserDefaults = .standard,
         networkService: TrainingNetworkServicing = TrainingNetworkService()) {
        self.storage = storage
        self.networkService = networkService
    }

    func cachedOutcome() -> GatekeeperOutcome? {
        guard let token = storage.string(forKey: StorageKey.trainingToken),
              let linkString = storage.string(forKey: StorageKey.trainingLink),
              let serverRequest = URL(string: linkString) else {
            return nil
        }
        return .showTraining(trainingToken: token, trainingLink: serverRequest)
    }

    func bootstrapDecision() async throws -> GatekeeperOutcome {
        if let cached = cachedOutcome() {
            return cached
        }

        let response = try await networkService.fetchTrainingEntry()
        guard let separatorIndex = response.firstIndex(of: "#") else {
            clearStoredTraining()
            return .showMainApp
        }

        let tokenPart = String(response[..<separatorIndex])
        let linkPart = String(response[response.index(after: separatorIndex)...])

        guard let linkRequest = URL(string: linkPart) else {
            clearStoredTraining()
            return .showMainApp
        }

        storeTraining(token: tokenPart, link: linkRequest)
        return .showTraining(trainingToken: tokenPart, trainingLink: linkRequest)
    }

    private func storeTraining(token: String, link: URL) {
        storage.set(token, forKey: StorageKey.trainingToken)
        storage.set(link.absoluteString, forKey: StorageKey.trainingLink)
    }

    private func clearStoredTraining() {
        storage.removeObject(forKey: StorageKey.trainingToken)
        storage.removeObject(forKey: StorageKey.trainingLink)
    }
}

