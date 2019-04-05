//
//  ViewController.swift
//  Spotify-Demo
//
//  Created by Anderson F Carvalho on 04/04/2019.
//  Copyright © 2019 Anderson F Carvalho. All rights reserved.
//

import UIKit
import SafariServices
import Alamofire
@_exported import AVFoundation

class ViewController: UIViewController, SPTAudioStreamingPlaybackDelegate, SPTAudioStreamingDelegate {
    
    var auth = SPTAuth.defaultInstance()!
    var session:SPTSession!
    var player: SPTAudioStreamingController?
    var loginUrl: URL?
    var myplaylists = [SPTPartialPlaylist]()

    @IBOutlet weak var btnSpotify: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.updateAfterFirstLogin), name: NSNotification.Name(rawValue: "loginSuccessfull"), object: nil)
    }

    func setup () {
        // insert redirect your url and client ID below
        let redirectURL = "Spotify-Demo://spotify-login-callback" // put your redirect URL here
        let clientID = "61e711cf320b4981ba6da27262dc1a2c" // put your client ID here
        auth.redirectURL     = URL(string: redirectURL)
        auth.clientID        = clientID
        auth.requestedScopes = [SPTAuthStreamingScope, SPTAuthPlaylistReadPrivateScope, SPTAuthPlaylistModifyPublicScope, SPTAuthPlaylistModifyPrivateScope]
        loginUrl = auth.spotifyAppAuthenticationURL()
        
//        searchButtn.alpha = 0
    }
    
    func initializaPlayer(authSession:SPTSession){
        if self.player == nil {
            
            
            self.player = SPTAudioStreamingController.sharedInstance()
            self.player!.playbackDelegate = self
            self.player!.delegate = self
            try! player?.start(withClientId: auth.clientID)
            self.player!.login(withAccessToken: authSession.accessToken)
            
        }
        
    }
    
    @objc func updateAfterFirstLogin () {
        
        btnSpotify.isHidden = true
//        searchButtn.alpha = 1
        let userDefaults = UserDefaults.standard
        
        if let sessionObj:AnyObject = userDefaults.object(forKey: "SpotifySession") as AnyObject? {
            
            let sessionDataObj = sessionObj as! Data
            let firstTimeSession = NSKeyedUnarchiver.unarchiveObject(with: sessionDataObj) as! SPTSession
            
            self.session = firstTimeSession
               initializaPlayer(authSession: session)
            
            var sessionuserId: String?
            
//            self.spotifyButton.isHidden = true
//            AuthService.instance.sessiontokenId = session.accessToken!
//            print(AuthService.instance.sessiontokenId!)
            SPTUser.requestCurrentUser(withAccessToken: session.accessToken) { (error, data) in
                guard let user = data as? SPTUser else { print("Couldn't cast as SPTUser"); return }
//                AuthService.instance.sessionuserId = user.canonicalUserName
                sessionuserId = user.canonicalUserName
                print(sessionuserId)
//
//                print(AuthService.instance.sessionuserId!)
                
                // Method 2 : To get current user's playlist
                let playListRequest = try! SPTPlaylistList.createRequestForGettingPlaylists(forUser: sessionuserId ?? "", withAccessToken: self.session.accessToken ?? "")
                Alamofire.request(playListRequest)
                    .response { response in
                        
                        
                        let list = try! SPTPlaylistList(from: response.data, with: response.response)
                        
                        for playList in list.items  {
                            if let playlist = playList as? SPTPartialPlaylist {
                                print( playlist.name! ) // playlist name
                                print( playlist.uri!)    // playlist uri
//                                playList
                            }}
                        
                        self.player?.playSpotifyURI("spotify:playlist:37i9dQZEVXcCXIehoefKBj", startingWith: 1, startingWithPosition: 8, callback: { (error) in
                            if (error != nil) {
                                print("playing!")
                            }
                        })
                }
            }
//            // Method 1 : To get current user's playlist
            SPTPlaylistList.playlists(forUser: session.canonicalUsername, withAccessToken: session.accessToken, callback: { (error, response) in
                if let listPage = response as? SPTPlaylistList, let playlists = listPage.items as? [SPTPartialPlaylist] {
                    print(playlists)   // or however you want to parse these
                    //  self.myplaylists = playlists
                    self.myplaylists.append(contentsOf: playlists)
                    print(self.myplaylists)
                    
                }
            })
////            // Method 2 : To get current user's playlist
//            let playListRequest = try! SPTPlaylistList.createRequestForGettingPlaylists(forUser: sessionuserId ?? "", withAccessToken: session.accessToken ?? "")
//            Alamofire.request(playListRequest)
//                .response { response in
//
//
//                    let list = try! SPTPlaylistList(from: response.data, with: response.response)
//
//                    for playList in list.items  {
//                        if let playlist = playList as? SPTPartialPlaylist {
//                            print( playlist.name! ) // playlist name
//                            print( playlist.uri!)    // playlist uri
//                        }}
//            }
            
        }
        
    }
    
    func audioStreamingDidLogin(_ audioStreaming: SPTAudioStreamingController!) {
        print("logged in")
        
        self.player?.playSpotifyURI("spotify:playlist:37i9dQZEVXcCXIehoefKBj", startingWith: 1, startingWithPosition: 8, callback: { (error) in
            if (error != nil) {
                print("playing!")
            }
        })
    }

    @IBAction func btnSpotifyAction(_ sender: Any) {
        
        let url = "https://accounts.spotify.com/authorize?client_id=61e711cf320b4981ba6da27262dc1a2c&response_type=code&redirect_uri=Spotify-Demo://spotify-login-callback&scope=user-read-private%20user-read-email&state=34fFs29kd09"
        
        if UIApplication.shared.openURL(URL(string: url)!) {
            
            if auth.canHandle(auth.redirectURL) {
                // To do - build in error handling
            }
        }
    }
}

