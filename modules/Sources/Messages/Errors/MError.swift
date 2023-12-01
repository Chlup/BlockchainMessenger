// Generated using Sourcery 2.0.3 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

//  MIT License
//
//  Copyright (c) 2023 Zcash
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

/*
!!!!! To edit this file go to MErrorCodeDefinition first and udate/add codes. Then run generateErrorCode.sh script to regenerate this file.

By design each error should be used only at one place in the app. Thanks to that it is possible to identify exact line in the code from which the
error originates. And it can help with debugging.
*/

import Foundation

public enum MError: Equatable, Error {
    /// Some error happened that is not handled as `MError`. All errors in the Messages are (should be) `MError`.
    /// This case is ideally not contructed directly or thrown by any Messages function, rather it's a wrapper for case clients expect MError and
    /// want to pass it to a function/enum. If this is the case, use `toMError()` extension of Error. This helper avoids to end up with Optional ]
    /// handling.
    /// MUNKWN0001
    case unknown(_ error: Error)
    /// Initialisation of the Synchronizer from Zcash SDK failed.
    /// MSYNC0001
    case synchronizerInitFailed(_ : Error)
    /// Problem with creation of connection to SQLite DB.
    /// MSQLC0001
    case simpleConnectionProvider(_ : Error)
    /// Can't create `Chat` entity from `Row` fetched from db.
    /// MSTOR0001
    case chatEntityInit(_ : Error)
    /// Can't create `Message` entity from `Row` fetched from db.
    /// MSTOR0002
    case messageEntityInit(_ : Error)
    /// Error when executing SQLite query and fetching multiple entities.
    /// MSTOR0003
    case messagesStorageQueryExecute(_ : Error)
    /// Error when executing SQLite query and fetching one entities.
    /// MSTOR0004
    case messagesStorageEntityNotFound
    /// Trying to update alias for `chatID` and not `Chat` entity is found for `chatID`.
    /// MSTOR0005
    case chatDoesntExistsWhenUpdatingAlias
    /// Verification of `Chat` itself failed. `Chat` contains different values then provided in paras to verification call.
    /// MSTOR0006
    case chatVerificationFailed
    /// `Chat` was verified but update of `Chat.verified` column in DB failed.
    /// MSTOR0007
    case chatUdateAfterVerificationFailed
    /// Failed to store newly created `Chat` entity to the DB.
    /// MSEND0001
    case storeNewChat(_ : Error)
    /// `toAddress` provided when creating chat isn't valid unified address.
    /// MSEND0002
    case invalidToAddressWhenCreatingChat
    /// Can't create memo from encoded message when creating new chat.
    /// MSEND0003
    case createMemoFromMessageWhenCreatingChat(_ : Error)
    /// Can't create recipient when creating new chat.
    /// MSEND0004
    case createRecipientWhenCreatingChat(_ : Error)
    /// Failed to get unified address for current account from the Zcash SDK when creating chat.
    /// MSEND0005
    case getUnifiedAddressWhenCreatingChat
    /// Trying to send message to non-existing chat.
    /// MSEND0006
    case chatDoesntExistWhenSendingMessage(_ : Error)
    /// Failed to get unified address for current account from the Zcash SDK when creating chat.
    /// MSEND0007
    case getUnifiedAddressWhenSendingMessage

    public var message: String {
        switch self {
        case .unknown: return "Some error happened that is not handled as `MError`. All errors in the Messages are (should be) `MError`."
        case .synchronizerInitFailed: return "Initialisation of the Synchronizer from Zcash SDK failed."
        case .simpleConnectionProvider: return "Problem with creation of connection to SQLite DB."
        case .chatEntityInit: return "Can't create `Chat` entity from `Row` fetched from db."
        case .messageEntityInit: return "Can't create `Message` entity from `Row` fetched from db."
        case .messagesStorageQueryExecute: return "Error when executing SQLite query and fetching multiple entities."
        case .messagesStorageEntityNotFound: return "Error when executing SQLite query and fetching one entities."
        case .chatDoesntExistsWhenUpdatingAlias: return "Trying to update alias for `chatID` and not `Chat` entity is found for `chatID`."
        case .chatVerificationFailed: return "Verification of `Chat` itself failed. `Chat` contains different values then provided in paras to verification call."
        case .chatUdateAfterVerificationFailed: return "`Chat` was verified but update of `Chat.verified` column in DB failed."
        case .storeNewChat: return "Failed to store newly created `Chat` entity to the DB."
        case .invalidToAddressWhenCreatingChat: return "`toAddress` provided when creating chat isn't valid unified address."
        case .createMemoFromMessageWhenCreatingChat: return "Can't create memo from encoded message when creating new chat."
        case .createRecipientWhenCreatingChat: return "Can't create recipient when creating new chat."
        case .getUnifiedAddressWhenCreatingChat: return "Failed to get unified address for current account from the Zcash SDK when creating chat."
        case .chatDoesntExistWhenSendingMessage: return "Trying to send message to non-existing chat."
        case .getUnifiedAddressWhenSendingMessage: return "Failed to get unified address for current account from the Zcash SDK when creating chat."
        }
    }

    public var code: MErrorCode {
        switch self {
        case .unknown: return .unknown
        case .synchronizerInitFailed: return .synchronizerInitFailed
        case .simpleConnectionProvider: return .simpleConnectionProvider
        case .chatEntityInit: return .chatEntityInit
        case .messageEntityInit: return .messageEntityInit
        case .messagesStorageQueryExecute: return .messagesStorageQueryExecute
        case .messagesStorageEntityNotFound: return .messagesStorageEntityNotFound
        case .chatDoesntExistsWhenUpdatingAlias: return .chatDoesntExistsWhenUpdatingAlias
        case .chatVerificationFailed: return .chatVerificationFailed
        case .chatUdateAfterVerificationFailed: return .chatUdateAfterVerificationFailed
        case .storeNewChat: return .storeNewChat
        case .invalidToAddressWhenCreatingChat: return .invalidToAddressWhenCreatingChat
        case .createMemoFromMessageWhenCreatingChat: return .createMemoFromMessageWhenCreatingChat
        case .createRecipientWhenCreatingChat: return .createRecipientWhenCreatingChat
        case .getUnifiedAddressWhenCreatingChat: return .getUnifiedAddressWhenCreatingChat
        case .chatDoesntExistWhenSendingMessage: return .chatDoesntExistWhenSendingMessage
        case .getUnifiedAddressWhenSendingMessage: return .getUnifiedAddressWhenSendingMessage
        }
    }

    public static func == (lhs: MError, rhs: MError) -> Bool {
        return lhs.code == rhs.code
    }
}
