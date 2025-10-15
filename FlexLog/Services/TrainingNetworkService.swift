import Foundation
import UIKit

protocol TrainingNetworkServicing {
    func fetchTrainingEntry() async throws -> String
}

enum TrainingNetworkError: LocalizedError {
    case invalidEndpoint
    case invalidResponse
    case decodingIssue

    var errorDescription: String? {
        switch self {
        case .invalidEndpoint:
            return "Endpoint misconfigured."
        case .invalidResponse:
            return "Unexpected response from training server."
        case .decodingIssue:
            return "Unable to decode training response."
        }
    }
}

struct TrainingNetworkService: TrainingNetworkServicing {
    private let session: URLSession
    private let infoProvider: TrainingInfoProviding
    private let localeProvider: LocaleProviding
    private let languageProvider: LanguageProviding

    init(session: URLSession = .shared,
         infoProvider: TrainingInfoProviding = TrainingInfoProvider(),
         localeProvider: LocaleProviding = CurrentLocaleProvider(),
         languageProvider: LanguageProviding = PreferredLanguageProvider()) {
        self.session = session
        self.infoProvider = infoProvider
        self.localeProvider = localeProvider
        self.languageProvider = languageProvider
    }

    func fetchTrainingEntry() async throws -> String {
        guard var components = URLComponents(string: ServerConfig.trainingEndpoint) else {
            throw TrainingNetworkError.invalidEndpoint
        }

        var queryItems: [URLQueryItem] = []
        queryItems.append(URLQueryItem(name: "p", value: ServerConfig.partnerKey))
        queryItems.append(URLQueryItem(name: "os", value: infoProvider.deviceVersion))
        queryItems.append(URLQueryItem(name: "lng", value: languageProvider.fetchLanguageIdentifier()))
        queryItems.append(URLQueryItem(name: "devicemodel", value: infoProvider.deviceModel))
        queryItems.append(URLQueryItem(name: "country", value: localeProvider.fetchCountryCode()))

        components.queryItems = queryItems

        guard let serverRequest = components.url else {
            throw TrainingNetworkError.invalidEndpoint
        }
        var request = URLRequest(url: serverRequest)
        request.httpMethod = "GET"

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw TrainingNetworkError.invalidResponse
        }

        guard let responseString = String(data: data, encoding: .utf8) else {
            throw TrainingNetworkError.decodingIssue
        }
        return responseString
    }
}

protocol TrainingInfoProviding {
    var deviceVersion: String { get }
    var deviceModel: String { get }
}

struct TrainingInfoProvider: TrainingInfoProviding {
    var deviceVersion: String {
        UIDevice.current.systemVersion
    }

    var deviceModel: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let rawCode = withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                ptr in String.init(validatingUTF8: ptr)
            }
        } ?? ""
        return rawCode
        }

    private func resolveMachineIdentifier() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce(into: "") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return }
            identifier.append(String(UnicodeScalar(UInt8(value))))
        }
        return identifier
    }
}

protocol LocaleProviding {
    func fetchCountryCode() -> String
}

struct CurrentLocaleProvider: LocaleProviding {
    func fetchCountryCode() -> String {
        let locale = Locale.preferredLanguages.first ?? "ee"
        let parts = locale.components(separatedBy: "-")

        if parts.count >= 2 {
            let region = parts[1]
            return region
        }
        return "US"
    }
}

protocol LanguageProviding {
    func fetchLanguageIdentifier() -> String
}

struct PreferredLanguageProvider: LanguageProviding {
    func fetchLanguageIdentifier() -> String {
        let locale = Locale.preferredLanguages.first ?? "oo"
        let parts = locale.components(separatedBy: "-")

        if parts.count >= 2 {
            let language = parts[0]
            return language
        }
        return "en"
    }
}

