//
//  MessageCenterViewController.swift
//  ApptentiveKit
//
//  Created by Luqmaan Khan on 10/13/21.
//  Copyright © 2021 Apptentive, Inc. All rights reserved.
//

import PhotosUI
import QuickLook
import UIKit

class MessageCenterViewController: UITableViewController, UITextViewDelegate, MessageCenterViewModelDelegate,
    PHPickerViewControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIDocumentPickerDelegate,
    QLPreviewControllerDelegate, QLPreviewControllerDataSource, UITextFieldDelegate
{
    private let viewModel: MessageCenterViewModel
    private let headerView: GreetingHeaderView
    private let footerView: UIStackView
    private let profileView: ProfileView
    private let statusView: StatusView
    private var composeView: MessageCenterComposeView
    private var composeContainerView: MessageCenterComposeContainerView?
    private let messageReceivedCellID = "MessageCellReceived"
    private let messageSentCellID = "MessageSentCell"
    private let automatedMessageCellID = "AutomatedMessageCell"
    private var lastFocusedControl: UIFocusEnvironment?

    init(viewModel: MessageCenterViewModel) {
        self.headerView = GreetingHeaderView(frame: CGRect(origin: .zero, size: CGSize(width: 320, height: 320)))
        self.profileView = ProfileView(frame: .zero)
        self.statusView = StatusView(frame: .zero)
        self.footerView = UIStackView(frame: CGRect(origin: .zero, size: CGSize(width: 320, height: 0)))
        self.composeView = MessageCenterComposeView(frame: .zero)

        self.viewModel = viewModel

        super.init(style: .grouped)

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Controller Overrides

    override func viewDidLoad() {
        super.viewDidLoad()

        if let headerLogo = UIImage.apptentiveHeaderLogo {
            let headerImageView = UIImageView(image: headerLogo.withRenderingMode(.alwaysOriginal))
            headerImageView.contentMode = .scaleAspectFit
            self.navigationItem.titleView = headerImageView
        } else {
            self.navigationItem.title = self.viewModel.headingTitle
        }

        self.tableView.backgroundColor = .apptentiveMessageCenterBackground
        self.navigationItem.rightBarButtonItem = .apptentiveClose
        self.navigationItem.rightBarButtonItem?.target = self
        self.navigationItem.rightBarButtonItem?.action = #selector(closeMessageCenter)
        self.navigationItem.rightBarButtonItem?.accessibilityLabel = self.viewModel.closeButtonAccessibilityLabel
        self.navigationItem.rightBarButtonItem?.accessibilityHint = self.viewModel.closeButtonAccessibilityHint

        self.tableView.rowHeight = UITableView.automaticDimension
        self.tableView.estimatedRowHeight = 1000
        self.tableView.keyboardDismissMode = .interactive
        self.tableView.register(MessageReceivedCell.self, forCellReuseIdentifier: self.messageReceivedCellID)
        self.tableView.register(MessageSentCell.self, forCellReuseIdentifier: self.messageSentCellID)
        self.tableView.register(AutomatedMessageCell.self, forCellReuseIdentifier: self.automatedMessageCellID)

        self.composeView.textView.delegate = self
        self.composeView.textView.accessibilityLabel = self.viewModel.composerTitle
        self.composeView.textView.accessibilityHint = self.viewModel.composerPlaceholderText

        self.composeView.placeholderLabel.text = self.viewModel.composerPlaceholderText
        self.composeView.sendButton.addTarget(self, action: #selector(sendMessage), for: .touchUpInside)
        self.composeView.sendButton.isEnabled = self.viewModel.canSendMessage
        self.composeView.sendButton.accessibilityLabel = self.viewModel.sendButtonAccessibilityLabel
        self.composeView.sendButton.accessibilityHint = self.viewModel.sendButtonAccessibilityHint

        self.composeView.attachmentButton.addTarget(self, action: #selector(addAttachment(_:)), for: .touchUpInside)
        self.composeView.attachmentButton.isEnabled = self.viewModel.canAddAttachment
        self.composeView.attachmentButton.accessibilityLabel = self.viewModel.attachButtonAccessibilityLabel
        self.composeView.attachmentButton.accessibilityHint = self.viewModel.attachButtonAccessibilityHint

        self.composeView.attachmentStackView.tag = Self.draftMessageTag
        for index in 0..<MessageCenterViewModel.maxAttachmentCount {
            let attachmentView = DraftAttachmentView(frame: .zero)
            attachmentView.isHidden = true
            attachmentView.closeButton.addTarget(self, action: #selector(removeDraftAttachment(_:)), for: .touchUpInside)
            attachmentView.gestureRecognizer.addTarget(self, action: #selector(showAttachment(_:)))
            attachmentView.tag = index
            self.composeView.attachmentStackView.addArrangedSubview(attachmentView)
        }

        self.footerView.axis = .vertical
        self.footerView.spacing = 8

        self.tableView.tableHeaderView = self.headerView

        self.tableView.accessibilityLabel = self.viewModel.headingTitle

        self.headerView.greetingTitleLabel.text = self.viewModel.greetingTitle
        self.headerView.greetingBodyText.text = self.viewModel.greetingBody
        self.headerView.brandingImageView.url = self.viewModel.greetingImageURL

        self.profileView.nameTextField.text = self.viewModel.name
        self.profileView.nameTextField.attributedPlaceholder = NSAttributedString(string: self.viewModel.profileNamePlaceholder, attributes: [NSAttributedString.Key.foregroundColor: UIColor.apptentiveMessageCenterTextInputPlaceholder])
        self.profileView.nameTextField.accessibilityLabel = self.viewModel.editProfileNamePlaceholder
        self.profileView.nameTextField.addTarget(self, action: #selector(textFieldChanged(_:)), for: .editingChanged)
        self.profileView.nameTextField.delegate = self

        self.profileView.emailTextField.text = self.viewModel.emailAddress
        self.profileView.emailTextField.attributedPlaceholder = NSAttributedString(string: self.viewModel.profileEmailPlaceholder, attributes: [NSAttributedString.Key.foregroundColor: UIColor.apptentiveMessageCenterTextInputPlaceholder])
        self.profileView.emailTextField.accessibilityLabel = self.viewModel.editProfileEmailPlaceholder
        self.profileView.emailTextField.addTarget(self, action: #selector(textFieldChanged(_:)), for: .editingChanged)
        self.profileView.emailTextField.delegate = self

        self.profileView.errorLabel.text = self.viewModel.profileEmailInvalidError

        self.statusView.label.text = self.viewModel.statusBody

        self.updateProfileValidation(strict: self.viewModel.emailAddress?.isEmpty == false)
        self.tableView.separatorColor = .clear

        self.tableView.accessibilityElements = [self.headerView, self.footerView]
        self.showKeyboardForIpad()
        NotificationCenter.default.addObserver(self, selector: #selector(willEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
    }

    override var preferredFocusEnvironments: [UIFocusEnvironment] {
        // Presenting image/file picker seems to lose focus from the attachment button
        if let lastFocusedControl = self.lastFocusedControl {
            self.lastFocusedControl = nil
            return [lastFocusedControl]
        } else {
            return super.preferredFocusEnvironments
        }
    }

    override var prefersStatusBarHidden: Bool {
        return false
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animate { context in
            self.sizeHeaderFooterViews()
        } completion: { _ in
        }
    }

    override func indexPathForPreferredFocusedView(in tableView: UITableView) -> IndexPath? {
        if let oldestUnreadMessageIndexPath = self.viewModel.oldestUnreadMessageIndexPath {
            return oldestUnreadMessageIndexPath
        } else if let newestMessageIndexPath = self.viewModel.newestMessageIndexPath {
            return newestMessageIndexPath
        } else {
            return nil
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        self.sizeHeaderFooterViews()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if !self.initialScrollToBottomCompleted {
            self.messageCenterViewModelDraftMessageDidUpdate(self.viewModel)

            if self.viewModel.hasLoadedMessages {
                self.messageCenterViewModelMessageListDidLoad(self.viewModel)
            }

            self.viewModel.delegate = self

            self.sizeHeaderFooterViews()
            self.scrollToRelevantMessage(false)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if let argument = self.accessibilityArgument {
            UIAccessibility.post(notification: .layoutChanged, argument: argument)
            self.accessibilityArgument = nil
        }
    }

    // MARK: Input accessory view

    override var canBecomeFirstResponder: Bool {
        return self.composeContainerView != nil
    }

    override var inputAccessoryView: UIView? {
        return self.composeContainerView
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return self.viewModel.numberOfMessageGroups
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.viewModel.numberOfMessagesInGroup(at: section)
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell
        let message = self.viewModel.message(at: indexPath)

        switch message.direction {
        case .sentFromDevice:
            cell = tableView.dequeueReusableCell(withIdentifier: self.messageSentCellID, for: indexPath)

        case .sentFromDashboard:
            cell = tableView.dequeueReusableCell(withIdentifier: self.messageReceivedCellID, for: indexPath)

        case .automated:
            cell = tableView.dequeueReusableCell(withIdentifier: self.automatedMessageCellID, for: indexPath)
        }

        cell.selectionStyle = .none

        switch (message.direction, cell) {
        case (.sentFromDashboard, let receivedCell as MessageReceivedCell):
            receivedCell.messageText.isHidden = message.body?.isEmpty != false
            receivedCell.messageText.text = message.body
            receivedCell.messageText.accessibilityLabel = message.accessibilityLabel
            receivedCell.messageText.accessibilityHint = message.accessibilityHint
            receivedCell.dateLabel.text = message.statusText
            receivedCell.senderLabel.text = message.sender?.name
            receivedCell.profileImageView.url = message.sender?.profilePhotoURL
            receivedCell.attachmentStackView.isHidden = message.attachments.count == 0
            self.updateStackView(receivedCell.attachmentStackView, with: message, at: indexPath)
            receivedCell.accessibilityElements = [receivedCell.senderLabel, receivedCell.messageText, receivedCell.attachmentStackView, receivedCell.dateLabel]

        case (.sentFromDevice, let sentCell as MessageSentCell):
            sentCell.messageText.isHidden = message.body?.isEmpty != false
            sentCell.messageText.text = message.body
            sentCell.messageText.accessibilityLabel = message.accessibilityLabel
            sentCell.messageText.accessibilityHint = message.accessibilityHint
            sentCell.statusLabel.text = message.statusText
            sentCell.attachmentStackView.isHidden = message.attachments.count == 0
            self.updateStackView(sentCell.attachmentStackView, with: message, at: indexPath)
            sentCell.accessibilityElements = [sentCell.messageText, sentCell.attachmentStackView, sentCell.statusLabel]

        case (.automated, let automatedCell as AutomatedMessageCell):
            automatedCell.messageText.text = message.body

        default:
            apptentiveCriticalError("Cell type doesn't match inbound value")
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.viewModel.dateStringForMessagesInGroup(at: section)
    }

    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        self.viewModel.markMessageAsRead(at: indexPath)
    }

    // MARK: - Text Field Delegate

    func textFieldDidBeginEditing(_ textField: UITextField) {
        self.composeView.textView.layer.borderColor = UIColor.apptentiveMessageCenterTextInputBorder.cgColor
        textField.layer.borderColor = UIColor.apptentiveTextInputBorderSelected.cgColor
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        textField.layer.borderColor = UIColor.apptentiveMessageCenterTextInputBorder.cgColor

        self.updateProfileValidation(strict: textField == self.profileView.emailTextField)

        if self.viewModel.profileIsValid {
            self.viewModel.commitProfileEdits()
        }

        self.updateFooter()
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == self.profileView.nameTextField {
            self.profileView.emailTextField.becomeFirstResponder()
        } else if self.viewModel.profileIsValid {
            self.composeView.textView.becomeFirstResponder()
        } else {
            self.updateProfileValidation(strict: true)
        }

        return true
    }

    // MARK: - Text View Delegate

    func textViewDidChange(_ textView: UITextView) {
        self.sizeComposeTextView()

        self.viewModel.draftMessageBody = textView.text
        self.composeView.sendButton.isEnabled = self.viewModel.canSendMessage
    }

    func textViewDidBeginEditing(_ textView: UITextView) {
        textView.layer.borderColor = UIColor.apptentiveTextInputBorderSelected.cgColor
    }

    // MARK: - UIImagePickerControllerDelegate

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true, completion: nil)
        self.lastFocusedControl = self.composeView.attachmentButton
        if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            self.viewModel.addImageAttachment(image, name: nil)
        } else {
            ApptentiveLogger.messages.error("UIImagePickerController failed to provide picked image.")
        }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }

    // MARK: - PHPickerViewControllerDelegate

    @available(iOS 14, *)
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true, completion: nil)
        self.lastFocusedControl = self.composeView.attachmentButton
        self.setNeedsFocusUpdate()
        for result in results {
            result.itemProvider.loadObject(ofClass: UIImage.self) { (object, error) in
                if let error = error {
                    ApptentiveLogger.messages.debug("Error selecting images from PHPicker: \(error).")
                }

                guard let image = object as? UIImage else {
                    ApptentiveLogger.messages.error("PHPickerViewController failed to provide picked image.")
                    return
                }

                self.viewModel.addImageAttachment(image, name: result.itemProvider.suggestedName)
            }
        }
    }

    // MARK: - UIDocumentPickerDelegate

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        controller.dismiss(animated: true)
        self.lastFocusedControl = self.composeView.attachmentButton
        self.setNeedsFocusUpdate()
        self.viewModel.addFileAttachment(at: url)
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        controller.dismiss(animated: true, completion: nil)
    }

    // MARK: - QuickLook Preview Controller Data Source

    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return self.previewedMessage?.attachments.count ?? 0
    }

    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        guard self.previewedMessage?.attachments.count ?? 0 > index, let previewedAttachment = previewedMessage?.attachments[index] else {
            return MessageCenterViewModel.Message.Attachment(fileExtension: nil, thumbnailData: nil, localURL: nil, downloadProgress: 0)
        }

        return previewedAttachment
    }

    // MARK: - QuickLook Preview Controller Delegate

    func previewControllerDidDismiss(_ controller: QLPreviewController) {
        self.previewedMessage = nil
    }

    func previewController(_ controller: QLPreviewController, transitionViewFor item: QLPreviewItem) -> UIView? {
        if let activeStackView = self.previewSourceView?.superview as? UIStackView {
            self.previewSourceView = activeStackView.arrangedSubviews[controller.currentPreviewItemIndex]
        }

        return self.previewSourceView
    }

    // MARK: - View Model Delegate

    func messageCenterViewModelDidBeginUpdates(_: MessageCenterViewModel) {
        self.tableView.beginUpdates()
    }

    func messageCenterViewModel(_: MessageCenterViewModel, didInsertSectionsWith sectionIndexes: IndexSet) {
        self.tableView.insertSections(sectionIndexes, with: .automatic)
    }

    func messageCenterViewModel(_: MessageCenterViewModel, didDeleteSectionsWith sectionIndexes: IndexSet) {
        self.tableView.deleteSections(sectionIndexes, with: .automatic)
    }

    func messageCenterViewModel(_: MessageCenterViewModel, didDeleteRowsAt indexPaths: [IndexPath]) {
        self.tableView.deleteRows(at: indexPaths, with: .automatic)
    }

    func messageCenterViewModel(_: MessageCenterViewModel, didUpdateRowsAt indexPaths: [IndexPath]) {
        self.tableView.reloadRows(at: indexPaths, with: .fade)
    }

    func messageCenterViewModel(_: MessageCenterViewModel, didInsertRowsAt indexPaths: [IndexPath]) {
        self.tableView.insertRows(at: indexPaths, with: .automatic)
    }

    func messageCenterViewModelDidEndUpdates(_: MessageCenterViewModel) {
        self.tableView.endUpdates()

        if !self.composerIsInline && self.composeView.superview == self.footerView {
            self.moveComposeViewToInputAccessoryView()
        }

        self.updateFooter()

        self.updateProfileEditButton()

        DispatchQueue.main.async {
            self.scrollToRelevantMessage(true)
        }
    }

    func messageCenterViewModelMessageListDidLoad(_: MessageCenterViewModel) {
        if self.viewModel.shouldRequestProfile {
            self.footerView.addArrangedSubview(self.profileView)
        }

        self.footerView.addArrangedSubview(self.statusView)

        if self.composerIsInline {
            self.footerView.addArrangedSubview(self.composeView)
        } else {
            self.composeContainerView = MessageCenterComposeContainerView(composeView: self.composeView)
            self.becomeFirstResponder()
        }

        self.tableView.tableFooterView = self.footerView

        self.updateFooter()

        self.tableView.reloadData()

        self.updateProfileEditButton()

        DispatchQueue.main.async {
            // Give the `becomeFirstResponder` a chance to take effect and adjust content insets
            if !self.viewModel.shouldRequestProfile {
                self.scrollToRelevantMessage(false)
            }
        }
    }

    func postAccessibilityNotification(for indexPath: IndexPath) {
        let argument: UIView = {
            switch self.tableView.cellForRow(at: indexPath) {
            case let receivedCell as MessageReceivedCell:
                return receivedCell.messageText

            case let sentCell as MessageSentCell:
                return sentCell.messageText

            case let automatedCell as AutomatedMessageCell:
                return automatedCell.messageText

            case .none:
                return self.tableView

            default:
                apptentiveCriticalError("Expected sent, received, or automated message cell")
                return self.tableView
            }
        }()

        // Notify when a new message arrives.
        UIAccessibility.post(notification: .screenChanged, argument: argument)

        // The previous call gets overridden when first loading, so make sure to re-post in viewDidAppear.
        self.accessibilityArgument = argument
    }

    func messageCenterViewModelDraftMessageDidUpdate(_: MessageCenterViewModel) {
        self.composeView.textView.text = self.viewModel.draftMessageBody
        self.composeView.textViewDidChange()
        self.sizeComposeTextView()

        self.updateDraftAttachments()

        self.composeView.attachmentButton.isEnabled = viewModel.canAddAttachment
        self.composeView.sendButton.isEnabled = viewModel.canSendMessage
    }

    func messageCenterViewModel(_: MessageCenterViewModel, didFailToRemoveAttachmentAt index: Int, with error: Error) {
        ApptentiveLogger.messages.error("Unable to remove attachment at index \(index): \(error).")
    }

    func messageCenterViewModel(_: MessageCenterViewModel, didFailToAddAttachmentWith error: Error) {
        ApptentiveLogger.messages.error("Unable to add attachment: \(error).")
    }

    func messageCenterViewModel(_: MessageCenterViewModel, didFailToSendMessageWith error: Error) {
        ApptentiveLogger.messages.error("Unable to send message: \(error).")
    }

    func messageCenterViewModel(_: MessageCenterViewModel, attachmentDownloadDidFinishAt index: Int, inMessageAt indexPath: IndexPath) {
        self.tableView.reloadRows(at: [indexPath], with: .fade)
    }

    func messageCenterViewModel(_: MessageCenterViewModel, attachmentDownloadDidFailAt index: Int, inMessageAt indexPath: IndexPath, with error: Error) {
        ApptentiveLogger.messages.error("Unable to download attachment #\(index) in row \(indexPath.row) of section \(indexPath.section).")
        self.tableView.reloadRows(at: [indexPath], with: .fade)
    }

    // MARK: - Notifications

    @objc func keyboardWillShow(_ notification: Notification) {
        guard let keyboardRect = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
            let animationDuration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval
        else {
            ApptentiveLogger.messages.warning("Expected keyboard frame in notification")
            return
        }

        // This is only needed because we want to keep the bottom of the message list fixed WRT the bottom of the table view
        UIView.animate(withDuration: animationDuration) {
            self.tableView.contentOffset = CGPoint(x: 0, y: self.tableView.contentOffset.y + keyboardRect.height - self.tableView.adjustedContentInset.bottom)
        }
    }

    // MARK: - Actions

    @objc func willEnterForeground() {
        self.tableView.reloadData()
    }

    @objc func openProfileEditView() {
        let profileViewController = EditProfileViewController(viewModel: self.viewModel)

        let navigationController = ApptentiveNavigationController(rootViewController: profileViewController)
        navigationController.isModalInPresentation = true
        self.present(navigationController, animated: true, completion: nil)
    }

    @objc func closeMessageCenter() {
        self.viewModel.cancel()
        self.dismiss()
    }

    @objc func addAttachment(_ sender: UIButton) {
        self.showAttachmentOptions(sourceView: sender)
    }

    @objc func sendMessage() {
        self.viewModel.commitProfileEdits()

        self.viewModel.sendMessage()

        self.composeView.textView.resignFirstResponder()
        self.viewModel.draftMessageBody = nil
        self.updateFooter()

        self.navigationItem.leftBarButtonItem?.isEnabled = true
    }

    @objc func removeDraftAttachment(_ sender: UIButton) {
        let index = sender.superview?.tag ?? 0

        self.viewModel.removeAttachment(at: index)
    }

    @objc func downloadAttachment(_ sender: UITapGestureRecognizer) {
        let view = sender.view
        let index = view?.tag ?? 0
        let indexPath = self.indexPath(forTag: view?.superview?.tag ?? 0)

        self.viewModel.downloadAttachment(at: index, inMessageAt: indexPath)
    }

    @objc func showAttachment(_ sender: UITapGestureRecognizer) {
        let view = sender.view
        let index = view?.tag ?? 0
        let superViewTag = view?.superview?.tag ?? 0

        let previewController = QLPreviewController()
        previewController.dataSource = self
        previewController.delegate = self
        previewController.currentPreviewItemIndex = index

        if superViewTag == Self.draftMessageTag {
            self.previewedMessage = self.viewModel.draftMessage
        } else {
            let indexPath = self.indexPath(forTag: superViewTag)
            self.previewedMessage = self.viewModel.message(at: indexPath)
        }
        self.previewSourceView = view

        // Have to enclose this in a navigation controller as the swipe-down-to-dismiss
        // doesn't correctly restore this view controller (seems to be related to inputAccessoryView)
        let navigationController = UINavigationController(rootViewController: previewController)
        navigationController.modalPresentationStyle = .fullScreen
        previewController.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(closeAttachmentPreview(_:)))

        self.present(navigationController, animated: true)
    }

    @objc func closeAttachmentPreview(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true)
    }

    @objc func textFieldChanged(_ sender: UITextField) {
        if sender == self.profileView.nameTextField {
            self.viewModel.name = self.profileView.nameTextField.text
        } else if sender == self.profileView.emailTextField {
            self.viewModel.emailAddress = self.profileView.emailTextField.text
        }

        self.updateProfileValidation(strict: false)
    }

    // MARK: - Private

    private var initialScrollToBottomCompleted = false

    private var accessibilityArgument: UIView?

    private static let draftMessageTag: Int = 0xFFFF

    private var previewedMessage: MessageCenterViewModel.Message?
    private var previewSourceView: UIView?

    // For some reason the footer reports an outdated size before the resize animation completes,
    // which breaks the table footer view size calculation and leads to a layout glitch.
    // I spent way to much time trying and failing to fix this the "right" way, hence this hack.
    private var footerSizeAdjustment: CGFloat = 0

    private var composerIsInline: Bool {
        return self.isBigScreen && self.viewModel.numberOfMessageGroups == 0
    }

    private var isBigScreen: Bool {
        if #available(iOS 14.0, *) {
            return self.traitCollection.userInterfaceIdiom == .mac || self.traitCollection.userInterfaceIdiom == .pad
        } else {
            return self.traitCollection.userInterfaceIdiom == .pad
        }
    }

    private func dismiss() {
        self.presentingViewController?.dismiss(animated: true, completion: nil)
    }

    private func updateProfileValidation(strict: Bool) {
        if self.viewModel.profileIsValid || !strict {
            self.profileView.emailTextField.layer.borderColor = UIColor.apptentiveMessageCenterTextInputBorder.cgColor
            self.profileView.errorLabel.isHidden = true
        } else {
            self.profileView.emailTextField.layer.borderColor = UIColor.apptentiveError.cgColor
            self.profileView.errorLabel.isHidden = false
            UIAccessibility.post(notification: .screenChanged, argument: self.profileView.errorLabel)
        }

        self.composeView.sendButton.isEnabled = self.viewModel.canSendMessage
    }

    private func updateProfileEditButton() {
        if self.viewModel.shouldAllowProfileEdit {
            self.navigationItem.leftBarButtonItem = .apptentiveProfileEdit
            self.navigationItem.leftBarButtonItem?.target = self
            self.navigationItem.leftBarButtonItem?.action = #selector(openProfileEditView)
            self.navigationItem.leftBarButtonItem?.accessibilityLabel = self.viewModel.profileButtonAccessibilityLabel
            self.navigationItem.leftBarButtonItem?.accessibilityHint = self.viewModel.profileButtonAccessibilityHint
        }
    }

    @objc func scrollToRelevantMessage(_ animated: Bool) {
        self.initialScrollToBottomCompleted = true

        let oldestUnreadIndexPath = self.viewModel.oldestUnreadMessageIndexPath
        let newestMessageIndexPath = self.viewModel.newestMessageIndexPath

        if let oldestUnreadIndexPath = oldestUnreadIndexPath, oldestUnreadIndexPath != newestMessageIndexPath {
            self.tableView.scrollToRow(at: oldestUnreadIndexPath, at: .top, animated: animated)
            self.postAccessibilityNotification(for: oldestUnreadIndexPath)
        } else if let newestMessageIndexPath = newestMessageIndexPath {
            if let statusRect = self.tableView.tableFooterView?.frame, !self.statusView.isHidden {
                self.tableView.scrollRectToVisible(statusRect, animated: animated)
            } else {
                self.tableView.scrollToRow(at: newestMessageIndexPath, at: .bottom, animated: animated)
            }
            self.postAccessibilityNotification(for: newestMessageIndexPath)
        }
    }

    private func moveComposeViewToInputAccessoryView() {
        self.footerView.removeArrangedSubview(self.composeView)
        self.composeContainerView = MessageCenterComposeContainerView(composeView: composeView)
        self.sizeComposeTextView()
        self.becomeFirstResponder()
    }

    private func updateFooter() {
        self.viewModel.validateProfile()

        if self.viewModel.shouldRequestProfile {
            self.navigationItem.leftBarButtonItem?.isEnabled = false
            self.profileView.isHidden = false
        } else {
            self.navigationItem.leftBarButtonItem?.isEnabled = true
            self.profileView.isHidden = true
        }

        if let newestMessageIndexPath = self.viewModel.newestMessageIndexPath, case .sentFromDevice = self.viewModel.message(at: newestMessageIndexPath).direction {
            self.statusView.isHidden = false
        } else {
            self.statusView.isHidden = true
        }

        self.sizeHeaderFooterViews()
    }

    private func sizeComposeTextView() {
        let textView = self.composeView.textView
        var textSize = textView.sizeThatFits(CGSize(width: textView.bounds.inset(by: textView.textContainerInset).width, height: CGFloat.greatestFiniteMagnitude))

        if self.composerIsInline {
            textSize.height = max(textSize.height, 100)
        }

        self.composeView.textViewHeightConstraint?.constant = textSize.height
    }

    private func sizeHeaderFooterViews() {
        let preferredMaxLayoutWidth = self.tableView.bounds.inset(by: self.tableView.safeAreaInsets).width

        self.headerView.greetingTitleLabel.preferredMaxLayoutWidth = preferredMaxLayoutWidth

        let headerViewSize = self.headerView.systemLayoutSizeFitting(CGSize(width: self.tableView.bounds.width, height: 100), withHorizontalFittingPriority: .required, verticalFittingPriority: .fittingSizeLevel)
        self.headerView.bounds = CGRect(origin: .zero, size: headerViewSize)
        self.tableView.tableHeaderView = self.tableView.tableHeaderView

        if let footerView = self.tableView.tableFooterView {
            self.statusView.label.preferredMaxLayoutWidth = preferredMaxLayoutWidth

            var footerSize = footerView.systemLayoutSizeFitting(CGSize(width: self.tableView.bounds.width, height: UIView.layoutFittingCompressedSize.height), withHorizontalFittingPriority: .required, verticalFittingPriority: .defaultHigh)
            footerSize.height += self.footerSizeAdjustment
            footerView.bounds = CGRect(origin: .zero, size: footerSize)
            self.tableView.tableFooterView = footerView
        }
    }

    private func updateStackView(_ stackView: UIStackView, with message: MessageCenterViewModel.Message, at indexPath: IndexPath) {
        if stackView.arrangedSubviews.count < message.attachments.count {
            for _ in stackView.arrangedSubviews.count..<message.attachments.count {
                stackView.addArrangedSubview(AttachmentView(frame: .zero))
            }
        }

        for (index, subview) in stackView.arrangedSubviews.enumerated() {
            if index >= message.attachments.count {
                subview.isHidden = true
                continue
            }

            guard let attachmentIndicator = subview as? AttachmentView else {
                apptentiveCriticalError("Unknown subview in attachment stack view.")
                continue
            }

            subview.isHidden = false

            let attachment = message.attachments[index]
            attachmentIndicator.tag = index
            stackView.tag = self.tag(for: indexPath)

            if let thumbnail = attachment.thumbnail {
                attachmentIndicator.imageView.image = thumbnail
                attachmentIndicator.titleLabel.text = nil
            } else {
                attachmentIndicator.imageView.image = .apptentiveAttachmentPlaceholder
                attachmentIndicator.titleLabel.text = attachment.fileExtension
            }

            attachmentIndicator.accessibilityLabel = attachment.accessibilityLabel

            if let _ = attachment.localURL {
                attachmentIndicator.progressView.isHidden = true
                attachmentIndicator.gestureRecognizer.addTarget(self, action: #selector(showAttachment(_:)))
                attachmentIndicator.accessibilityHint = self.viewModel.showAttachmentButtonAccessibilityHint
            } else if attachment.downloadProgress == 0 {
                attachmentIndicator.progressView.isHidden = true
                attachmentIndicator.gestureRecognizer.addTarget(self, action: #selector(downloadAttachment(_:)))
                attachmentIndicator.accessibilityHint = self.viewModel.downloadAttachmentButtonAccessibilityHint
            } else {
                attachmentIndicator.progressView.isHidden = false
                attachmentIndicator.progressView.progress = attachment.downloadProgress
                attachmentIndicator.gestureRecognizer.removeTarget(self, action: nil)
                attachmentIndicator.accessibilityHint = nil
            }

            attachmentIndicator.imageView.adjustsImageSizeForAccessibilityContentSizeCategory = true
        }
    }

    private func showAttachmentOptions(sourceView: UIView) {
        let alertController = UIAlertController(title: self.viewModel.attachmentOptionsTitle, message: nil, preferredStyle: .actionSheet)
        alertController.addAction(
            UIAlertAction(
                title: self.viewModel.attachmentOptionsImagesButton, style: .default,
                handler: { _ in
                    if #available(iOS 14, *) {
                        var config = PHPickerConfiguration()
                        config.selectionLimit = self.viewModel.remainingAttachmentSlots
                        config.filter = PHPickerFilter.images

                        let pickerViewController = PHPickerViewController(configuration: config)
                        pickerViewController.delegate = self
                        self.present(pickerViewController, animated: true, completion: nil)
                    } else {
                        let imagePickerController = UIImagePickerController()
                        imagePickerController.sourceType = .photoLibrary
                        imagePickerController.delegate = self
                        self.present(imagePickerController, animated: true, completion: nil)
                    }

                }))

        alertController.addAction(
            UIAlertAction(
                title: self.viewModel.attachmentOptionsFilesButton, style: .default,
                handler: { _ in
                    if #available(iOS 14.0, *) {
                        let filePicker = UIDocumentPickerViewController(forOpeningContentTypes: self.viewModel.allUTTypes)
                        filePicker.delegate = self
                        self.present(filePicker, animated: true, completion: nil)
                    } else {
                        let filePicker = UIDocumentPickerViewController(documentTypes: self.viewModel.allFileTypes, in: .import)
                        filePicker.delegate = self
                        self.present(filePicker, animated: true, completion: nil)
                    }
                }))

        alertController.addAction(UIAlertAction(title: self.viewModel.attachmentOptionsCancelButton, style: .cancel, handler: nil))
        alertController.view.accessibilityIdentifier = "AddAttachment"

        alertController.popoverPresentationController?.sourceView = sourceView
        if self.composeView.textView.isFirstResponder {
            self.composeView.textView.resignFirstResponder()
        }
        self.present(alertController, animated: true, completion: nil)
    }

    private func indexPath(forTag tag: Int) -> IndexPath {
        return IndexPath(row: tag & 0xFFFF, section: tag >> 16)
    }

    private func tag(for indexPath: IndexPath) -> Int {
        return (indexPath.section << 16) | (indexPath.item & 0xFFFF)
    }

    private func showKeyboardForIpad() {
        if UIDevice.current.userInterfaceIdiom == .pad {
            if self.viewModel.shouldRequestProfile && self.viewModel.profileMode == .requiredEmail {
                self.profileView.emailTextField.becomeFirstResponder()
            } else {
                self.composeView.textView.becomeFirstResponder()
            }
        }
    }

    private func updateDraftAttachments() {
        // Don't animate unless the count has changed (seems to avoid layout glitches).
        let visibleCount = self.composeView.attachmentStackView.arrangedSubviews.filter { $0.isHidden == false }.count
        let shouldAnimate = visibleCount != self.viewModel.draftMessage.attachments.count && self.tableView.tableFooterView != nil

        let animations = {
            for (index, subview) in self.composeView.attachmentStackView.arrangedSubviews.enumerated() {
                if index >= self.viewModel.draftAttachments.count {
                    subview.isHidden = true
                    continue
                }

                subview.isHidden = false

                guard let attachmentView = subview as? DraftAttachmentView else {
                    apptentiveCriticalError("Unknown subview in attachment stack view.")
                    continue
                }

                let attachment = self.viewModel.draftAttachments[index]

                attachmentView.imageView.accessibilityLabel = attachment.accessibilityLabel
                attachmentView.imageView.accessibilityHint = self.viewModel.showAttachmentButtonAccessibilityHint
                attachmentView.closeButton.accessibilityLabel = attachment.removeButtonAccessibilityLabel

                if let thumbnail = attachment.thumbnail {
                    attachmentView.imageView.image = thumbnail
                } else {
                    attachmentView.imageView.image = .apptentiveAttachmentPlaceholder
                }
            }

            if visibleCount > 0 && self.viewModel.draftMessage.attachments.count == 0 {
                self.footerSizeAdjustment = -58
            } else if visibleCount == 0 && self.viewModel.draftMessage.attachments.count > 0 {
                self.footerSizeAdjustment = 58
            } else {
                self.footerSizeAdjustment = 0
            }

            self.sizeHeaderFooterViews()
        }

        if shouldAnimate {
            UIView.animate(withDuration: 0.2, animations: animations)
        } else {
            animations()
        }
    }
}
