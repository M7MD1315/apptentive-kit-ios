//
//  UIKit+Apptentive.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 12/9/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import UIKit

/// `UINavigationController` subclass intended primarily to facilitate scoping `UIAppearance` rules to Apptentive UI.
public class ApptentiveNavigationController: UINavigationController {
    static var preferredStatusBarStyle: UIStatusBarStyle = .default

    // swift-format-ignore
    public override var preferredStatusBarStyle: UIStatusBarStyle {
        return Self.preferredStatusBarStyle
    }
    /// Increases the header height for surveys.
    @objc public static var prefersLargeHeader: Bool = false

}

extension UITableView {
    /// Determines height of the separator between questions.
    public static var apptentiveQuestionSeparatorHeight: CGFloat = {
        return 0
    }()
}

extension UITableView.Style {
    /// The table view style to use for Apptentive UI.
    public static var apptentive: UITableView.Style = {

        return .insetGrouped

    }()
}

extension UIModalPresentationStyle {
    /// The modal presentation style to use for Surveys and Message Center.
    public static var apptentive: Self = .pageSheet
}

extension UIBarButtonItem {
    /// The bar button item to use for closing Apptentive UI.
    @objc public static var apptentiveClose: UIBarButtonItem = {

        return UIBarButtonItem(barButtonSystemItem: .close, target: nil, action: nil)

    }()

    /// The bar button item to use for editing the profile in message center.
    @objc public static var apptentiveProfileEdit: UIBarButtonItem = {
        let image: UIImage? = .apptentiveImage(named: "person.crop.circle")
        let barButtonItem = UIBarButtonItem(image: image, style: .done, target: nil, action: nil)
        return barButtonItem

    }()
}

extension UIButton {

    /// The close button used to replicate the bar button item when large headers are used in surveys.
    public static var apptentiveClose: UIButton? = {
        let button = UIButton()
        button.setImage(UIImage.init(systemName: "xmark"), for: .normal)
        button.tintColor = .gray
        return button

    }()

    /// The style for call-to-action buttons in Apptentive UI.
    public enum ApptentiveButtonStyle {
        /// The corner radius is half of the height.
        case pill

        /// The corner radius is the associated CGFloat value.
        case radius(CGFloat)
    }

    /// The style for call-to-action buttons in Apptentive UI.
    public static var apptentiveStyle: ApptentiveButtonStyle = .pill
}

extension UIImage {
    /// The image to use for the add attachment button for message center.
    @objc public static var apptentiveMessageAttachmentButton: UIImage? = {
        return apptentiveImage(named: "paperclip.circle.fill")
    }()

    /// The image to use for the button that sends messages for message center.
    @objc public static var apptentiveMessageSendButton: UIImage? = {
        return apptentiveImage(named: "paperplane.circle.fill")
    }()

    /// The image to use as the chat bubble for outbound messages.
    @objc public static var apptentiveSentMessageBubble: UIImage? = {
        return UIImage(named: "messageSentBubble", in: .apptentive, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate).resizableImage(withCapInsets: UIEdgeInsets(top: 9, left: 9, bottom: 14, right: 18))
    }()

    /// The image to use as the chat bubble for inbound messages.
    @objc public static var apptentiveReceivedMessageBubble: UIImage? = {
        return UIImage(named: "messageReceivedBubble", in: .apptentive, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate).resizableImage(withCapInsets: UIEdgeInsets(top: 9, left: 18, bottom: 14, right: 9))
    }()

    /// The image to use for attachment placeholders in messages and the composer.
    @objc public static var apptentiveAttachmentPlaceholder: UIImage? = {
        return UIImage(named: "document", in: .apptentive, compatibleWith: nil)?.withRenderingMode(.alwaysOriginal).resizableImage(withCapInsets: UIEdgeInsets(top: 14, left: 4, bottom: 4, right: 14))
    }()

    /// The image to use for the attachment delete button.
    @objc public static var apptentiveAttachmentRemoveButton: UIImage? = {
        if let minusImage = UIImage.init(systemName: "minus.circle.fill") {
            return minusImage
        }

        return .apptentiveImage(named: "minus.circle.fill")?.withRenderingMode(.alwaysOriginal)
    }()

