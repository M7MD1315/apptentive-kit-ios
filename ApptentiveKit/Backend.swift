//
//  Backend.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 8/10/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import Foundation

/// The backend includes internal top-level methods used by the SDK.
///
/// It is implemented as a separate class from `Apptentive` to help enforce the main queue/background queue separation.
class Backend {
    /// The private background queue used for executing methods in this class.
    let queue: DispatchQueue

    /// The `Apptentive` instance that owns this `Backend` instance.
    weak var frontend: Apptentive?

    /// Indicates the source of the conversation credentials when calling `connect(appCredentials:baseURL:completion:)`.
    enum ConnectionType {

        /// The conversation credentials were loaded from persistent storage.
        case cached

        /// The conversation credentials were retrieved from the API.
        case new
    }

    /// The primary persistent record of the state of the SDK.
    ///
    /// An temporary conversation object is created when the backend is initialized. When access to the device's
    /// persistent storage becomes available, any existing conversation is loaded and any newer data from
    /// the temporary conversation is merged into the saved conversation. This allows the SDK to function
    /// regardless of the order in which `load(containerURL:fileManager:)` and `connect(appCredentials:baseURL:completion:)`
    /// are called.
    var conversation: Conversation {
        didSet {
            self.processChanges(from: oldValue)
        }
    }

    /// The file repository used to load and save the conversation from/to persistent storage.
    private var conversationRepository: PropertyListRepository<Conversation>?

    /// The object that determines whether an interaction should be presented when an event is engaged.
    private var targeter: Targeter

    private var payloadSender: PayloadSender

    private var requestRetrier: HTTPRequestRetrier<ApptentiveV9API>

    /// The completion handler that should be called when conversation credentials are loaded/retrieved.
    private var connectCompletion: ((Result<ConnectionType, Error>) -> Void)?

    /// Whether the conversation has changes that need to be saved to persistent storage.
    private var conversationNeedsSaving: Bool = false

    private var persistenceTimer: DispatchSourceTimer?

    /// Initializes a new backend instance.
    /// - Parameters:
    ///   - queue: The dispatch queue on which the backend instance should run.
    ///   - environment: The environment object used to initialize the conversation.
    ///   - baseURL: The URL where the Apptentive API is based.
    convenience init(queue: DispatchQueue, environment: ConversationEnvironment, baseURL: URL) {
        let conversation = Conversation(environment: environment)
        let client = HTTPClient<ApptentiveV9API>(requestor: URLSession.shared, baseURL: baseURL, userAgent: ApptentiveV9API.userAgent(sdkVersion: environment.sdkVersion))
        let requestRetrier = HTTPRequestRetrier(retryPolicy: HTTPRetryPolicy(), client: client, queue: queue)
        let payloadSender = PayloadSender(requestRetrier: requestRetrier)

        self.init(queue: queue, conversation: conversation, targeter: Targeter(), requestRetrier: requestRetrier, payloadSender: payloadSender)
    }

    /// This initializer intended for testing only.
    /// - Parameters:
    ///   - queue: The dispatch queue on which the backend instance should run.
    ///   - conversation: The conversation that the backend should start with.
    ///   - targeter: The targeter to use to determine if events should show an interaction.
    ///   - requestRetrier: The Apptentive API request retrier to use to send API requests.
    ///   - payloadSender: The payload sender to use to send updates to the API.
    init(queue: DispatchQueue, conversation: Conversation, targeter: Targeter, requestRetrier: HTTPRequestRetrier<ApptentiveV9API>, payloadSender: PayloadSender) {
        self.queue = queue
        self.conversation = conversation
        self.targeter = targeter
        self.requestRetrier = requestRetrier
        self.payloadSender = payloadSender
    }

    deinit {
        self.persistenceTimer?.setEventHandler(handler: nil)
        self.persistenceTimer?.cancel()
        self.persistenceTimer?.resume()
    }

    /// Connects the backend to the Apptentive API.
    /// - Parameters:
    ///   - appCredentials: The App Key and App Signature to use when communicating with the Apptentive API
    ///   - completion: A completion handler to be called when conversation credentials are loaded/retrieved, or when loading/retrieving fails.
    func connect(appCredentials: Apptentive.AppCredentials, completion: @escaping (Result<ConnectionType, Error>) -> Void) {
        guard self.conversation.appCredentials == nil || self.conversation.appCredentials == appCredentials else {
            completion(.failure(ApptentiveError.mismatchedCredentials))
            return
        }

        self.connectCompletion = completion

        self.conversation.appCredentials = appCredentials
    }

