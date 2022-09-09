//
//  CryptoViewController.swift
//  openCryptoTracker
//
//  Created by Deepankar Gupta on 07/09/22.
//

import UIKit
import Charts
import TinyConstraints

class CryptoViewController: UIViewController {
    
    @IBOutlet weak var cryptoImage: UIImageView!
    @IBOutlet weak var cryptoLabel: UILabel!
    @IBOutlet weak var cryptoValue: UILabel!
    @IBOutlet weak var cryptoUpDown: UIImageView!
    @IBOutlet weak var cryptoDailyDifference: UILabel!
    @IBOutlet weak var cryptoATH: UILabel!
    @IBOutlet weak var cryptoUISegmentedControl: UISegmentedControl!
    @IBOutlet weak var chartView: UIView!
    // TableView
    @IBOutlet weak var cryptoTableView: UITableView!
    
    var cryptoBackend = CryptoBackend()
    var crypto: [String : CryptoModel]? = [:]
    
    // Default Starting Values
    var currentCryptoCurrencyName = "Bitcoin"
    var currentCryptoCurrencyID = "bitcoin"
    var currentVSCurrency = "usd"
    var lastCurrencyIndex = 0
    var vsCurrencyDictionary = ["usd": "$", "eur": "€", "gbp": "£", "pln": "PLN", "unknown currency": "error"]
    var cryptoArray = ["Bitcoin", "Ethereum", "Litecoin", "Monero", "Chainlink", "Tether", "Dash", "Aave", "Ripple", "Dogecoin"]
    
    lazy var lineChartView: LineChartView = {
        let chartView = LineChartView()
        return chartView
    }()
    
    // Create UserDefaults
    let defaults = UserDefaults.standard
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        ChartViewConstraints
        chartView.addSubview(lineChartView)
        lineChartView.width(to: chartView)
        lineChartView.bottom(to: chartView)
        lineChartView.top(to: chartView)
//        ChartViewCustomization
        lineChartView.leftAxis.drawLabelsEnabled = false
        lineChartView.rightAxis.drawLabelsEnabled = false
        lineChartView.xAxis.drawLabelsEnabled = false
        lineChartView.doubleTapToZoomEnabled = false
        lineChartView.pinchZoomEnabled = false
        
        cryptoValue.adjustsFontSizeToFitWidth = true
        cryptoDailyDifference.adjustsFontSizeToFitWidth = true
        
        cryptoBackend.delegate = self
        
        lineChartView.delegate = self
        
        cryptoTableView.dataSource = self
        cryptoTableView.delegate = self
        
        // Open defaults if they exist
        if let lastVSCurrencyIndex = defaults.value(forKey: "lastVSCurrencyIndex") as? Int {
            lastCurrencyIndex = lastVSCurrencyIndex
            currentVSCurrency = (cryptoUISegmentedControl.titleForSegment(at: lastCurrencyIndex)!).lowercased()
            cryptoUISegmentedControl.selectedSegmentIndex = lastCurrencyIndex
        }
//        Download values from API and refresh UI
        cryptoBackend.getURLValue(vsCurrency: currentVSCurrency)
        cryptoBackend.getURLValueCharts(vsCurrency: currentVSCurrency, cryptoCurrency: currentCryptoCurrencyID)
    }
    
    @IBAction func refreshButtonPressed(_ sender: UIButton) {
//        Download data
        cryptoBackend.getURLValue(vsCurrency: currentVSCurrency)
    }
    
    func refreshCryptoUI() {
        
//        Refresh values for Labels and Charts
        
        cryptoBackend.getURLValueCharts(vsCurrency: currentVSCurrency, cryptoCurrency: currentCryptoCurrencyID)
        
//        Refresh UI
        let group = DispatchGroup()
        group.enter()
        DispatchQueue.main.async {
            
//            Refresh TableView
            let indexPath = self.cryptoTableView.indexPathForSelectedRow ?? IndexPath(row: 0, section: 0)
            self.cryptoTableView.scrollToRow(at: indexPath, at: .middle, animated: true)
            self.cryptoTableView.reloadData()
            
//            Highlight empty value on the chartView
            self.lineChartView.highlightValues([Highlight]())
            
            if self.crypto != nil {
                if let currentCrypto = self.crypto![self.currentCryptoCurrencyName] {
                    
                    self.cryptoLabel.text = "\(currentCrypto.cryptoName) (\(currentCrypto.cryptoSymbol))"
                        // If imageURL != nil download the image and display it
                    if let imageURL = URL(string: (currentCrypto.imageURL)) {
                        self.cryptoImage.load(imageURL)
                    }
                    self.cryptoValue.text = "\(currentCrypto.currentPrice) \(self.vsCurrencyDictionary[self.currentVSCurrency] ?? "$")"
                    self.cryptoATH.text = "All Time High: \(currentCrypto.aTH) \(self.vsCurrencyDictionary[self.currentVSCurrency] ?? "$")"
                    let dailyPriceChangeString = "\(currentCrypto.dailyPriceChange)"
                    if currentCrypto.valueIsUp { // if cryptocurrency is up
                            self.cryptoUpDown.image = UIImage(systemName: "arrow.up.circle.fill")
                            self.cryptoUpDown.tintColor = .green
                            self.cryptoDailyDifference.text = dailyPriceChangeString
                        }
                        else { // if cryptocurrency is down
                            self.cryptoUpDown.image = UIImage(systemName: "arrow.down.circle.fill")
                            self.cryptoUpDown.tintColor = .red
                            self.cryptoDailyDifference.text = dailyPriceChangeString
                        }
                    group.leave()
                }
            } else {
                self.cryptoBackend.getURLValue(vsCurrency: self.currentVSCurrency)
            }
        }
        group.notify(queue: .main) {
            self.dismiss(animated: false) {}
        }
    }
    
}

