//
//  MessageCenterViewModel.swift
//  ApptentiveKit
//
//  Created by Luqmaan Khan on 10/9/21.
//  Copyright © 2021 Apptentive, Inc. All rights reserved.
//

import Foundation
import MobileCoreServices
import QuickLookThumbnailing
import UIKit

/// Represents an object that can be notified of a change to the message list.
public protocol MessageCenterViewModelDelegate: AnyObject {
    func messageCenterViewModelMessageListDidUpdate(_: MessageCenterViewModel)

    func messageCenterViewModelDraftMessageDidUpdate(_: MessageCenterViewModel)

    func messageCenterViewModel(_: MessageCenterViewModel, didFailToRemoveAttachmentAt index: Int, with error: Error)

    func messageCenterViewModel(_: MessageCenterViewModel, didFailToAddAttachmentWith error: Error)

    func messageCenterViewModel(_: MessageCenterViewModel, didFailToSendMessageWith error: Error)

    func messageCenterViewModel(_: MessageCenterViewModel, attachmentDownloadDidFinishAt index: Int, inMessageAt indexPath: IndexPath)

    func messageCenterViewModel(_: MessageCenterViewModel, attachmentDownloadDidFailAt index: Int, inMessageAt indexPath: IndexPath, with error: Error)
}

typealias MessageCenterInteractionDelegate = EventEngaging & MessageSending & MessageProviding & AttachmentManaging

/// A class that describes the data in message center and allows messages to be gathered and transmitted.
public class MessageCenterViewModel: MessageManagerDelegate {
    let interaction: Interaction
    let interactionDelegate: MessageCenterInteractionDelegate

    static let maxAttachmentCount = 4

    /// The delegate object (typically a view controller) that is notified when messages change.
    weak var delegate: MessageCenterViewModelDelegate?

    /// The title for the message center window.
    public let headingTitle: String

    /// Text for branding watermark, where "Apptentive" is replaced with the logo image.
    public let branding: String

    /// The title for the composer window.
    public let composerTitle: String

    /// The title text for the send button on the composer.
    public let composerSendButtonTitle: String

    /// The title text for the attach button in the composer.
    public let composerAttachButtonTitle: String

    /// The hint text displayed in the text box for the composer.
    public let composerPlaceholderText: String

    /// The text for composer close confirmation dialog.
    public let composerCloseConfirmBody: String

    /// The text for discard message button.
    public let composerCloseDiscardButtonTitle: String

    /// The text for the composer cancel button.
    public let composerCloseCancelButtonTitle: String

    /// The title text for the greeting message.
    public let greetingTitle: String

    /// The text body for the greeting message.
    public let greetingBody: String

    /// The URL of the image to load into the greeting view.
    public let greetingImageURL: URL

    ///the message describing customer's hours, expected time until response.
    public let statusBody: String

    /// The introductory message added to conversation after consumer's message is sent.
    public let automatedMessageBody: String?

    /// The messages grouped by date, according to the current calendar, sorted with oldest messages last.
    public var groupedMessages: [[Message]]

    /// The size at which to generate thumbnails for attachments.
    public var thumbnailSize = CGSize(width: 44, height: 44) {
        didSet {
            MessageManager.thumbnailSize = self.thumbnailSize
        }
    }

    init(configuration: MessageCenterConfiguration, interaction: Interaction, interactionDelegate: MessageCenterInteractionDelegate) {
        self.interaction = interaction
        self.interactionDelegate = interactionDelegate
        self.headingTitle = configuration.title
        self.branding = configuration.branding
        self.composerTitle = configuration.composer.title
        self.composerSendButtonTitle = configuration.composer.sendButton
        self.composerAttachButtonTitle = configuration.composer.attachmentButton ?? "Add Attachment"
        self.composerPlaceholderText = configuration.composer.hintText
        self.composerCloseConfirmBody = configuration.composer.closeConfirmBody
        self.composerCloseDiscardButtonTitle = configuration.composer.closeDiscardButton
        self.composerCloseCancelButtonTitle = configuration.composer.closeCancelButton
        self.greetingTitle = configuration.greeting.title
        self.greetingBody = configuration.greeting.body
        self.greetingImageURL = configuration.greeting.imageURL
        self.statusBody = configuration.status.body
        self.automatedMessageBody = configuration.automatedMessage?.body

        self.sentDateFormatter = DateFormatter()
        self.sentDateFormatter.dateStyle = .short
        self.sentDateFormatter.doesRelativeDateFormatting = true
        self.sentDateFormatter.timeStyle = .short

        self.groupDateFormatter = DateFormatter()
        self.groupDateFormatter.dateStyle = .long
        self.groupDateFormatter.timeStyle = .none

        self.managedMessages = []
        self.groupedMessages = []
        self.draftMessage = Message(nonce: "", direction: .sentFromDevice(.failed), isAutomated: false, attachments: [], sender: nil, body: nil, sentDate: Date(), sentDateString: "")

        self.interactionDelegate.messageManagerDelegate = self

        self.interactionDelegate.getMessages { messages in
            self.messageManagerMessagesDidChange(messages)
        }

        self.interactionDelegate.getDraftMessage { draftManagedMessage in
            self.messageManagerDraftMessageDidChange(draftManagedMessage)
        }

        MessageManager.thumbnailSize = self.thumbnailSize
    }

