//
//  LoginViewModel.swift
//  iES
//
//  Created by Никита Пивоваров on 01.10.2024.
//

import Foundation

class LoginViewModel: ObservableObject {
    
    enum LoginInputErrors: String, Error {
        case invalidEmail = "Invalid email format"
        case invalidPassword = "Password must be at least 8 characters, contain an uppercase letter, a number, and a special character"
    }
    
    enum AuthError: Error, Equatable {
        case error(description: String)
    }
    
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var isSecure: Bool = true
    @Published var isButtonsDisabled: Bool = true
    @Published var showAuthError: Bool = false
    @Published var errorMessage: LoginInputErrors? = nil
    @Published var authErrorMessage: AuthError? = nil
    
    private func isValidEmail(_ email: String) throws {
        let emailRegex = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        if  !emailPredicate.evaluate(with: email) {
            throw LoginInputErrors.invalidEmail
        }
    }
    
    private func isValidPassword(_ password: String) throws {
        // At least 8 characters, one uppercase, one number, and one special character
        let passwordRegex = "^(?=.*[A-Z])(?=.*[0-9])(?=.*[!@#$&*]).{8,}$"
        let passwordPredicate = NSPredicate(format: "SELF MATCHES %@", passwordRegex)
        if !passwordPredicate.evaluate(with: password) {
            throw LoginInputErrors.invalidPassword
        }
    }
    
    private func checkInputs() throws {
        try isValidEmail(email)
        try isValidPassword(password)
    }
    
    public func handleInput() {
        do {
            try checkInputs()
            isButtonsDisabled = false
            errorMessage = nil
        } catch let error {
            isButtonsDisabled = true
            errorMessage = error as? LoginInputErrors
        }
    }
    
    public func signIn() {
        authErrorMessage = nil
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            do {
                try checkInputs()
                UserService.signIn(with: email, password: password) { [weak self] result in
                    guard let self = self else { return }
                    switch result {
                    case .success(let success):
                        UserService.saveUser(user: success)
                        print("Success")
                    case .failure(let failure):
                        authErrorMessage = .error(description: failure.localizedDescription)
                    }
                }
            } catch let error {
                errorMessage = error as? LoginInputErrors
            }
        }
    }
    
    public func signUp() {
        authErrorMessage = nil
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            do {
                try checkInputs()
                UserService.signUp(with: email, password: password) { [weak self] result in
                    guard let self = self else { return }
                    switch result {
                    case .success(let success):
                        UserService.saveUser(user: success)
                        print("Success")
                    case .failure(let failure):
                        authErrorMessage = .error(description: failure.localizedDescription)
                    }
                }
            } catch let error {
                errorMessage = error as? LoginInputErrors
            }
        }
    }
}
