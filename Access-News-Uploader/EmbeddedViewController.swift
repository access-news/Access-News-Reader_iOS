//
//  EmbeddedViewController.swift
//  Access News
//
//  Created by Attila Gulyas on 10/30/18.
//  Copyright © 2018 Society for the Blind. All rights reserved.
//

import UIKit

class EmbeddedViewController: UIViewController {

    @IBOutlet weak var publicationDropDown: DropDown!
    @IBOutlet weak var volunteerTimeDropDown: DropDown!

    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationController?.navigationBar.layer.cornerRadius = 19
        self.navigationController?.navigationBar.clipsToBounds = true

        self.volunteerTimeDropDown.optionArray = Array(1...250).filter { $0 % 5 == 0 }.map { "\($0 / 60) h \($0 % 60) min" }

        self.publicationDropDown.optionArray =
            [ "Auburn Journal"	  	
            , "Braille Monitor"
            , "CVS"
            , "Capital Public Radio"
            , "Client Assistance Program"
            , "Comstocks"
            , "Cooking Light"
            , "Crosswords"
            , "Davis Enterprise"
            , "Earle Baum Center newsletter"
            , "East Bay Times"
            , "El Dorado County Mountain Democrat"
            , "Entertainment Weekly"
            , "Entrepreneur"
            , "Eureka Times Standard"
            , "Farm show"
            , "Ferndale Enterprise"
            , "Foods Co"
            , "Forbes"
            , "Fort Bragg Advocate News"
            , "Fortune"
            , "Grass Valley-Nevada City Union"
            , "KQED Bay Area Bites"
            , "La Superior Grocery Store Ads"
            , "Lucky Supermarkets"
            , "Mad River Union"
            , "Meeting minutes of the California Council of the Blind"
            , "Mental Floss"
            , "Modesto Bee"
            , "Money"
            , "National Geographic"
            , "Newsweek"
            , "North Coast Journal"
            , "People"
            , "Raleys Bel Air"
            , "Real Simple"
            , "Rite Aid"
            , "Roseville Press Tribune"
            , "SF Gate"
            , "SF Weekly"
            , "SacTown"
            , "Sacramento Business Journal"
            , "Sacramento Magazine"
            , "Sacramento News & Review"
            , "Sacramento Press"
            , "Safeway"
            , "Santa Rosa Press Democrat"
            , "Save Mart"
            , "Senior News"
            , "Sierra Services for the Blind newsletter"
            , "Sprouts"
            , "Stockton Record"
            , "Sunset"
            , "Target"
            , "The Atlantic"
            , "The Economist"
            , "The Mendocino Beacon"
            , "The Oprah Magazine"
            , "Trader Joe's"
            , "Trivia"
            , "WalMart"
            , "Walgreen's"
            , "Wild West"
            , "Woodland Daily Democrat"
            , "Yuba-Sutter Meals on Wheels"
            ]
        // Do any additional setup after loading the view.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