    // MARK: Events

    /// Registers that the Message Center was successfully presented to the user.
    public func launch() {
        self.interactionDelegate.engage(event: .launch(from: self.interaction))
    }

    /// Registers that the Message Center was cancelled by the user.
    public func cancel() {
        self.interactionDelegate.engage(event: .cancel(from: self.interaction))
    }

    // TODO: Add additional events (PBI-2895)

    // MARK: List view

    /// The number of message groups.
    public var numberOfMessageGroups: Int {
        return self.groupedMessages.count
    }

    /// Returns the number of messages in the specified group.
    /// - Parameter index: the index of the message group.
    /// - Returns: the number of messages in the group.
    public func numberOfMessagesInGroup(at index: Int) -> Int {
        return self.groupedMessages[index].count
    }

    /// The date string for the message group, according to the current calendar.
    /// - Parameter index: The index of the group.
    /// - Returns: A string formatted with the date of messages in the group.
    public func dateStringForMessagesInGroup(at index: Int) -> String? {
        if self.groupedMessages[index].count > 0 {
            return self.groupDateFormatter.string(from: self.groupedMessages[index].first?.sentDate ?? Date())
        } else {
            return nil
        }
    }

    /// Provides a message for the index path.
    /// - Parameter indexPath: The index path of the message to provide.
    /// - Returns: The message object.
    public func message(at indexPath: IndexPath) -> Message {
        return self.groupedMessages[indexPath.section][indexPath.row]
    }

