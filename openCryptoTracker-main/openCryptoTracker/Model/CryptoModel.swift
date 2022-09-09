//
//  CryptoModel.swift
//  openCryptoTracker
//
//  Created by Deepankar Gupta on 07/09/22.
//

import Foundation

struct CryptoModel {
    let currentPrice: Double
    let cryptoName: String
    let dailyPriceChange: Double
    let aTH: Double
    let imageURL: String
    let cryptoSymbol: String
    let id: String
    let marketCapRank: Int
    
    var valueIsUp: Bool {
        if dailyPriceChange < 0{
            return false
        } else {
            return true
        }
    }
}
