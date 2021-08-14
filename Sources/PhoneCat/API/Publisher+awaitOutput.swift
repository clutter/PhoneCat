//
//  Publisher+awaitOutput.swift
//  
//
//  Created by Robert Manson on 4/22/21.
//

import Combine
import Foundation

struct TimeoutError: Error {
    let description: String
}

extension Publisher {
    private static var defaultTimeoutMessage: String {
        "An async operation timed out"
    }

    func awaitOutput(
        withTimeoutMessage timeoutMessage: String = defaultTimeoutMessage,
        forTimeInterval timeInterval: TimeInterval = 20
    ) throws -> Output {
        let semaphore = DispatchSemaphore(value: 0)
        var result: Result<Output, Failure>?

        let cancellable = sink(
            receiveCompletion: { completion in
                switch completion {
                case .failure(let error):
                    result = .failure(error)
                case .finished:
                    break
                }

                semaphore.signal()
            },
            receiveValue: { value in
                result = .success(value)
            }
        )

        _ = semaphore.wait(timeout: .now() + timeInterval)

        guard let output = try result?.get() else {
            cancellable.cancel()
            throw TimeoutError(description: timeoutMessage)
        }

        return output
    }
}