    /// The image to use for the top navigation bar for surveys.
    @objc public static var apptentiveHeaderLogo: UIImage? = {
        return nil
    }()

    /// The image to use next to a radio button question choice.
    @objc public static var apptentiveRadioButton: UIImage? = {
        return apptentiveImage(named: "circle")
    }()

    /// The image to use next to a checkbox question choice.
    @objc public static var apptentiveCheckbox: UIImage? = {
        return apptentiveImage(named: "square")
    }()

    /// The image to use next to a selected radio button question choice.
    @objc public static var apptentiveRadioButtonSelected: UIImage? = {
        return apptentiveImage(named: "radio_button_active")
    }()
    
    /// The image to use next to a selected radio button question choice.
    @objc public static var batelcoRadioButtonSelected: UIImage? = {
        return apptentiveImage(named: "smallcircle.fill.circle.fill")
    }()

    /// The image to use next to a selected checkbox question choice.
    @objc public static var apptentiveCheckboxSelected: UIImage? = {
        return apptentiveImage(named: "checkmark.square.fill")
    }()

    static func apptentiveImage(named: String) -> UIImage? {

        if let result = UIImage(systemName: named) {
            return result
        }

        return UIImage(named: named, in: .apptentive, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
    }
}

extension UIColor {

    /// The color to use for the background in text inputs for message center.
    @objc public static var apptentiveMessageCenterTextInputBackground: UIColor = {

        return UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return .black

            default:
                return .white

            }
        }

    }()

    /// The placeholder color to use for text inputs for message center.
    @objc public static var apptentiveMessageCenterTextInputPlaceholder: UIColor = {

        return .placeholderText

    }()

    /// The placeholder color to use for text inputs for message center.
    @available(*, deprecated, message: "This property has been renamed to 'apptentiveMessageTextInputPlaceholder'.")
    @objc public static var apptentiveMessageTextViewPlaceholder: UIColor {
        get {
            return self.apptentiveMessageTextInputPlaceholder
        }
        set {
            self.apptentiveMessageTextInputPlaceholder = newValue
        }
    }

    /// The text color to use for all text inputs in message center.
    @objc public static var apptentiveMessageCenterTextInput: UIColor = {

        return UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return .secondaryLabel

            default:
                return .black
            }
        }

    }()

    /// The tint color for text inputs for surveys.
    @objc public static var apptentivetextInputTint: UIColor = {
        return .apptentiveTint
    }()

    /// The border color to use for the message text view.
    @objc public static var apptentiveMessageCenterTextInputBorder: UIColor = {
        return .darkGray
    }()

    /// The border color to use for the message text view.
    @available(*, deprecated, message: "This property has been renamed to 'apptentiveMessageCenterTextInputBorder'.")
    @objc public static var apptentiveMessageCenterTextViewBorder: UIColor {
        get {
            return self.apptentiveMessageCenterTextInputBorder
        }
        set {
            self.apptentiveMessageCenterTextInputBorder = newValue
        }
    }

    /// The color to use for the attachment button for the compose view for message center.
    @objc public static var apptentiveMessageCenterAttachmentButton: UIColor = {
        return .blue
    }()

    /// The color to use for the text view placeholder for the compose view for message center.
    @objc public static var apptentiveMessageTextInputPlaceholder: UIColor = {
        return .lightGray
    }()

    /// The color to use for the status message in message center.
    @objc public static var apptentiveMessageCenterStatus: UIColor = .apptentiveSecondaryLabel

    /// The color to use for the greeting body on the greeting header view for message center.
    @objc public static var apptentiveMessageCenterGreetingBody: UIColor = .apptentiveSecondaryLabel

    /// The color to use for the greeting title on the greeting header view for message center.
    @objc public static var apptentiveMessageCenterGreetingTitle: UIColor = .apptentiveSecondaryLabel

    /// The color to use for the message bubble view for inbound messages.
    @objc public static var apptentiveMessageBubbleInbound: UIColor = {
        return .darkGray
    }()

    /// The color to use for the message bubble view for outbound messages.
    @objc public static var apptentiveMessageBubbleOutbound: UIColor = {
        return UIColor(red: 0, green: 0.42, blue: 1, alpha: 1)
    }()

    /// The color to use for message labels for the inbound message body.
    @objc public static var apptentiveMessageLabelInbound: UIColor = {
        return .white
    }()

    /// The color to use for message labels for the outbound message body.
    @objc public static var apptentiveMessageLabelOutbound: UIColor = {
        return .white
    }()

    /// The color to use for labels in a non-error state.
    @objc public static var apptentiveQuestionLabel: UIColor = .apptentiveLabel

    /// The color to use for instruction labels.
    @objc public static var apptentiveInstructionsLabel: UIColor = .apptentiveSecondaryLabel

    /// The color to use for choice labels.
    @objc public static var apptentiveChoiceLabel: UIColor = .apptentiveLabel

    /// The color to use for UI elements to indicate an error state.
    @objc public static var apptentiveError: UIColor = {
        let lightModeError = UIColor(red: 0.86, green: 0.1, blue: 0, alpha: 1)
        let darkModeError = UIColor(red: 1, green: 0.28, blue: 0.24, alpha: 1)

        return UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return darkModeError

            default:
                return lightModeError
            }
        }

    }()

    /// The color to use for labels of primary prominance.
    internal static var apptentiveLabel: UIColor = {

        return .label

    }()

    /// The tint/accent color to use for buttons and similar controls in Apptentive interaction UI.
    @objc public static var apptentiveTint: UIColor = {
        if let windowScene = UIApplication.shared.connectedScenes
            .first(where: { $0 is UIWindowScene }) as? UIWindowScene,
            let tintColor = windowScene.windows.first?.tintColor
        {
            return tintColor
        } else {
            return .systemBlue
        }
    }()

    /// The color to use for labels of secondary prominence.
    @objc public static var apptentiveSecondaryLabel: UIColor = {

        return .secondaryLabel

    }()

    /// The border color to use for the segmented control for range surveys.
    @objc public static var apptentiveRangeControlBorder: UIColor = {
        return .clear
    }()

    /// The color to use for the survey introduction text.
    @objc public static var apptentiveSurveyIntroduction: UIColor = .apptentiveLabel

    /// The color to use for the borders of text fields and text views.
    @objc public static var apptentiveTextInputBorder: UIColor = {
        return lightGray
    }()

    /// The color to use for text fields and text views.
    @objc public static var apptentiveTextInputBackground: UIColor = {

        return UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return .black

            default:
                return .white

            }
        }

    }()

    /// The color to use for text within text fields and text views.
    @objc public static var apptentiveTextInput: UIColor = {

        return UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return .secondaryLabel

            default:
                return .black
            }
        }

    }()

    /// The color to use for the placeholder text within text fields and text views.
    @objc public static var apptentiveTextInputPlaceholder: UIColor = {

        return .placeholderText

    }()

    /// The color used for min and max labels for the range survey.
    @objc public static var apptentiveMinMaxLabel: UIColor = .apptentiveSecondaryLabel

    /// The color used for the background of the entire survey.
    @objc public static var apptentiveGroupedBackground: UIColor = {

        return .systemGroupedBackground

    }()

    /// The color used for the cell where the survey question is located.
    @objc public static var apptentiveSecondaryGroupedBackground: UIColor = {

        return .secondarySystemGroupedBackground

    }()

    /// The color to use for separators in e.g. table views.
    @objc public static var apptentiveSeparator: UIColor = {

        return .separator

    }()

    /// The color to use for images in a selected state for surveys.
    @objc public static var apptentiveImageSelected: UIColor = {
        return .appRed
    }()

    /// The color to use for images in a non-selected state for surveys.
    @objc public static var apptentiveImageNotSelected: UIColor = {
        return .appRed
    }()
    
    /// The background color to use for the submit button on surveys.
    @objc public static var apptentiveSubmitButton: UIColor = {
        return .apptentiveTint
    }()
    
    /// The BATELCO color to use for images in a selected state for surveys.
    @objc public static var BatelcoImageSelected: UIColor = {
        return .appRed
    }()

    /// The BATELCO color to use for images in a non-selected state for surveys.
    @objc public static var BatelcoImageNotSelected: UIColor = {
        return .appRed
    }()

    /// The background color to use for the submit button on surveys.
    @objc public static var BatelcoSubmitButton: UIColor = {
        return .appRed
    }()

    /// The background color to use for the footer which contains the terms and conditions for branched surveys.
    @objc public static var apptentiveBranchedSurveyFooter: UIColor = {
        return .apptentiveTint
    }()

    /// The color to use for the survey footer label (Thank You text).
    @available(*, deprecated, message: "This property has been renamed to 'apptentiveSubmitStatusLabel'.")
    public static var apptentiveSubmitLabel: UIColor = {
        return .apptentiveSubmitStatusLabel
    }()

    /// The color to use for the survey footer label (Thank You text).
    @objc public static var apptentiveSubmitStatusLabel: UIColor = .apptentiveLabel

    /// The color to use for the terms of service label.
    @objc public static var apptentiveTermsOfServiceLabel: UIColor = {
        return .apptentiveTint
    }()

    /// The color to use for the submit button text color.
    @objc public static var apptentiveSubmitButtonTitle: UIColor = {
        return .white
    }()

    /// The color to use for submit button border.
    @objc public static var apptentiveSubmitButtonBorder: UIColor = {
        return .clear
    }()

    /// The color to use for the space between questions.
    @objc public static var apptentiveQuestionSeparator: UIColor = {
        return .clear
    }()

    /// The color to use for the unselected segments for branched surveys.
    public static var apptentiveUnselectedSurveyIndicatorSegment: UIColor = {
        return .gray
    }()

    /// The color to use for the selected segments for branched surveys.
    public static var apptentiveSelectedSurveyIndicatorSegment: UIColor = {
        return .apptentiveTint
    }()

    /// The color to use for the background of Message Center.
    @objc public static var apptentiveMessageCenterBackground: UIColor = {
        return .white
    }()

    /// The color to use for the button that deletes the attachment from the draft message.
    @available(*, deprecated, message: "This property has been renamed to 'apptentiveAttachmentRemoveButton'.")
    @objc public static var apptentiveMessageCenterAttachmentDeleteButton: UIColor = {
        return .apptentiveAttachmentRemoveButton
    }()

    /// The color to use for the button that deletes the attachment from the draft message.
    @objc public static var apptentiveAttachmentRemoveButton: UIColor = {
        let lightModeError = UIColor(red: 0.86, green: 0.1, blue: 0, alpha: 1)
        let darkModeError = UIColor(red: 1, green: 0.28, blue: 0.24, alpha: 1)

        return UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return darkModeError

            default:
                return lightModeError
            }
        }

    }()

    /// The color to use for the compose box for Message Center.
    @objc public static var apptentiveMessageCenterComposeBoxBackground: UIColor = {
        return .white
    }()

    /// The color to use for the compose box separator.
    @objc public static var apptentiveMessageCenterComposeBoxSeparator: UIColor = {
        return .lightGray
    }()

    /// The color to use for text input borders when selected.
    @objc public static var apptentiveTextInputBorderSelected: UIColor = {
        return .blue
    }()

    /// The text color used for the disclaimer text.
    @objc public static var apptentiveDisclaimerLabel: UIColor = {
        return .lightGray
    }()
}

