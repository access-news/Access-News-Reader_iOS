//
//  ListRecordingsTVC.swift
//  Access News
//
//  Created by Attila Gulyas on 9/21/18.
//  Copyright © 2018 Society for the Blind. All rights reserved.
//

import UIKit

class ListRecordingsTVC: UITableViewController {

    var recordings: [URL]!

    var recordingsOrderedByDate: [URL] {
        get {

            func dateString(_ date: Date) -> String {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyyMMddHHmmss"

                return dateFormatter.string(from: date)
            }

            func compareValue(_ url: URL) -> Int {
                func getURLDateTime(_ url: URL) -> Date {
                    let urlAttrs = try! FileManager.default.attributesOfItem(atPath: url.path)
                    return urlAttrs[FileAttributeKey.creationDate] as! Date
                }

                // I miss built in function composition.
                return Int(dateString(getURLDateTime(url)))!
            }

            let documentURLs = FileManager.default.urls(
                for: .documentDirectory,
                in:  .userDomainMask
            ).first!

            let fileURLs = try? FileManager.default.contentsOfDirectory(at: documentURLs, includingPropertiesForKeys: nil, options: [])
            let fileURLsNeverNil = fileURLs ?? []

            return fileURLsNeverNil.sorted { f,g in
                let fi = compareValue(f)
                let gi = compareValue(g)

                return fi > gi
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.recordings = self.recordingsOrderedByDate

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return self.recordingsOrderedByDate.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "recording", for: indexPath)

        cell.textLabel?.text = self.recordingsOrderedByDate[indexPath.row].lastPathComponent
        return cell
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {

            let url = self.recordingsOrderedByDate[indexPath.row]
            try? FileManager.default.removeItem(at: url)

            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .right)
        }
        /* else if editingStyle == .insert {
         // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
         } */
    }

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