//MARK: - UITableView

extension CryptoViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.cryptoArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
//        Create TableViewCell with the choosen style
        let cell = UITableViewCell(style: UITableViewCell.CellStyle.value1, reuseIdentifier: "cryptoNameCell")
        
//        Set TableViewCell.text for CryptoCurrency Name and Symbol
        cell.textLabel?.text = "\(self.crypto![self.cryptoArray[indexPath[1]]]?.marketCapRank ?? 404). \(self.cryptoArray[indexPath[1]]) (\(self.crypto![self.cryptoArray[indexPath[1]]]?.cryptoSymbol ?? "404"))"
        cell.detailTextLabel?.text = "\(self.crypto![self.cryptoArray[indexPath[1]]]?.currentPrice ?? 0) \(self.vsCurrencyDictionary[self.currentVSCurrency] ?? "$")"
        cell.backgroundColor = UIColor.clear
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        Update UI when clicking on TableViewCell
        currentCryptoCurrencyName = self.cryptoArray[indexPath.row]
        currentCryptoCurrencyID = self.crypto![self.cryptoArray[indexPath.row]]!.id
        refreshCryptoUI()
    }
}

//MARK: - UISegmentedControl

extension CryptoViewController {
    
    @IBAction func moneyCurrencyChanged(_ sender: UISegmentedControl) {
//        Change vsCurrency based on UISegmented Control
        switch sender.selectedSegmentIndex {
                case 0:
                    currentVSCurrency = "usd"
                case 1:
                    currentVSCurrency = "eur"
                case 2:
                    currentVSCurrency = "gbp"
                case 3:
                    currentVSCurrency = "pln"
                default:
                    currentVSCurrency = "unknown currency"
                }
        
//        Update defaults
        self.lastCurrencyIndex = sender.selectedSegmentIndex
        self.defaults.setValue(self.lastCurrencyIndex, forKey: "lastVSCurrencyIndex")
        
//        Download data for this vsCurrency
        cryptoBackend.getURLValue(vsCurrency: currentVSCurrency)
        
        // Update Charts
        cryptoBackend.getURLValueCharts(vsCurrency: currentVSCurrency, cryptoCurrency: currentCryptoCurrencyID)
    }
}

//MARK: - CryptoBackendDelegate

extension CryptoViewController: CryptoBackendDelegate, ChartViewDelegate {
    
//MARK: - Charts

    func didUpdateCharts(_ cryptoBackend: CryptoBackend, charts: [ChartsModel]) {
        DispatchQueue.main.async {
            
//            Create empty ChartDataEntry array
            var priceChartDataSet: [ChartDataEntry] = []
//            Fill the array with ChartData
            for dailyValue in charts {
                priceChartDataSet.append(ChartDataEntry(x: dailyValue.date, y: dailyValue.price))
            }
            let pricesSet = LineChartDataSet(entries: priceChartDataSet, label: "Monthly price for \(self.crypto![self.currentCryptoCurrencyName]?.cryptoSymbol ?? "404") in \(self.vsCurrencyDictionary[self.currentVSCurrency] ?? "$")")
            
//            Hide circles on each point
            pricesSet.drawCirclesEnabled = false
            
//            Hide values on each point
            pricesSet.drawValuesEnabled = false
            
            pricesSet.setColor(UIColor(named: "AccentColor")!)
            pricesSet.highlightColor = (UIColor(named: "AccentColor")!)
            
            let priceChartData = LineChartData(dataSet: pricesSet)
            self.lineChartView.data = priceChartData
            self.lineChartView.fitScreen()
        }
    }
    
    func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {
        self.cryptoValue.text = "\(String(format: "%.3f", highlight.y)) \(self.vsCurrencyDictionary[self.currentVSCurrency] ?? "$")"
    }
    
    func updateCryptoLabel(_ highlight: Double) {
        self.cryptoLabel.text = String(highlight)
    }
    
//MARK: - UpdateCryptoCurrencyValues
    
    func didUpdateCrypto(_ cryptoBackend: CryptoBackend, crypto: [String : CryptoModel]?) {
        DispatchQueue.main.async {
            self.performSegue(withIdentifier: "loadingSegue", sender: nil)
            self.crypto = crypto
            
//            Create cryptoArray and cryptoArrayMarketCap
            self.cryptoArray = []
            var cryptoArrayMarketCap: [String] = []
            
//            Fill cryptoArrayMarketCap with CryptoCurrency Ranks
            for cryptoCurrencyData in crypto! {
                cryptoArrayMarketCap.append("\(cryptoCurrencyData.value.marketCapRank).\(cryptoCurrencyData.value.cryptoName)")
            }
//            Sort cryptoArrayMarketCap by asceding numbers
            cryptoArrayMarketCap.sort(by: {$0.localizedStandardCompare($1) == .orderedAscending})
            
//            Delete marketCapRank from cryptoArray
            for cryptoNameRanked in cryptoArrayMarketCap {
                if let index = (cryptoNameRanked.range(of: ".")?.upperBound){
//                    Delete everything before & including the dot
                    let justCryptoName = String(cryptoNameRanked.suffix(from: index))
                    self.cryptoArray.append("\(justCryptoName)")
                }
            }
            self.refreshCryptoUI()
        }
    }
    
    func didFailWithError(error: Error) {
        print(error)
    }
}

//MARK: - LoadImageFromInternetExtension

extension UIImageView {
    func load(_ url: URL) {
        DispatchQueue.global().async { [weak self] in
            if let data = try? Data(contentsOf: url) {
                if let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self?.image = image
                    }
                }
            }
        }
    }
}