    /// Loads a previously saved conversation, if any, from persistent storage.
    /// - Parameters:
    ///   - containerURL: A file URL corresponding to the container directory for Apptentive files.
    ///   - fileManager: The `FileManager` instance to use when accessing the filesystem.
    /// - Throws: An error if the conversation file exists but can't be read, or if the saved conversation can't be merged with the in-memory conversation.
    func load(containerURL: URL, fileManager: FileManager) throws {
        try self.createContainerDirectoryIfNeeded(containerURL: containerURL, fileManager: fileManager)

        let conversationRepository = PropertyListRepository<Conversation>(containerURL: containerURL, filename: "Conversation", fileManager: fileManager)
        self.conversationRepository = conversationRepository

        if conversationRepository.fileExists {
            ApptentiveLogger.default.info("Loading previously-saved conversation.")

            let savedConversation = try conversationRepository.load()

            self.conversation = try savedConversation.merged(with: self.conversation)
        }

        self.payloadSender.repository = PayloadSender.createRepository(containerURL: containerURL, filename: "PayloadQueue", fileManager: fileManager)

        self.startPeristenceTimer()
    }

    func willEnterForeground() {
        self.payloadSender.resume()

        self.persistenceTimer?.resume()
    }

    func didEnterBackground() {
        self.payloadSender.suspend()

        self.persistenceTimer?.suspend()

        self.saveToPersistentStorageIfNeeded()
    }

    /// Engages an event.
    ///
    /// This consists of the following steps:
    /// 1. Sends an API request to create the event on the server.
    /// 2. Increments the relevant engagement metric in the conversation.
    /// 3. Presents an interaction if one was triggered by the event being engaged.
    /// - Parameters:
    ///   - event: The `Event` object to be engaged.
    ///   - completion: A completion handler whose argument indicates whether engaging the event resulted in the presentation of an interaction.
    func engage(event: Event, completion: ((Bool) -> Void)?) {
        self.payloadSender.send(Payload(wrapping: event), for: self.conversation)

        self.conversation.codePoints.invoke(for: event.codePointName)

        do {
            if let interaction = try self.targeter.interactionData(for: event, state: self.conversation) {
                try self.presentInteraction(interaction, completion: completion)
            } else {
                DispatchQueue.main.async {
                    completion?(false)
                }
            }
        } catch let error {
            DispatchQueue.main.async {
                completion?(false)
                ApptentiveLogger.engagement.error("Targeting error: \(error).")
                assertionFailure("Targeting error: \(error)")
            }
        }
    }

    /// Sends a survey response to the Apptentive API.
    /// - Parameter surveyResponse: The survey response to send to the API.
    func send(surveyResponse: SurveyResponse) {
        self.payloadSender.send(Payload(wrapping: surveyResponse), for: self.conversation, persistEagerly: true)
    }

    /// Evaluates a list of invocations and presents an interaction, if needed.
    /// - Parameters:
    ///   - invocations: The invocations to evaluate.
    ///   - completion: A completion handler called with the ID of the presented interaction, if any.
    func invoke(_ invocations: [EngagementManifest.Invocation], completion: @escaping (String?) -> Void) {
        do {
            guard let destinationInteraction = try self.targeter.interactionData(for: invocations, state: self.conversation) else {
                throw ApptentiveError.internalInconsistency
            }

            try self.presentInteraction(destinationInteraction) { (success) in
                if success {
                    completion(destinationInteraction.id)
                } else {
                    ApptentiveLogger.interaction.error("TextModal button had no invocations with matching criteria.")
                    assertionFailure("TextModal button had no invocations with matching criteria.")
                }
            }
        } catch let error {
            DispatchQueue.main.async {
                completion(nil)
            }

            ApptentiveLogger.interaction.error("TextModal button targeting error: \(error).")
            assertionFailure("TextModal button targeting error: \(error).")
        }
    }

    private func presentInteraction(_ interaction: Interaction, completion: ((Bool) -> Void)?) throws {
        ApptentiveLogger.interaction.info("Attempting to present \(interaction.typeName) interaction.")

        guard let frontend = self.frontend else {
            throw ApptentiveError.internalInconsistency
        }

        DispatchQueue.main.async {
            do {
                try frontend.interactionPresenter.presentInteraction(interaction)

                completion?(true)

                self.queue.async {
                    self.conversation.interactions.invoke(for: interaction.id)
                }
            } catch let error {
                completion?(false)
                ApptentiveLogger.default.error("Interaction presentation error: \(error).")
                assertionFailure("Interaction presentation error: \(error).")
            }
        }
    }

