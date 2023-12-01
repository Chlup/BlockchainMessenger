//
//  MErrorCodeDefinition.swift
//
//
//  Created by Michal Fousek on 01.12.2023.
//
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

import Foundation

/*
 This enum won't every be directly used in the code. It is just definition of errors and it used as source for Sourcery. And the files used in the
 code are then generated. Check `MError` and `MErrorCode`.

 Please pay attention how each error is defined here. Important part is to raw code for each error. And it's important to use /// for the
 documentation and only // for the sourcery command.

 First line of documentation for each error will be used in automatically generated `message` property.

 Error code should always start with `M` letter. Then there should be 0-4 letters that marks in which part of the SDK is the code used. And then 4
 numbers. This is suggestion to keep some order when it comes to error codes. Each code must be unique. `MErrorCode` enum is generated from these
 codes. So if the code isn't unique generated code won't compile.
*/

enum MErrorDefinition {
    /// Some error happened that is not handled as `MError`. All errors in the Messages are (should be) `MError`.
    /// This case is ideally not contructed directly or thrown by any Messages function, rather it's a wrapper for case clients expect MError and
    /// want to pass it to a function/enum. If this is the case, use `toMError()` extension of Error. This helper avoids to end up with Optional ]
    /// handling.
    // sourcery: code="MUNKWN0001"
    case unknown(_ error: Error)

    // MARK: - Synchronizer

    /// Initialisation of the Synchronizer from Zcash SDK failed.
    // sourcery: code="MSYNC0001"
    case synchronizerInitFailed(Error)

    // MARK: - DB connection

    /// Problem with creation of connection to SQLite DB.
    // sourcery: code="MSQLC0001"
    case simpleConnectionProvider(Error)

    // MARK: - Storage

    /// Can't create `Chat` entity from `Row` fetched from db.
    // sourcery: code="MSTOR0001"
    case chatEntityInit(Error)
    /// Can't create `Message` entity from `Row` fetched from db.
    // sourcery: code="MSTOR0002"
    case messageEntityInit(Error)
    /// Error when executing SQLite query and fetching multiple entities.
    // sourcery: code="MSTOR0003"
    case messagesStorageQueryExecute(Error)
    /// Error when executing SQLite query and fetching one entities.
    // sourcery: code="MSTOR0004"
    case messagesStorageEntityNotFound
    /// Trying to update alias for `chatID` and not `Chat` entity is found for `chatID`.
    // sourcery: code="MSTOR0005"
    case chatDoesntExistsWhenUpdatingAlias
    /// Verification of `Chat` itself failed. `Chat` contains different values then provided in paras to verification call.
    // sourcery: code="MSTOR0006"
    case chatVerificationFailed
    /// `Chat` was verified but update of `Chat.verified` column in DB failed.
    // sourcery: code="MSTOR0007"
    case chatUdateAfterVerificationFailed

    // MARK: - Sending

    /// Failed to store newly created `Chat` entity to the DB.
    // sourcery: code="MSEND0001"
    case storeNewChat(Error)
    /// `toAddress` provided when creating chat isn't valid unified address.
    // sourcery: code="MSEND0002"
    case invalidToAddressWhenCreatingChat
    /// Can't create memo from encoded message when creating new chat.
    // sourcery: code="MSEND0003"
    case createMemoFromMessageWhenCreatingChat(Error)
    /// Can't create recipient when creating new chat.
    // sourcery: code="MSEND0004"
    case createRecipientWhenCreatingChat(Error)
    /// Failed to get unified address for current account from the Zcash SDK when creating chat.
    // sourcery: code="MSEND0005"
    case getUnifiedAddressWhenCreatingChat
    /// Trying to send message to non-existing chat.
    // sourcery: code="MSEND0006"
    case chatDoesntExistWhenSendingMessage(Error)
    /// Failed to get unified address for current account from the Zcash SDK when creating chat.
    // sourcery: code="MSEND0007"
    case getUnifiedAddressWhenSendingMessage
}
