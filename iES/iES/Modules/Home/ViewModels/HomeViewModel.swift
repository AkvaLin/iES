//
//  HomeViewModel.swift
//  iES
//
//  Created by Никита Пивоваров on 01.10.2024.
//

import Foundation

class HomeViewModel: ObservableObject {
    
    func getResentPlayedGames() {
        print(GamesService.getGames())
    }
    func getUserData() {
        print(UserService.getUser())
    }
}
