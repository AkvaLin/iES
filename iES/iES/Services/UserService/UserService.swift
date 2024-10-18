//
//  UserService.swift
//  iES
//
//  Created by Никита Пивоваров on 01.10.2024.
//

import FirebaseAuth

struct UserService: UserServiceProtocol {
    
    static func signIn(with email: String,
                       password: String,
                       completion: @escaping (Result<UserModel, Error>) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { (result, error) in
            handleAuthResponse(result: result, error: error, completion: completion)
        }
    }
    
    static func signUp(with email: String,
                       password: String,
                       completion: @escaping (Result<UserModel, Error>) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { (result, error) in
            handleAuthResponse(result: result, error: error, completion: completion)
        }
    }
    
    static func signOut() {  }
    
    static func saveUser(user: UserModel) {
        let defaults = UserDefaults.standard
        
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(user) {
            let defaults = UserDefaults.standard
            defaults.set(encoded, forKey: "user")
        }
    }
    
    static func getUser() -> UserModel? {
        let defaults = UserDefaults.standard
        
        if let savedUser = defaults.object(forKey: "user") as? Data {
            let decoder = JSONDecoder()
            if let loadedMovie = try? decoder.decode(UserModel.self, from: savedUser) {
                return loadedMovie
            }
        }
        return nil
    }
    
    static func changeUserInfo(info userInfo: UserModel) { }
    
    private static func handleAuthResponse(result: AuthDataResult?,
                                       error: (any Error)?,
                                       completion: @escaping (Result<UserModel, Error>) -> Void) {
        if let error = error {
            completion(.failure(error))
        } else {
            guard let user = result?.user else {
                completion(.failure(FirebaseError.noUser))
                return
            }
            completion(.success(.init(from: user)))
        }
    }
}
