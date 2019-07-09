//
//  Configs.swift
//  JChat
//
//  Created by DuyetTran on 2/16/19.
//  Copyright © 2019 zero2launch. All rights reserved.
//

import Foundation


let serverKey = "AAAATjGgfzU:APA91bE0SQmi2oAHsolPFA6EZyA0hzqXREtI7L9zd0tv0fqYOEEH-XvvlANxcSczug6FgYxDfFZyXHbWsOlU4g0h0TRL7VpZ7idWGL_vqM7OSph2PU7_ljdQQPJXcZkTVD4Lr5bL1Vci"
let fcmUrl = "https://fcm.googleapis.com/fcm/send"
func sendRequestNotification(isMatch: Bool = false, fromUser: User, toUser: User, message: String, badge: Int) {
    var request = URLRequest(url: URL(string: fcmUrl)!)
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("key=\(serverKey)", forHTTPHeaderField: "Authorization")
    request.httpMethod = "POST"
    
    let notification: [String: Any] = [ "to" : "/topics/\(toUser.uid)",
        "notification" : ["title": (isMatch == false) ? fromUser.username : "New Match",
                          "body": message,
                          "sound" : "default",
                          "badge": badge,
                          "customData" : ["userId": fromUser.uid,
                                          "username": fromUser.username,
                                          "email": fromUser.email,
                                          "profileImageUrl": fromUser.profileImageUrl]
        ]
    ]
    
    let data = try! JSONSerialization.data(withJSONObject: notification, options: [])
    request.httpBody = data
    
    let session = URLSession.shared
    session.dataTask(with: request) { (data, response, error) in
        guard let data = data, error == nil else {
            return
        }
        
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
            print("HttpUrlResponse \(httpResponse.statusCode)")
            print("Response \(response!)")
        }
        
        if let responseString = String(data: data, encoding: String.Encoding.utf8) {
            print("ResponseString \(responseString)")
        }
        }.resume()
    
}