extension UIFont {

    /// The font to use for placeholder for text inputs in message center.
    @objc public static var apptentiveMessageCenterTextInputPlaceholder: UIFont = {
        return .preferredFont(forTextStyle: .body)
    }()

    /// The font to use for text inputs in message menter.
    @objc public static var apptentiveMessageCenterTextInput: UIFont = {
        return .preferredFont(forTextStyle: .body)
    }()

    /// The font to use for placeholder text for text inputs in surveys.
    @objc public static var apptentiveTextInputPlaceholder: UIFont = {
        return .preferredFont(forTextStyle: .body)
    }()

    /// The font to use for the greeting title for message center.
    @objc public static var apptentiveMessageCenterStatus: UIFont = {
        return .preferredFont(forTextStyle: .footnote)
    }()

    /// The font to use for the greeting title for message center.
    @objc public static var apptentiveMessageCenterGreetingTitle: UIFont = {
        return .preferredFont(forTextStyle: .headline)
    }()

    /// The font to use for the greeting body for message center.
    @objc public static var apptentiveMessageCenterGreetingBody: UIFont = {
        return .preferredFont(forTextStyle: .body)
    }()

    /// The font to use for attachment placeholder file extension labels.
    @objc public static var apptentiveMessageCenterAttachmentLabel: UIFont = {
        return .preferredFont(forTextStyle: .caption1)
    }()

