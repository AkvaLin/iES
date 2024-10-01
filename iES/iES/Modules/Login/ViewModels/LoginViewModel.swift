//
//  LoginViewModel.swift
//  iES
//
//  Created by Никита Пивоваров on 01.10.2024.
//

import Foundation

class LoginViewModel: ObservableObject {
    
    func signIn() {
        UserService.signIn()
    }
    
    func signUp() {
        UserService.signUp()
    }
}
