//
//  User.swift
//  iES
//
//  Created by Никита Пивоваров on 18.10.2024.
//

import Foundation
import FirebaseAuth

public class UserModel: Identifiable, Codable {
    public let uid: String
    public let name: String?
    public let email: String?
    
    public init(uid: String, name: String, email: String) {
        self.uid = uid
        self.name = name
        self.email = email
    }
    
    public init(from user: User) {
        self.uid = user.uid
        self.name = user.displayName
        self.email = user.email
    }
}
