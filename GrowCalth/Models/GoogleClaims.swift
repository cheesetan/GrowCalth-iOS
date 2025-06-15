//
//  GoogleClaims.swift
//  GrowCalth
//
//  Created by Tristan Chay on 15/6/25.
//

import Foundation
import SwiftJWT

struct GoogleClaims: Claims {
    let iss: String
    let scope: String
    let aud: String
    let exp: Int
    let iat: Int
}
