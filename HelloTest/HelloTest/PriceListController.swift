//
//  PriceListController.swift
//  HelloTest
//
//  Created by Hafiz Nordin on 19/02/2019.
//  Copyright © 2019 Hafiz Nordin. All rights reserved.
//

import UIKit
import Alamofire

class PriceListController: UITableViewController {
    var emailAddress: String?
    var priceData: [[Int:String]] = [[:]]
    let refreshController = UIRefreshControl()
    
    // MARK: - Actions
    @IBAction func refreshButtonTapped(_ sender: Any) {
        fetchPriceData()
    }
    
    @IBAction func signOutButtonTapped(_ sender: Any) {
        //TODO: Set plist hasSignedUp flag to false, unwind to sign up screen
        performSegue(withIdentifier: "unwindFromPriceList", sender: self)
    }
    
    @objc private func refreshPriceData(_ sender: Any) {
        fetchPriceData()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Set email address
        if emailAddress == nil {
            //TODO: Get email address from plist
        }
        self.title = emailAddress
        
        //Setup refresh control
        refreshController.tintColor = UIColor(red: 230/255, green: 206/255, blue: 7/255, alpha: 1)
        refreshController.addTarget(self, action: #selector(refreshPriceData(_:)), for: .valueChanged)
        tableView.refreshControl = refreshController
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        //Add notification center observer when app will enter foreground
        NotificationCenter.default.addObserver(self, selector: #selector(appWillEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        
        fetchPriceData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        //Remove notification center observer
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func appWillEnterForeground() {
        fetchPriceData()
    }
    
    func fetchPriceData() {
        let endpoint: String = "https://cws.hellogold.com/api/v2/spot_price.json"
        
        Alamofire.request(endpoint).responseJSON { response in
            guard response.result.error == nil else {
                //Error in getting the data
                print("Error calling GET on spot_price.json")
                print(response.result.error!)
                return
            }
            
            if let json = response.result.value as? [String: Any], let result = json["result"] as? String, result == "ok" {
                if let data = json["data"] as? [String: Any], let iso8601Timestamp = data["timestamp"] as? String, let price = data["spot_price"] as? Double {
                    let milliTimestamp = self.getTotalMillisFromISO8601String(iso8601Timestamp)
                    let roundedPrice = String(format: "%.2f", price)
                    
                    //Save price data point to array
                    self.priceData.insert([milliTimestamp : roundedPrice], at: 0)
                    
                    //Reload table view with new data point
                    self.tableView.reloadData()
                    
                    //End refresh
                    if self.refreshController.isRefreshing {
                        self.refreshController.endRefreshing()
                    }
                } else {
                    //End refresh
                    if self.refreshController.isRefreshing {
                        self.refreshController.endRefreshing()
                    }
                }
            } else {
                //End refresh
                if self.refreshController.isRefreshing {
                    self.refreshController.endRefreshing()
                }
            }
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return priceData.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "priceCell", for: indexPath)

        // Configure the cell...
        if let date = priceData[indexPath.row].keys.first, let price = priceData[indexPath.row].values.first {
            cell.textLabel?.text = getDisplayTimestampFormatString(timestamp: date)
            cell.detailTextLabel?.text = "RM " + price
        }

        return cell
    }

    // MARK: - Date and time utility functions.
    
    /// Get current timestamp in milliseconds.
    ///
    /// - Returns: Total milliseconds.
    func getCurrentTimestamp() -> Int {
        return (Int)(Date().timeIntervalSince1970 * 1000)
    }
    
    /// Get date from timestamp
    ///
    /// - Parameter timestamp: Timestamp in milliseconds
    /// - Returns: Date object
    func getDateFromTotalMillis(timestamp: Int) -> Date {
        return Date(timeIntervalSince1970: Double(timestamp / 1000))
    }
    
    /// Get total milliseconds from ISO8601 date time string.
    ///
    /// - Parameter iso8601String: ISO8601 formatted date time string.
    /// - Returns: Total milliseconds.
    func getTotalMillisFromISO8601String(_ iso8601String: String?) -> Int {
        guard iso8601String != nil else {
            return 0
        }
        let date = getDateFromISO8601String(iso8601String!)
        guard date != nil else {
            return 0
        }
        return (Int)(date!.timeIntervalSince1970 * 1000)
    }
    
    /// Get Date object from ISO8601 formatted date time string.
    ///
    /// - Parameter iso8601String: ISO8601 formatted date time string.
    /// - Returns: Date object.
    func getDateFromISO8601String(_ iso8601String: String) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone(abbreviation: "GMT")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        
        return dateFormatter.date(from: iso8601String)
    }
    
    /// Get display timestamp format string.
    ///
    /// If message are from today, show time (Eg. 10:15 AM).
    /// If message are from yesterday, show Yesterday with time (Eg. Yesterday, 11:15 AM).
    /// If within 7 days - show Sun, Mon, Tue, Wed, Thu, Fri, Sat with time (Eg. Mon, 10:15 AM).
    /// If within same year, show Jun 28, 8:00 PM.
    /// If last year, show 28 Jun 2017, 8:00 PM.
    ///
    /// - Parameter timestamp: Timestamp in milliseconds.
    /// - Returns: New timestamp format string.
    func getDisplayTimestampFormatString(timestamp: Int) -> String {
        guard timestamp > 0 else {
            return ""
        }
        
        let calendar = Calendar.current
        let toCompareDate = Date(timeIntervalSince1970: Double(timestamp / 1000))
        
        // Replace the hour (time) of both dates with 00:00
        let fromDate = calendar.startOfDay(for: toCompareDate)
        let toDate = calendar.startOfDay(for: Date())
        
        //Get days
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone.autoupdatingCurrent
        dateFormatter.locale = Locale.current
        let components = (calendar as NSCalendar).components(NSCalendar.Unit.day, from: fromDate, to: toDate, options: [])
        
        switch components.day! {
        case 0:
            dateFormatter.dateFormat = "h:mm a"
            return dateFormatter.string(from: toCompareDate)
        case 1:
            dateFormatter.dateFormat = "h:mm a"
            return "\(NSLocalizedString("LBL_YESTERDAY", comment: "")), \(dateFormatter.string(from: toCompareDate))"
        case 2:
            dateFormatter.dateFormat = "EEE, h:mm a"
            return dateFormatter.string(from: toCompareDate)
        case 3:
            dateFormatter.dateFormat = "EEE, h:mm a"
            return dateFormatter.string(from: toCompareDate)
        case 4:
            dateFormatter.dateFormat = "EEE, h:mm a"
            return dateFormatter.string(from: toCompareDate)
        case 5:
            dateFormatter.dateFormat = "EEE, h:mm a"
            return dateFormatter.string(from: toCompareDate)
        case 6:
            dateFormatter.dateFormat = "EEE, h:mm a"
            return dateFormatter.string(from: toCompareDate)
        default:
            if isDateInSameYear(toCompareDate) {
                dateFormatter.dateFormat = "MMM d, h:mm a"
                return dateFormatter.string(from: toCompareDate)
            } else {
                dateFormatter.dateFormat = "d MMM yyyy, h:mm a"
                return dateFormatter.string(from: toCompareDate)
            }
        }
    }
    
    /// Check if date is within the same year as current date.
    ///
    /// - Parameter date: Date object
    /// - Returns: True if date is within the same year as current date. False otherwise.
    func isDateInSameYear(_ date: Date) -> Bool {
        return Calendar.current.isDate(getDateFromTotalMillis(timestamp: getCurrentTimestamp()), equalTo: date, toGranularity: .year)
    }
}
