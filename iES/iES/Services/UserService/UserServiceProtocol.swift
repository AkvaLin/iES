//
//  FirebaseService.swift
//  iES
//
//  Created by Никита Пивоваров on 18.10.2024.
//


public protocol UserServiceProtocol {
    static func signIn(with email: String, password: String, completion: @escaping (Result<UserModel, Error>) -> Void)
    static func signUp(with email: String, password: String, completion: @escaping (Result<UserModel, Error>) -> Void)
}
