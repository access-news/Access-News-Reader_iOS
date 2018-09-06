//
//  SubmitTVC.swift
//  Access News
//
//  Created by Attila Gulyas on 7/13/18.
//  Copyright © 2018 Society for the Blind. All rights reserved.
//

import UIKit
import Firebase

class SubmitTVC: UITableViewController {

    @IBOutlet weak var selectedPublication: UILabel!

    let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]

    let storage = Storage.storage()

    var recordVC: RecordViewController!

    override func viewDidLoad() {
        super.viewDidLoad()

        self.recordVC =  self.navigationController?.viewControllers[1] as! RecordViewController
        /* Making the text always fit the label
           https://stackoverflow.com/questions/4865458/dynamically-changing-font-size-of-uilabel
        */
        self.selectedPublication.numberOfLines = 1
        self.selectedPublication.adjustsFontSizeToFitWidth = true
        // This is the default, but making it explicit
        self.selectedPublication.minimumScaleFactor = 0

        let doneButton = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(self.uploadRecording))
        self.navigationItem.rightBarButtonItem = doneButton

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    @objc func uploadRecording() {

        let recordingName =
            self.recordVC.articleURLToSubmit.pathComponents.last!

        let path =
            "recordings/\(self.selectedPublication.text!)/\(recordingName)"

        let recordingRef =
            self.storage.reference().child(path)

        let metadata = StorageMetadata()
        metadata.customMetadata =
            [ "publication":   "\(self.selectedPublication.text!)"
            , "reader":        "\(Auth.auth().currentUser!.uid)"
            ]

        self.recordVC.exportCheck.notify(queue: .main) {
            recordingRef.putFile(
                from: self.recordVC.articleURLToSubmit,
                metadata: metadata) {

                    (completionMetadata, error) in

                    guard let completionMetadata = completionMetadata else {
                        return
                    }

                    print("\nBUCKET: \(completionMetadata.bucket)")

                    recordingRef.downloadURL {
                        (url, error) in

                        guard let downloadURL = url else {
                            return
                        }
                        print("\n\n\(downloadURL)\n\n")

                        try! FileManager.default.removeItem(
                            at: self.recordVC.articleURLToSubmit
                        )

                        Commands.updateSession(
                            seconds: Int(self.recordVC.sessionDuration))

                        Commands.addRecording(
                            publication: self.selectedPublication.text!)
                    }
            }
        }

        self.recordVC.resetRecordTimer()
        self.recordVC.restartUIState()
        self.navigationController?.popViewController(animated: true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

//    override func numberOfSections(in tableView: UITableView) -> Int {
//        // #warning Incomplete implementation, return the number of sections
//        return 0
//    }

//    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        // #warning Incomplete implementation, return the number of rows
//        return 0
//    }

    /*
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)

        // Configure the cell...

        return cell
    }
    */

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

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

extension SubmitTVC: UITextFieldDelegate {

    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {

        return true
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {

        textField.resignFirstResponder()
        return true
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        print(textField.text!)
    }
}
