//
//  YandexDiskService.swift
//  iES
//
//  Created by Никита Пивоваров on 05.04.2025.
//

import Foundation

enum YandexDiskService {
    static func save(model: Data, token: String, fileName: String) async {
        var request = URLRequest(url: URL(string: "https://cloud-api.yandex.net/v1/disk/resources/upload?path=\(fileName)&overwrite=true")!)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = ["Authorization": "OAuth \(token)"]
        
        do {
            let (pathData, _) = try await URLSession.shared.data(for: request)

            guard let href = try? JSONDecoder().decode(PathResponse.self, from: pathData).href else { return }
            
            var request = URLRequest(url: URL(string: href)!)
            request.httpMethod = "PUT"
            request.httpBody = model
            
            _ = try await URLSession.shared.data(for: request)
        } catch {
            print(error)
        }
    }
    
    static func getFile(token: String, fileName: String) async -> Data? {
        var request = URLRequest(url: URL(string: "https://cloud-api.yandex.net/v1/disk/resources/download?path=\(fileName)")!)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = ["Authorization": "OAuth \(token)"]
        
        do {
            let (pathData, _) = try await URLSession.shared.data(for: request)
            
            guard let href = try? JSONDecoder().decode(PathResponse.self, from: pathData).href else { return nil }
            
            var request = URLRequest(url: URL(string: href)!)
            request.httpMethod = "GET"
            
            let (fileData, fileResponse) = try await URLSession.shared.data(for: request)
            
            if (fileResponse as? HTTPURLResponse)?.statusCode == 200 {
                return fileData
            } else {
                 return nil
            }
        } catch {
            print(error)
            return nil
        }
    }

    private struct PathResponse: Decodable {
        let href: String
    }
}
