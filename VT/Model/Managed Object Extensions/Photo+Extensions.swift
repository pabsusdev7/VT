//
//  Photo+Extensions.swift
//  VT
//
//  Created by Pablo Albuja on 6/30/20.
//  Copyright © 2020 Ingenuity Applications. All rights reserved.
//

import Foundation

extension Photo {
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        creationDate = Date()
    }
}
