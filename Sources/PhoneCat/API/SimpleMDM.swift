//
//  SimpleMDM.swift
//  
//
//  Created by Robert Manson on 4/22/21.
//

import Combine
import Foundation

protocol ResponseDataItem: Decodable {
    var id: Int { get }
}

enum SimpleMDM {
    struct Response<T: ResponseDataItem>: Decodable {
        enum CodingKeys: String, CodingKey {
            case data
            case hasMore = "has_more"
        }

        let data: [T]
        let hasMore: Bool

        var startingAfter: Int? {
            guard hasMore else { return nil }
            return data.last?.id
        }
    }

    struct Device: ResponseDataItem {
        let id: Int
        let name: String
        let serial: String
        let UDID: String

        enum CodingKeys: String, CodingKey {
            case id
            case attributes
        }

        enum AttributesCodingKeys: String, CodingKey {
            case name = "device_name"
            case serial = "serial_number"
            case UDID = "unique_identifier"
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            id = try container.decode(Int.self, forKey: .id)

            let attributesContainer = try container.nestedContainer(keyedBy: AttributesCodingKeys.self, forKey: .attributes)
            name = try attributesContainer.decode(String.self, forKey: .name)
            serial = try attributesContainer.decode(String.self, forKey: .serial)
            UDID = try attributesContainer.decode(String.self, forKey: .UDID)
        }
    }

    struct Group: ResponseDataItem {
        let id: Int
        let name: String

        enum CodingKeys: String, CodingKey {
            case id
            case attributes
        }

        enum AttributesCodingKeys: String, CodingKey {
            case name
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            id = try container.decode(Int.self, forKey: .id)

            let attributesContainer = try container.nestedContainer(keyedBy: AttributesCodingKeys.self, forKey: .attributes)
            name = try attributesContainer.decode(String.self, forKey: .name)
        }
    }

    struct API {
        let token: String

        private static func makeRequest(token: String, path: String, parameters: [String: String] = [:], method: String = "GET") -> URLRequest {

            var parameters = parameters
            parameters["limit"] = "100"

            var urlComponents = URLComponents()
            urlComponents.scheme = "https"
            urlComponents.host = "a.simplemdm.com"
            urlComponents.path = path
            urlComponents.queryItems = parameters.map(URLQueryItem.init)

            guard let url = urlComponents.url else { fatalError("Could not create URL from components") }

            var request = URLRequest(url: url)
            request.httpMethod = method

            let authKeyData = Data(token.utf8)
            request.addValue("Basic \(authKeyData.base64EncodedString())", forHTTPHeaderField: "Authorization")

            return request
        }

        private func devices(startingAfter: Int?) -> AnyPublisher<SimpleMDM.Response<Device>, Error> {
            let request = Self.makeRequest(
                token: token,
                path: "/api/v1/devices",
                parameters: startingAfter.map { ["starting_after": String($0)] } ?? [:]
            )

            return URLSession(configuration: .default)
                .dataTaskPublisher(for: request)
                .tryMap() { element -> Data in
                    guard let httpResponse = element.response as? HTTPURLResponse,
                          httpResponse.statusCode == 200 else {
                        throw URLError(.badServerResponse)
                    }
                    return element.data
                }
                .decode(type: Response<Device>.self, decoder: JSONDecoder())
                .eraseToAnyPublisher()
        }

        private func groups(startingAfter: Int?) -> AnyPublisher<SimpleMDM.Response<Group>, Error> {
            let request = Self.makeRequest(
                token: token,
                path: "/api/v1/device_groups",
                parameters: startingAfter.map { ["starting_after": String($0)] } ?? [:]
            )

            return URLSession(configuration: .default)
                .dataTaskPublisher(for: request)
                .tryMap() { element -> Data in
                    guard let httpResponse = element.response as? HTTPURLResponse,
                          httpResponse.statusCode == 200 else {
                        throw URLError(.badServerResponse)
                    }
                    return element.data
                }
                .decode(type: Response<Group>.self, decoder: JSONDecoder())
                .eraseToAnyPublisher()
        }

        func allDevices() -> AnyPublisher<[Device], Error> {
            return LoadAll<Device>().fromIndexes(
                loadWithIndex: self.devices(startingAfter:)
            )
        }

        func allGroups() -> AnyPublisher<[Group], Error> {
            return LoadAll<Group>().fromIndexes(
                loadWithIndex: self.groups(startingAfter:)
            )
        }
    }
}
