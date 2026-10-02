//
//  Ball.swift
//  ima-week04-HW
//
//  Created by Joyce Li on 9/29/26.
//
import SwiftUI


struct Ball: Identifiable {
    // Identifiable gives each ball its own identity.
    let id = UUID()

    let color: Color
    var x: CGFloat
    var y: CGFloat
    var level: Int
    var catchCount: Int
}
