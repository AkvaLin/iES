//
//  ProfileViewModel.swift
//  iES
//
//  Created by Никита Пивоваров on 01.10.2024.
//

import Foundation

class ProfileViewModel: ObservableObject {
    
    func signOut() {
        UserService.signOut()
    }
    
    func getUserInfo() {
        print(UserService.getUser())
    }
    
    func changeUserInfo() {
        UserService.changeUserInfo(info: .init(uid: "", name: "", email: ""))
    }
}
