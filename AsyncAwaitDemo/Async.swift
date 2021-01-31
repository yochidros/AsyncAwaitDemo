//
//  Async.swift
//  AsyncAwaitDemo
//
//  Created by yochidros on 2021/01/31.
//

import Foundation
import _Concurrency


struct User: Decodable {
    let id: String
    let createdAt: Date
    let avatarUrl: String
    let name: String

    enum CodingKeys: String, CodingKey {
        case id
        case createdAt = "created_at"
        case avatarUrl = "avatar_url"
        case name
    }
}
func printThread(file: String = #file, fuction: String = #function, line: Int = #line) {
    print("\n THREAD: \(file)/\(fuction) [\(line)]: \(Thread.current) \n")
}
extension DateFormatter {
    /// ミリ秒付きのiso8601フォーマット e.g. 2019-08-22T09:30:15.000+0900
    static let iso8601Full: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
}
enum APIError: Error {
    case invalidUrl
    case invalidStatusCode(Int)
    case unknown(Error?)
    case decode(Error?)
}
extension APIError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .invalidUrl:
            return "Invalid URL"
        case .decode(let error):
            return "\(error?.localizedDescription ?? "")"
        case .invalidStatusCode(let code):
            return "ERROR Response code: \(code)"
        case .unknown(let error):
            if let nsError = error as NSError? {
                return "\(nsError.code) \(nsError.localizedDescription)"
            } else {
                return error?.localizedDescription ?? "ERROR"
            }
        }
    }
}

final class APIClient {
    enum APIConst {
        static let scheme = "https://"
        static let secret = ""
        static let path = ".mockapi.io/api/v1/"

        static func getPath() -> String {
            return scheme + secret + path
        }
        static func createURL(endpoint: String) -> URL? {
            return URL.init(string: getPath() + endpoint)
        }
    }

    func fetchAsync<T: Decodable>(endpoint: String) async throws -> T {
        printThread()
        return try await withCheckedThrowingContinuation { continuation in
            guard let url = APIConst.createURL(endpoint: endpoint) else {
                continuation.resume(throwing: APIError.invalidUrl)
                return
            }
            URLSession.shared.dataTask(with: url) { (data, response, error) in
                if let error = error {
                    continuation.resume(throwing: APIError.unknown(error))
                    return
                }
                guard let httpRes = response as? HTTPURLResponse else {
                    continuation.resume(throwing: APIError.unknown(nil))
                    return
                }
                guard let data = data, httpRes.statusCode == 200 else {
                    continuation.resume(throwing: APIError.invalidStatusCode(httpRes.statusCode))
                    return
                }
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .formatted(.iso8601Full)
                do {
                    let result = try decoder.decode(T.self, from: data)
                    continuation.resume(returning: result)
                } catch let decodeError {
                    continuation.resume(throwing: APIError.decode(decodeError))
                }
            }.resume()
        }
    }

    func fetchDispatch<T: Decodable>(_ type: T.Type, completion: @escaping (Result<T, APIError>) -> Void) {
        printThread()
        guard let url = APIConst.createURL(endpoint: "users") else {
            return completion(.failure(.invalidUrl))
        }
        DispatchQueue.global().async {
            URLSession.shared.dataTask(with: url) { (data, response, error) in
                printThread()
                if let error = error {
                    completion(.failure(.unknown(error as NSError)))
                    return
                }
                guard let httpRes = response as? HTTPURLResponse else {
                    completion(.failure(.unknown(nil)))
                    return
                }
                guard let data = data, httpRes.statusCode == 200 else {
                    completion(.failure(.invalidStatusCode(httpRes.statusCode)))
                    return
                }
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .formatted(.iso8601Full)
                do {
                    let result = try decoder.decode(type, from: data)
                    completion(.success(result))
                } catch let decodeError {
                    completion(.failure(.decode(decodeError)))
                }
            }.resume()
        }
    }
    func fetchTask<T: Decodable>(endpoint: String, priority: Task.Priority = .default) -> Task.Handle<T> {
        return Task.runDetached(priority: priority) {
            return try await self.fetchAsync(endpoint: endpoint)
        }
    }
    func fetchTaskDeadline(endpoint: String) async throws -> Int {
        await Task.withDeadline(in: Task._TimeInterval.milliseconds(300)) {
            sleep(1)
            return 1
        }
    }
    func fetchTaskCancellation() async -> Int {
        return try! await Task.withCancellationHandler {
            print("cancle")
        } operation: {
            return 1
        }
    }
}

class UserAPI {
    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    func fetchUserTask() -> Task.Handle<[User]> {
        return client.fetchTask(endpoint: "users")
    }
    // not implement
    func fetchWithDeadLine() async throws -> Int {
        return try await client.fetchTaskDeadline(endpoint: "users")
    }
    // not implement
    func fetchWithCancel() async throws -> Int {
        return await client.fetchTaskCancellation()
    }

    func fetchUsers() async throws -> [User] {
        // キャンセルしてたら`Task.CancellationError`をthrowする
        try await Task.checkCancellation()
        return try await client.fetchAsync(endpoint: "users")
    }

    func fetchUser(id: String) async throws -> User {
        try await Task.checkCancellation()
        return try await client.fetchAsync(endpoint: "users/\(id)")
    }

    func fetchUsersDispatch(onSuccess: @escaping ([User]) -> Void, onFailure: @escaping (Error) -> Void) {
        printThread()
        client.fetchDispatch([User].self) { result in
            printThread()
            switch result {
            case let .success(result):
                onSuccess(result)
            case let .failure(error):
                onFailure(error)
            }
        }
    }
}
