//
//  Apptentive+Debugging.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 8/10/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import UIKit

/// Encapsulates methods on the Apptentive class that may or may not eventually make it into the public API.
extension Apptentive {
    private static var engagementManifestURL: URL?

    /// The currently-set manifest override URL, if any.
    public var engagementManifestURL: URL? {
        return Self.engagementManifestURL
    }

    /// Overrides the API-provided engagement manifest with one from the specified URL.
    /// - Parameters:
    ///   - url: The (file) URL of the manifest to load.
    ///   - completion: A completion handler called with the result of loading the URL.
    public func loadEngagementManifest(at url: URL?, completion: @escaping (Result<Void, Error>) -> Void) {
        self.backendQueue.async {
            if let url = url {
                do {
                    let manifestData = try Data(contentsOf: url)

                    let engagementManifest = try JSONDecoder.apptentive.decode(EngagementManifest.self, from: manifestData)

                    self.backend.targeter.localEngagementManifest = engagementManifest

                    DispatchQueue.main.async {
                        Self.engagementManifestURL = url
                        completion(.success(()))
                    }
                } catch let error {
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                }
            } else {
                self.backend.targeter.localEngagementManifest = nil

                DispatchQueue.main.async {
                    Self.engagementManifestURL = nil
                    completion(.success(()))
                }
            }
        }
    }

    /// Returns a list of objects describing the interactions encoded in the engagement manifest.
    /// - Parameter completion: A completion handler that is called with the list of interaction items.
    public func getInteractionList(_ completion: @escaping ([InteractionListItem]) -> Void) {
        self.backendQueue.async {
            let interactionItems = self.backend.targeter.activeManifest.interactions
                .map({ InteractionListItem(id: $0.id, displayName: $0.displayName, typeName: $0.typeName) })

            DispatchQueue.main.async {
                completion(interactionItems)
            }
        }
    }

    /// Attempts to present the interaction with the specified identifier from the active engagement manifest.
    /// - Parameters:
    ///   - id: The identifier of the interaction.
    ///   - completion: A completion handler that is called with the result of attempting to present the interaction.
    public func presentInteraction(with id: String, completion: @escaping (Result<Void, Error>) -> Void) {
        self.backendQueue.async {
            if let interaction = self.backend.targeter.interactionIndex[id] {
                DispatchQueue.main.async {
                    completion(
                        Result(catching: {
                            try self.interactionPresenter.presentInteraction(interaction)
                        }))
                }
            }
        }
    }

    /// Attempts to load a JSON-encoded interaction from the specified URL and present it.
    /// - Parameters:
    ///   - url: The URL for the interaction
    ///   - completion: A completion handler that is called with the result of attempting to present the interaction.
    public func presentInteraction(at url: URL, completion: @escaping (Result<Void, Error>) -> Void) {
        self.backendQueue.async {
            do {
                let interactionData = try Data(contentsOf: url)
                let interaction = try JSONDecoder.apptentive.decode(Interaction.self, from: interactionData)

                DispatchQueue.main.async {
                    completion(
                        Result(catching: {
                            try self.interactionPresenter.presentInteraction(interaction)
                        }))
                }
            } catch let error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }

    /// An object that encapsulates the information to display an interaction in a list.
    public struct InteractionListItem {
        /// The identifier of the interaction.
        public let id: String

        /// The display name for the interaction.
        public let displayName: String

        /// The internal type name of the interaction.
        public let typeName: String
    }

    /// Calls a completion handler with a list of app-defined events that may trigger an interaction.
    /// - Parameter completion: A completion handler that is called with the list of events.
    public func getEventList(_ completion: @escaping ([String]) -> Void) {
        self.backendQueue.async {
            let targetedEvents = self.backend.targeter.activeManifest.targets.keys
                .filter({ $0.hasPrefix("local#app#") })
                .compactMap({ $0.split(separator: "#").last?.removingPercentEncoding })

            DispatchQueue.main.async {
                completion(targetedEvents)
            }
        }
    }

    /// Queries information about the current connection to the Apptentive API.
    /// - Parameter completion: A completion handler that is called with the result of the query.
    public func getConnectionInfo(_ completion: @escaping (_ state: String?, _ id: String?, _ token: String?, _ subject: String?, _ buttonLabel: String?) -> Void) {
        self.backendQueue.async {
            var stateString = "No Active Conversation"
            var subjectString: String? = nil
            var idString: String? = nil
            var buttonLabel: String? = nil
            var tokenString: String? = nil

            switch self.backend.state.roster.active?.state {
            case .placeholder:
                stateString = "Placeholder"

            case .anonymousPending:
                stateString = "Anonymous Pending"

            case .legacyPending(let legacyToken):
                tokenString = legacyToken
                stateString = "Legacy Pending"

            case .anonymous(let credentials):
                idString = credentials.id
                tokenString = credentials.token
                stateString = "Anonymous"
                buttonLabel = "Log In"

            case .loggedIn(let credentials, let subject, encryptionKey: _):
                idString = credentials.id
                tokenString = credentials.token
                subjectString = subject
                stateString = "Logged In"
                buttonLabel = "Log Out"

            default:
                idString = nil
                subjectString = nil
                stateString = "Logged Out"
                buttonLabel = "Log In"
            }

            DispatchQueue.main.async {
                completion(stateString, idString, tokenString, subjectString, buttonLabel)
            }
        }
    }
}

extension Interaction {
    var displayName: String {
        switch self.configuration {

        case .appleRatingDialog:
            return "Apple Rating Dialog"

        case .enjoymentDialog(let configuration):
            return configuration.title

        case .navigateToLink(let configuration):
            return configuration.url.absoluteString

        case .surveyV11(let configuration):
            return configuration.title ?? configuration.name ?? "Untitled"

        case .textModal(let configuration):
            return configuration.name ?? configuration.title ?? configuration.body ?? "Untitled"

        case .messageCenter(let configuration):
            return configuration.title

        case .surveyV12(let configuration):
            return configuration.title

        case .notImplemented:
            return "Not Implemented"

        case .failedDecoding:
            return "Invalid"
        }
    }
}
