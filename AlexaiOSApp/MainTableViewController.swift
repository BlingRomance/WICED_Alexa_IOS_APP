//
//  MainTableViewController.swift
//  Alexa iOS App
//
//  Created by God on 2017/6/29.
//  Copyright © 2017 Bling. All rights reserved.
//

import UIKit
import FoldingCell
import Toast_Swift

var tableID: [String] = []
var tableName: [String] = []
var finalArray = Array<Array<String>>()
var redStatus: Bool = false
var blueStatus: Bool = false
var greenStatus: Bool = false

class MainTableViewController: UITableViewController, UITextFieldDelegate {
    let kCloseCellHeight: CGFloat = 105
    let kOpenCellHeight: CGFloat = 400
    var cellHeights: [CGFloat] = []
    
    var countdownTimer: Timer?
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableID.removeAll()
        tableName.removeAll()
        finalArray.removeAll()
        
        if let mydb = appDelegate.db {
            let statement = mydb.select("'\(LoginWithAmazon.sharedInstance.loginWithAmazonUserID!)'", cond: nil, order: nil)
            
            while sqlite3_step(statement) == SQLITE_ROW {
                tableID.append(String(cString: sqlite3_column_text(statement, 1)))
                tableName.append(String(cString: sqlite3_column_text(statement, 2)))
                
                appDelegate.mqtt?.publish("\(appDelegate.subChannel!)/\(String(cString: sqlite3_column_text(statement, 1)))", withString: "{\"state\":{\"desired\":{\"status\":2, \"name\":\"\", \"led\":\"\", \"color\":\"\"}}}", qos: .qos1, retained: false, dup: false)
                finalArray.append([String(cString: sqlite3_column_text(statement, 1)), "0", "0", "0", "0"])
            }
            sqlite3_finalize(statement)
        }

        cellHeights = Array(repeating: kCloseCellHeight, count: tableID.count)
        tableView.estimatedRowHeight = kCloseCellHeight
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.backgroundColor = UIColor(patternImage: #imageLiteral(resourceName: "Background"))
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if string == " " {
            self.view.makeToast("Can't enter space", duration: 0.3, position: .center)
            return false
        }
        
        return true
    }
}

//MARK - TableView
extension MainTableViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableID.count
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        guard case let cell as DemoCell = cell else {
            return
        }
        
        cell.backgroundColor = .clear
        
        if cellHeights[indexPath.row] == kCloseCellHeight {
            cell.selectedAnimation(false, animated: false, completion: nil)
        } else {
            cell.selectedAnimation(true, animated: false, completion: nil)
        }
        
        cell.closeNumber = indexPath.row
        cell.deviceID = tableID[indexPath.row]
        cell.deviceName = tableName[indexPath.row]
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FoldingCell", for: indexPath) as! FoldingCell
        let durations: [TimeInterval] = [0.26, 0.2, 0.2]
        cell.durationsForExpandedState = durations
        cell.durationsForCollapsedState = durations
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return cellHeights[indexPath.row]
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        UIApplication.shared.keyWindow?.endEditing(true)
        
        if finalArray[indexPath.row][1] == "2" {
            redStatus = false
            blueStatus = false
            greenStatus = false
            
            if finalArray[indexPath.row][2] == "1" {
                redStatus = true
            }
            if finalArray[indexPath.row][3] == "1" {
                blueStatus = true
            }
            if finalArray[indexPath.row][4] == "1" {
                greenStatus = true
            }

            let cell = tableView.cellForRow(at: indexPath) as! FoldingCell
            
            if cell.isAnimating() {
                return
            }
            
            var duration = 0.0
            let cellIsCollapsed = cellHeights[indexPath.row] == kCloseCellHeight
            if cellIsCollapsed {
                cellHeights[indexPath.row] = kOpenCellHeight
                cell.selectedAnimation(true, animated: true, completion: nil)
                duration = 0.5
            } else {
                cellHeights[indexPath.row] = kCloseCellHeight
                cell.selectedAnimation(false, animated: true, completion: nil)
                duration = 0.8
            }
            
            UIView.animate(withDuration: duration, delay: 0, options: .curveEaseOut, animations: { () -> Void in
                tableView.beginUpdates()
                tableView.endUpdates()
            }, completion: nil)
        } else {
            self.view.makeToast("Connecting...", duration: 1.0, position: .bottom)
        }
        
    }
}