    /// Reacts to any changes in the conversation.
    ///
    /// This is the main "event loop" of the SDK, and centralizes the behavior in response to changes in the conversation.
    /// - Parameter oldValue: The previous value of the conversation.
    private func processChanges(from oldValue: Conversation) {
        // Determine whether we have conversation credentials.
        if let _ = conversation.conversationCredentials {

            // If we have credentials but we have not called the completion block, do so.
            if let connectCompletion = self.connectCompletion {
                connectCompletion(.success(.cached))
                self.connectCompletion = nil
            }

            // Supply the payload sender with necessary credentials
            if payloadSender.credentials == nil {
                ApptentiveLogger.network.debug("Activating payload sender.")

                self.payloadSender.credentials = self.conversation
            }

            // Retrieve a new engagement manifest if the previous one is missing or expired.
            self.getInteractionsIfNeeded()

            if self.conversation.person != oldValue.person {
                ApptentiveLogger.network.debug("Person data changed. Enqueueing update.")

                self.payloadSender.send(Payload(wrapping: self.conversation.person), for: self.conversation)
            }

            if self.conversation.device != oldValue.device {
                ApptentiveLogger.network.debug("Device data changed. Enqueueing update.")

                self.payloadSender.send(Payload(wrapping: self.conversation.device), for: self.conversation)
            }

            if self.conversation.appRelease != oldValue.appRelease {
                ApptentiveLogger.network.debug("App release data changed. Enqueueing update.")

                self.payloadSender.send(Payload(wrapping: self.conversation.appRelease), for: self.conversation)
            }
        } else if let _ = conversation.appCredentials {
            // App credentials allow us to retrieve conversation credentials from the API.
            self.createConversationOnServer()
        }  // else we can't really do anything because we can't talk to the API.

        // Mark the conversation as needing to be saved.
        self.conversationNeedsSaving = true
    }

    /// Saves the conversation and payload queue to persistent storage if needed.
    func saveToPersistentStorageIfNeeded() {
        do {
            try self.saveConversationIfNeeded()
            try self.payloadSender.savePayloadsIfNeeded()
        } catch let error {
            ApptentiveLogger.default.error("Unable to save files to persistent storage: \(error).")
            assertionFailure("Unable to save files to persistent storage: \(error.localizedDescription)")
        }
    }

    /// Saves the conversation to persistent storage.
    private func saveConversationIfNeeded() throws {
        if let repository = self.conversationRepository, self.conversationNeedsSaving {
            try repository.save(self.conversation)
            self.conversationNeedsSaving = false
        }
    }

    private func startPeristenceTimer() {
        let persistenceTimer = DispatchSource.makeTimerSource(flags: [], queue: self.queue)
        persistenceTimer.schedule(deadline: .now(), repeating: .seconds(10), leeway: .seconds(1))
        persistenceTimer.setEventHandler { [weak self] in
            ApptentiveLogger.default.debug("Running periodic persistence task")
            self?.saveToPersistentStorageIfNeeded()
        }

        persistenceTimer.resume()

        self.persistenceTimer = persistenceTimer
    }

    /// Creates a conversation on the Apptentive server using the API.
    private func createConversationOnServer() {
        ApptentiveLogger.default.info("Requesting a new conversation via Apptentive API.")

        self.requestRetrier.startUnlessUnderway(.createConversation(self.conversation), identifier: "create conversation") { (result: Result<ConversationResponse, Error>) in
            switch result {
            case .success(let conversationResponse):
                self.conversation.conversationCredentials = Conversation.ConversationCredentials(token: conversationResponse.token, id: conversationResponse.id)
                self.connectCompletion?(.success(.new))
            case .failure(let error):
                self.connectCompletion?(.failure(error))
            }

            self.connectCompletion = nil
        }
    }

    /// Retrieves an engagement manifest from the Apptentive API if the current one is missing or expired.
    private func getInteractionsIfNeeded() {
        // Make sure we don't have a request in flight already, and that the engagement manifest in memory (if any) is expired.
        if (self.targeter.engagementManifest.expiry ?? Date.distantPast) < Date() {
            ApptentiveLogger.default.info("Requesting new engagement manifest via Apptentive API (current one is absent or stale).")

            self.requestRetrier.startUnlessUnderway(.getInteractions(with: self.conversation), identifier: "get interactions") { (result: Result<EngagementManifest, Error>) in
                switch result {
                case .success(let engagementManifest):
                    ApptentiveLogger.default.debug("New engagement manifest received.")

                    self.targeter.engagementManifest = engagementManifest

                case .failure(let error):
                    ApptentiveLogger.network.error("Failed to download engagement manifest: \(error).")
                }
            }
        }
    }

    /// Creates a container directory if does not already exist.
    /// - Parameters:
    ///   - containerURL: The URL at which the directory should reside.
    ///   - fileManager: The `FileManager` object used to create the directory.
    /// - Throws: An error if the directory can't be created, or if an existing file is in the way of the directory.
    private func createContainerDirectoryIfNeeded(containerURL: URL, fileManager: FileManager) throws {
        var isDirectory: ObjCBool = false

        if !fileManager.fileExists(atPath: containerURL.path, isDirectory: &isDirectory) {
            ApptentiveLogger.default.debug("Creating directory for Apptentive SDK data at \(containerURL).")

            try fileManager.createDirectory(at: containerURL, withIntermediateDirectories: true, attributes: [:])
        } else if !isDirectory.boolValue {
            throw ApptentiveError.fileExistsAtContainerDirectoryPath
        }
    }
}