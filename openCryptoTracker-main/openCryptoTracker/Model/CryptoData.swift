//
//  CryptoData.swift
//  openCryptoTracker
//
//  Created by Deepankar Gupta on 07/09/22.
//

import Foundation

struct CryptoData: Decodable {
    let current_price: Double
    let price_change_24h: Double
    let name: String
    let ath: Double
    let image: String
    let symbol: String
    let id: String
    let market_cap_rank: Int
}