    /// The font used for all survey question labels.
    @objc public static var apptentiveQuestionLabel: UIFont = {
        return .preferredFont(forTextStyle: .headline)
    }()
    
    /// The font used for all BATELCO survey question labels.
    @objc public static var BatelcoQuestionLabel: UIFont = {
        return .batelcoFontBold(ofSize: 10)
    }()

    /// The font used for the terms of service.
    @objc public static var apptentiveTermsOfServiceLabel: UIFont = {
        return .preferredFont(forTextStyle: .footnote)
    }()

    /// The font used for all survey answer choice labels.
    @objc public static var apptentiveChoiceLabel: UIFont = {
        return .batelcoFontThin(ofSize: 10)
    }()

    /// The font used for the message body in message center.
    @objc public static var apptentiveMessageLabel: UIFont = {
        return .preferredFont(forTextStyle: .body)
    }()

    /// The font used for the min and max labels for the range survey.
    @objc public static var apptentiveMinMaxLabel: UIFont = {
        return .preferredFont(forTextStyle: .footnote)
    }()

    /// The font used for the sender label in message center.
    @objc public static var apptentiveSenderLabel: UIFont = {
        return .preferredFont(forTextStyle: .caption2)
    }()

    /// The font used for the message date label in message center.
    @objc public static var apptentiveMessageDateLabel: UIFont = {
        return .preferredFont(forTextStyle: .caption2)
    }()

