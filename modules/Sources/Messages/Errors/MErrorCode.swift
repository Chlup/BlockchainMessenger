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

By design each error code should be used only at one place in the app. Thanks to that it is possible to identify exact line in the code from which the
error originates. And it can help with debugging.
*/

public enum MErrorCode: String, Equatable {
    /// Some error happened that is not handled as `MError`. All errors in the Messages are (should be) `MError`.
    case unknown = "MUNKWN0001"
    /// Initialisation of the Synchronizer from Zcash SDK failed.
    case synchronizerInitFailed = "MSYNC0001"
    /// Problem with creation of connection to SQLite DB.
    case simpleConnectionProvider = "MSQLC0001"
    /// Can't create `Chat` entity from `Row` fetched from db.
    case chatEntityInit = "MSTOR0001"
    /// Can't create `Message` entity from `Row` fetched from db.
    case messageEntityInit = "MSTOR0002"
    /// Error when executing SQLite query and fetching multiple entities.
    case messagesStorageQueryExecute = "MSTOR0003"
    /// Error when executing SQLite query and fetching one entities.
    case messagesStorageEntityNotFound = "MSTOR0004"
    /// Trying to update alias for `chatID` and not `Chat` entity is found for `chatID`.
    case chatDoesntExistsWhenUpdatingAlias = "MSTOR0005"
    /// Verification of `Chat` itself failed. `Chat` contains different values then provided in paras to verification call.
    case chatVerificationFailed = "MSTOR0006"
    /// `Chat` was verified but update of `Chat.verified` column in DB failed.
    case chatUdateAfterVerificationFailed = "MSTOR0007"
    /// Failed to store newly created `Chat` entity to the DB.
    case storeNewChat = "MSEND0001"
    /// `toAddress` provided when creating chat isn't valid unified address.
    case invalidToAddressWhenCreatingChat = "MSEND0002"
    /// Can't create memo from encoded message when creating new chat.
    case createMemoFromMessageWhenCreatingChat = "MSEND0003"
    /// Can't create recipient when creating new chat.
    case createRecipientWhenCreatingChat = "MSEND0004"
    /// Failed to get unified address for current account from the Zcash SDK when creating chat.
    case getUnifiedAddressWhenCreatingChat = "MSEND0005"
    /// Trying to send message to non-existing chat.
    case chatDoesntExistWhenSendingMessage = "MSEND0006"
    /// Failed to get unified address for current account from the Zcash SDK when creating chat.
    case getUnifiedAddressWhenSendingMessage = "MSEND0007"
}
