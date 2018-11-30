//
//  SubmitTVC.swift
//  Access News
//
//  Created by Attila Gulyas on 7/13/18.
//  Copyright © 2018 Society for the Blind. All rights reserved.
//

import UIKit
import Firebase
import AVFoundation

class SubmitTVC: UITableViewController {

    @IBOutlet weak var selectedPublication: UILabel!

    let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    var recordVC: RecordViewController!

    override func viewDidLoad() {
        super.viewDidLoad()

        self.recordVC =  self.navigationController?.viewControllers[1] as! RecordViewController

        let doneButton = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(self.uploadRecording))
        self.navigationItem.rightBarButtonItem = doneButton

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    @objc func uploadRecording() {

        /* ISSUE:
           Event -LMrdLN2qYagVhfOBYYG is for a recording, but has "seq = 2",
           which is only possible if the "Done" button is hit multiple times.
           This could happen for longer recordings, when exporting needs
           some time to complete.

           FIX:
           Fixing it by (1) disabling the "Done" button once pressed and (2)
           showing an alert until the we are ready to go back to recording.

           TODO: This doesn't explain the missing 12th recording though...
                 See issue #17.
        */
        self.navigationItem.rightBarButtonItem?.isEnabled = false

        let exportAlert = UIAlertController(
            title: "Exporting...",
            message: "Getting ready to\nupload your recording.",
            preferredStyle: .alert)
        self.present(exportAlert, animated: true, completion: nil)

        let bucket = self.recordVC.recordBucket!

        Commands.updateSession(
            seconds: Int(self.recordVC.sessionDuration))

        let articleURLToSubmit =
            self.recordVC.createNewRecordingURL()
        let articleDuration: Float64 =
            CMTimeGetSeconds(bucket.articleSoFar.duration)

        let submitQueue = bucket.dispatchQueue

        submitQueue.async {
            self.recordVC.exportArticle(
                bucket:  bucket,
                fileURL: articleURLToSubmit)
        }

        submitQueue.async {
            bucket.dispatchGroup.wait()
            bucket.dispatchGroup.enter()

            /* Calling Firebase.StorageReference.putFile from the main queue,
               as it won't run from the background. It is async and therefore
               won't block, plus this just a way how it needs to be done.
               (Otherwise the app will crash.)
            */
            DispatchQueue.main.async {

                Commands.submit(
                    publication: self.selectedPublication.text!,
                    recordingName: articleURLToSubmit.pathComponents.last!,
                    duration: articleDuration,
                    recordingURL: articleURLToSubmit)
            }
        }

        let doneSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        doneSheet.addAction(UIAlertAction(
            title: "End Session",
            style: .default,
            handler: { _action in

                /* Left over chunks deleted on successful export in `exportArticle` */
                self.recordVC.endSession()
        }))
        doneSheet.addAction(
            UIAlertAction(
                title: "Start New Recording",
                style: .default,
                handler: { _action in

                    /* Left over chunks deleted on successful export in `exportArticle` */
                    self.recordVC.newRecording()
                    self.navigationController?.popViewController(animated: true)
            }))

        exportAlert.dismiss(animated: true, completion: {
            self.navigationItem.rightBarButtonItem?.isEnabled = true
            self.present(doneSheet, animated: true, completion: nil)
        })
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
