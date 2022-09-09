//
//  CryptoBackend.swift
//  openCryptoTracker
//
//  Created by Deepankar Gupta on 07/09/22.
//

import Foundation

protocol CryptoBackendDelegate {
    func didUpdateCrypto(_ cryptoBackend: CryptoBackend, crypto: [String : CryptoModel]?)
    func didUpdateCharts(_ cryptoBackend: CryptoBackend, charts: [ChartsModel])
    func didFailWithError(error: Error)
}

struct CryptoBackend {
    
    var baseAPIURL = "https://api.coingecko.com/api/v3/"
    var delegate: CryptoBackendDelegate?
    
    func getURLValue(vsCurrency: String) {
        let apiURL = "\(baseAPIURL)coins/markets?vs_currency=\(vsCurrency)&order=market_cap_desc&per_page=100&page=1"
        getRequest(apiURL)
    }
    func getRequest(_ urlString: String) {
        // 1 Create a URL
        if let url = URL(string: urlString) {
            // 2 Create a URL Session
            let session = URLSession(configuration: .default)
            // 3 Give the session a task
            let task = session.dataTask(with: url) { (data, response, error) in
                if error != nil {
                    delegate?.didFailWithError(error: error!)
                    return
                }
                
                if let safeData = data {
                    if urlString.contains("market_chart") {
                        if let charts = parseJSONCharts(safeData) {
                            delegate?.didUpdateCharts(self, charts: charts)
                        }
                    } else {
                        if let crypto = parseJSON(safeData) {
                            delegate?.didUpdateCrypto(self, crypto: crypto)
                        }
                    }
                }
            }
            // 4 Start the task
            task.resume()
        }
    }
    func parseJSON(_ cryptoData: Data) -> [ String : CryptoModel]?{
        let decoder = JSONDecoder()
        do {
            let decodedData = try decoder.decode([CryptoData].self, from: cryptoData)
            var cryptoMarkets: [ String : CryptoModel] = [:]
            for data in decodedData {
                let name = data.name
                let priceChange = data.price_change_24h
                let currentPrice = data.current_price
                let aTH = data.ath
                let imageURL = data.image
                let symbol = data.symbol.uppercased()
                let id = data.id
                let marketCapRank = data.market_cap_rank
                let cryptoModel = CryptoModel(currentPrice: currentPrice, cryptoName: name, dailyPriceChange: priceChange, aTH: aTH, imageURL: imageURL, cryptoSymbol: symbol, id: id, marketCapRank: marketCapRank)
                cryptoMarkets[name] = cryptoModel
            }
            
            return cryptoMarkets
        } catch {
            delegate?.didFailWithError(error: error)
            return nil
        }
    }
    
    //MARK: - Charts
    
    func getURLValueCharts(vsCurrency: String, cryptoCurrency: String) {
        let apiURLChart = "\(baseAPIURL)coins/\(cryptoCurrency)/market_chart?vs_currency=\(vsCurrency)&days=\(30)&interval=daily"
        getRequest(apiURLChart)
    }
    func parseJSONCharts(_ chartsData: Data) -> [ChartsModel]?{
        let decoder = JSONDecoder()
        do {
            let decodedData = try decoder.decode(ChartsData.self, from: chartsData)
            var charts: [ChartsModel] = []
            for dailyValue in decodedData.prices {
                let date = dailyValue[0]
                let price = dailyValue[1]
                charts.append(ChartsModel(date: date, price: price))
            }
            return charts
        } catch {
            delegate?.didFailWithError(error: error)
            return nil
        }
    }
}
