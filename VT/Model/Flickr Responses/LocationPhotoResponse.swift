//
//  LocationPhotoResponse.swift
//  VT
//
//  Created by Pablo Albuja on 7/13/20.
//  Copyright © 2020 Ingenuity Applications. All rights reserved.
//

import Foundation

struct LocationPhotoResponse: Codable {
    let photos : Photos
    
    enum CodingKeys: String, CodingKey {
        case photos
    }
}

struct Photos: Codable {
    let page: Int
    let pages: Int
    let perpage: Int
    let total: String
    let photo : [Picture]
    
    enum CodingKeys: String, CodingKey {
        case page
        case pages
        case perpage
        case total
        case photo
    }
}

struct Picture: Codable {
    let id: String
    let owner: String
    let secret: String
    let server: String
    let farm: Int
    let title: String
    let ispublic: Int
    let isfriend: Int
    let isfamily: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case owner
        case secret
        case server
        case farm
        case title
        case ispublic
        case isfriend
        case isfamily
    }
}
