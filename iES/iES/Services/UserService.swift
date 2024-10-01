//
//  UserService.swift
//  iES
//
//  Created by Никита Пивоваров on 01.10.2024.
//

struct UserService {
    
    struct User { }
    
    static func signIn() { }
    
    static func signUp() { }
    
    static func signOut() { }
    
    static func getUser() -> User {
        return User()
    }
    
    static func changeUserInfo(info userInfo: User) { }
}
