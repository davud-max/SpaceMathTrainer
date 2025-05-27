//
//  Item.swift
//  SpaceMathTrainer
//
//  Created by Davud Zulumkhanov on 27.05.2025.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