    /// The font used for the instructions label for surveys.
    @objc public static var apptentiveInstructionsLabel: UIFont = {
        return .preferredFont(forTextStyle: .footnote)
    }()

    /// The font used for the survey introduction label.
    @objc public static var apptentiveSurveyIntroductionLabel: UIFont = {
        return .preferredFont(forTextStyle: .subheadline)
    }()

    /// The font used for the survey footer label (Thank You text).
    @available(*, deprecated, message: "This property has been renamed to 'apptentiveSubmitStatusLabel'.")
    public static var apptentiveSubmitLabel: UIFont = {
        return .apptentiveSubmitStatusLabel
    }()

    /// The font used for the survey footer label (Thank You text).
    @objc public static var apptentiveSubmitStatusLabel: UIFont = {
        return .preferredFont(forTextStyle: .headline)
    }()

    /// The font used for the disclaimer text.
    @objc public static var apptentiveDisclaimerLabel: UIFont = {
        return .preferredFont(forTextStyle: .callout)
    }()

    /// The font used for the submit button at the end of surveys.
    @objc public static var apptentiveSubmitButtonTitle: UIFont = {
        return .preferredFont(forTextStyle: .headline)
    }()

    /// The font used for the multi- and single-line text inputs in surveys.
    @objc public static var apptentiveTextInput: UIFont = {
        return .preferredFont(forTextStyle: .body)
    }()

    /// Repairs the scalability of ``UIFont.apptentiveTextInput`` for `UITextView` and `UITextField` use.
    internal func apptentiveRepairedFont() -> UIFont {
        guard let textStyleString = self.fontDescriptor.object(forKey: UIFontDescriptor.AttributeName.textStyle) as? String else {
            ApptentiveLogger.default.warning("Font \(self.debugDescription) has a missing or invalid textStyle and will not work with Dynamic Type.")
            return self
        }

        return UIFontMetrics(forTextStyle: UIFont.TextStyle(rawValue: textStyleString)).scaledFont(for: self)
    }
}

extension UIToolbar {
    /// The circumstances under which to show a toolbar.
    @objc public enum ToolbarMode: Int {

        /// Always show the toolbar.
        case alwaysShown

        /// Show the toolbar only when there will be UI present in it.
        case hiddenWhenEmpty
    }

    /// Determines when to show a toolbar in Apptentive view controllers.
    @objc public static var apptentiveMode: ToolbarMode = .hiddenWhenEmpty
}

extension CGFloat {
    /// The width of the layer border for Apptentive buttons for surveys.
    public static var apptentiveButtonBorderWidth: CGFloat = {
        return 2
    }()
}
