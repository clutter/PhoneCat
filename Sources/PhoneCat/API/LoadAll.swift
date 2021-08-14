//
//  LoadAll.swift
//  
//
//  Created by Robert Manson on 4/22/21.
//

import Combine
import Foundation

struct LoadAll<T: ResponseDataItem> {
    func fromIndexes(
        loadWithIndex: @escaping (_ index: Int?) -> AnyPublisher<SimpleMDM.Response<T>, Error>
    ) -> AnyPublisher<[T], Error> {
        let pageIndexPublisher = CurrentValueSubject<Int?, Error>(nil)

        return pageIndexPublisher
            .flatMap({ index in
                return loadWithIndex(index)
            })
            .handleEvents(receiveOutput: { (response: SimpleMDM.Response<T>) in
                if let index = response.startingAfter {
                    pageIndexPublisher.send(index)
                } else  {
                    pageIndexPublisher.send(completion: .finished)
                }
            })
            .reduce([T](), { allItems, response in
                return response.data + allItems
            })
            .eraseToAnyPublisher()
    }
}
