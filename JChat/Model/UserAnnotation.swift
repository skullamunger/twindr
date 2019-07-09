//
//  UserAnnotation.swift
//  JChat
//
//  Created by DuyetTran on 3/10/19.
//  Copyright © 2019 zero2launch. All rights reserved.
//

import Foundation
import MapKit

class UserAnnotation: MKPointAnnotation {
    var uid: String?
    var age: Int?
    var profileImage: UIImage?
    var isMale: Bool?
}
