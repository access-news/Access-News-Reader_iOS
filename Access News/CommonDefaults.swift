//
//  CommonDefaults.swift
//  Access News
//
//  Created by Attila Gulyas on 11/29/18.
//  Copyright © 2018 Society for the Blind. All rights reserved.
//

import UIKit

struct CommonDefaults {

    static var defaults = UserDefaults.init(suiteName: "group.org.societyfortheblind.access-news-reader-ag")!

    static func isUserLoggedIn() -> Bool {
        return defaults.bool(forKey: "is-user-logged-in")
    }

    static func userID() -> String {
        return self.defaults.string(forKey: "user-id")!
    }

    static func showLogin(navController nvc: UINavigationController, animated: Bool = false) {
        let storyboard = UIStoryboard(name: "Main", bundle: .main)
        let loginViewController = storyboard.instantiateViewController(withIdentifier: "LoginViewController")
        loginViewController.navigationItem.hidesBackButton = true
        nvc.pushViewController(loginViewController, animated: false)
    }

    static func showLoginIfNoUser(navController nvc: UINavigationController) {
        if self.isUserLoggedIn() == false {
            self.showLogin(navController: nvc, animated: false)
        }
    }

    static var publications : [String] =
        [ "Auburn Journal"
        , "Braille Monitor"
        , "CVS"
        , "Capital Public Radio"
        , "Comstocks"
        , "Cooking Light"
        , "Crosswords"
        , "Davis Enterprise"
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
        , "Newsweek"
        , "North Coast Journal"
        , "Raleys"
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
        , "Sprouts"
        , "Stockton Record"
        , "Sunset"
        , "Target"
        , "The Mendocino Beacon"
        , "The Oprah Magazine"
        , "Trader Joe's"
        , "Trivia"
        , "WalMart"
        , "Walgreen's"
        , "Woodland Daily Democrat"
        ]
}
