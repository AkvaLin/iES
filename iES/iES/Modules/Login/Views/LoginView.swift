//
//  LoginView.swift
//  iES
//
//  Created by Никита Пивоваров on 18.10.2024.
//

import SwiftUI

struct LoginView: View {
    @Environment(\.colorScheme) private var colorScheme
    @StateObject var viewModel = LoginViewModel()
    
    var body: some View {
        ZStack {
            if colorScheme == .dark {
                Rectangle()
                    .fill(.black.gradient)
                    .ignoresSafeArea()
            } else {
                Rectangle()
                    .fill(.white.gradient)
                    .ignoresSafeArea()
            }
            ScrollView {
                VStack(alignment: .leading) {
                    title
                    textFields
                    Spacer()
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage.rawValue)
                            .foregroundColor(.red)
                            .font(.callout)
                    }
                    if viewModel.showAuthError {
                        if let authErrorMessage = viewModel.authErrorMessage {
                            if case LoginViewModel.AuthError.error(let error) = authErrorMessage {
                                Text(error)
                                    .foregroundColor(.red)
                                    .font(.callout)
                            }
                        }
                    }
                    Spacer()
                    signInButton
                    signUpButton
                }
                .padding()
                .frame(maxWidth: 400)
                .onChange(of: viewModel.email) {
                    withAnimation {
                        viewModel.handleInput()
                        viewModel.showAuthError = false
                    }
                }
                .onChange(of: viewModel.password) {
                    withAnimation {
                        viewModel.handleInput()
                        viewModel.showAuthError = false
                    }
                }
                .onChange(of: viewModel.authErrorMessage) {
                    withAnimation {
                        if viewModel.authErrorMessage != nil {
                            viewModel.showAuthError = true
                        } else {
                            viewModel.showAuthError = false
                        }
                    }
                }
            }
            .scrollBounceBehavior(.basedOnSize)
        }
    }
    
    private var title: some View {
        Text("Sign In")
            .font(.largeTitle)
            .bold()
            .padding(.top, 20)
    }
    
    private var loginTextField: some View {
        TextField("Email", text: $viewModel.email)
            .keyboardType(.emailAddress)
            .autocapitalization(.none)
            .padding(.bottom, 10)
    }
    
    private var textFields: some View {
        Group {
            loginTextField
            
            if viewModel.isSecure {
                SecureField("Password", text: $viewModel.password)
            } else {
                TextField("Password", text: $viewModel.password)
            }
        }
        .textFieldStyle(.roundedBorder)
    }
    
    private var signInButton: some View {
        Button(action: {
            viewModel.signIn()
        }) {
            Text("Sign In")
                .bold()
                .frame(maxWidth: .infinity)
                .cornerRadius(25)
                .padding(10)
        }
        .buttonStyle(.borderedProminent)
        .disabled(viewModel.isButtonsDisabled)
    }
    
    private var signUpButton: some View {
        Button(action: {
            viewModel.signUp()
        }) {
            Text("Sign Up")
                .frame(maxWidth: .infinity)
                .cornerRadius(25)
                .padding(10)
        }
        .disabled(viewModel.isButtonsDisabled)
        .padding(.bottom, 20)
    }
}

#if DEBUG
struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            LoginView()
                .previewDevice(PreviewDevice(rawValue: "iPhone 15 Pro"))
                .previewDisplayName("iPhone")
            LoginView()
                .previewDevice(PreviewDevice(rawValue: "iPad Pro 13-inch (M4)"))
                .previewDisplayName("iPad")
        }
        .previewInterfaceOrientation(.landscapeLeft)
    }
}
#endif