    /// Downloads the specified attachment and notifies the delegate.
    /// - Parameters:
    ///   - index: The index of the attachment.
    ///   - indexPath: The indexPath of the message.
    public func downloadAttachment(at index: Int, inMessageAt indexPath: IndexPath) {
        let messageViewModel = self.message(at: indexPath)
        guard let managedMessage = self.managedMessages.first(where: { $0.nonce == messageViewModel.nonce }) else {
            self.delegate?.messageCenterViewModel(self, attachmentDownloadDidFailAt: index, inMessageAt: indexPath, with: ApptentiveError.internalInconsistency)
            return
        }

        self.interactionDelegate.loadAttachment(at: index, in: managedMessage) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self.delegate?.messageCenterViewModel(self, attachmentDownloadDidFinishAt: index, inMessageAt: indexPath)

                case .failure(let error):
                    self.delegate?.messageCenterViewModel(self, attachmentDownloadDidFailAt: index, inMessageAt: indexPath, with: error)
                }
            }
        }
    }

    // MARK: Editing

    /// The message currently being composed.
    public private(set) var draftMessage: MessageCenterViewModel.Message

    /// The body of the draft message.
    public var draftMessageBody: String? {
        get {
            self.draftMessage.body
        }
        set {
            self.interactionDelegate.setDraftMessageBody(newValue)
        }
    }

    /// The attachments attached to the draft message.
    public var draftAttachments: [MessageCenterViewModel.Message.Attachment] {
        self.draftMessage.attachments
    }

    /// Attaches an image to the draft message.
    /// - Parameters:
    ///  - image: The image to attach.
    ///  - name: The name to associate with the image, if available.
    public func addImageAttachment(_ image: UIImage, name: String?) {
        guard self.canAddAttachment else {
            self.delegate?.messageCenterViewModel(self, didFailToAddAttachmentWith: MessageCenterViewModelError.attachmentCountGreaterThanMax)
            return
        }

        guard let data = image.jpegData(compressionQuality: 0.95) else {
            self.delegate?.messageCenterViewModel(self, didFailToAddAttachmentWith: MessageCenterViewModelError.unableToGetImageData)
            return
        }

        self.interactionDelegate.addDraftAttachment(data: data, name: name, mediaType: "image/jpeg") { result in
            self.finishAddingDraftAttachment(with: result)
        }
    }

    /// Attaches a file to the draft message.
    /// - Parameter sourceURL: The URL of the file to attach.
    public func addFileAttachment(at sourceURL: URL) {
        guard self.canAddAttachment else {
            self.delegate?.messageCenterViewModel(self, didFailToAddAttachmentWith: MessageCenterViewModelError.attachmentCountGreaterThanMax)
            return
        }

        self.interactionDelegate.addDraftAttachment(url: sourceURL) { result in
            self.finishAddingDraftAttachment(with: result)
        }
    }

    /// Removes an attachment from the draft message.
    /// - Parameter index: The index of the attachment to remove.
    public func removeAttachment(at index: Int) {
        self.interactionDelegate.removeDraftAttachment(at: index) { result in
            DispatchQueue.main.async {
                if case .failure(let error) = result {
                    self.delegate?.messageCenterViewModel(self, didFailToRemoveAttachmentAt: index, with: error)
                }
            }
        }
    }

    /// The difference between the maximum number of attachments and the number
    /// of attachments currently in the draft message.
    public var remainingAttachmentSlots: Int {
        return Self.maxAttachmentCount - self.draftAttachments.count
    }

    /// Whether the Add Attachment button should be enabled.
    public var canAddAttachment: Bool {
        return self.remainingAttachmentSlots > 0
    }

    /// Whether the send button should be enabled.
    public var canSendMessage: Bool {
        return self.draftAttachments.count > 0 || self.draftMessageBody?.isEmpty == false
    }

    /// Queues the message for sending to the Apptentive API.
    public func sendMessage() {
        self.interactionDelegate.sendDraftMessage { result in
            if case .failure(let error) = result {
                DispatchQueue.main.async {
                    self.delegate?.messageCenterViewModel(self, didFailToSendMessageWith: error)
                }
            }
        }
    }

    // MARK: - Message Manager Delegate (called on background queue)

    func messageManagerMessagesDidChange(_ managedMessages: [MessageList.Message]) {
        self.managedMessages = managedMessages
        let convertedMessages = managedMessages.compactMap { message -> Message? in
            if message.isHidden {
                return nil
            } else {
                return Self.convert(message, sentDateFormatter: self.sentDateFormatter, interactionDelegate: self.interactionDelegate)
            }
        }

        let groupings = Self.assembleGroupedMessages(messages: convertedMessages)

        DispatchQueue.main.async {
            self.groupedMessages = groupings
            self.delegate?.messageCenterViewModelMessageListDidUpdate(self)
        }
    }

    func messageManagerDraftMessageDidChange(_ managedDraftMessage: MessageList.Message) {
        let result = Self.convert(managedDraftMessage, sentDateFormatter: self.sentDateFormatter, interactionDelegate: self.interactionDelegate)
        DispatchQueue.main.async {
            self.draftMessage = result
            self.delegate?.messageCenterViewModelDraftMessageDidUpdate(self)
        }
    }

    // MARK: - Static (pure) functions

    static func convert(_ managedMessage: MessageList.Message, sentDateFormatter: DateFormatter, interactionDelegate: MessageCenterInteractionDelegate) -> MessageCenterViewModel.Message {
        let attachments = managedMessage.attachments.enumerated().compactMap { (index, attachment) in
            Message.Attachment(
                fileExtension: AttachmentManager.pathExtension(for: attachment.contentType) ?? "file", thumbnailData: attachment.thumbnailData, localURL: interactionDelegate.urlForAttachment(at: index, in: managedMessage),
                downloadProgress: attachment.downloadProgress)
        }

        let sender = managedMessage.sender.flatMap { Message.Sender(name: $0.name, profilePhotoURL: $0.profilePhoto) }
        let direction: Message.Direction

        switch managedMessage.status {
        case .draft:
            direction = .sentFromDevice(.draft)
        case .queued:
            direction = .sentFromDevice(.queued)
        case .sending:
            direction = .sentFromDevice(.sending)
        case .sent:
            direction = .sentFromDevice(.sent)
        case .failed:
            direction = .sentFromDevice(.failed)

        case .unread:
            direction = .sentFromDashboard(.unread)
        case .read:
            direction = .sentFromDashboard(.read)
        }

        return Message(
            nonce: managedMessage.nonce, direction: direction, isAutomated: managedMessage.isAutomated, attachments: attachments, sender: sender, body: managedMessage.body, sentDate: managedMessage.sentDate,
            sentDateString: sentDateFormatter.string(from: managedMessage.sentDate))
    }

    static func assembleGroupedMessages(messages: [Message]) -> [[Message]] {
        var result = [[Message]]()

        let messageDict = Dictionary(grouping: messages) { (message) -> Date in
            Calendar.current.startOfDay(for: message.sentDate)
        }

        let sortedKeys = messageDict.keys.sorted()
        sortedKeys.forEach { (key) in
            let values = messageDict[key]
            result.append(values ?? [])
        }

        return result
    }

    // MARK: - Private

    private var managedMessages: [MessageList.Message]

    private let sentDateFormatter: DateFormatter

    private let groupDateFormatter: DateFormatter

    private func finishAddingDraftAttachment(with result: Result<URL, Error>) {
        DispatchQueue.main.async {
            if case .failure(let error) = result {
                self.delegate?.messageCenterViewModel(self, didFailToAddAttachmentWith: error)
            }
        }
    }
}

public enum MessageCenterViewModelError: Error {
    case attachmentCountGreaterThanMax
    case unableToGetImageData
}
