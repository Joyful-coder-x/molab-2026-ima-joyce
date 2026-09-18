// xcode: set sdk=iOS

import SwiftUI
import Playgrounds
import UIKit


#Playground {

    //
    //  HW02 UIRender.swift
    //  Files.xcfilescontainer
    //
    //  Created by Joyce Li on 9/18/26.
    //


    let dim = 1024.0
    let backLevel = 0.0
    let lineLen = 1 / 10.0
    let strokeLen = 4 / 10.0

    let renderer = UIGraphicsImageRenderer(size:CGSize(width:dim, height:dim))

    var image = renderer.image { context in
        let ctx = context.cgContext
        let box = renderer.format.bounds

        // background
        UIColor(
            red: 0.02,
            green: 0.05,
            blue: 0.18,
            alpha: 1.0
        ).setFill()

        context.fill(box)

        //location
        let center = CGPoint(
            x: box.midX,
            y: box.midY
        )

        // Colors for every light point
        let colors = [
            UIColor.white.cgColor,
            UIColor.systemYellow.withAlphaComponent(0.95).cgColor,
            UIColor.systemBlue.withAlphaComponent(0.55).cgColor,
            UIColor.systemBlue.withAlphaComponent(0.0).cgColor
        ]

        let locations: [CGFloat] = [
            0.0,
            0.15,
            0.50,
            1.0
        ]

        let gradient = CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceRGB(),
            colors: colors as CFArray,
            locations: locations
        )!

        // Create five light points
        for _ in 0..<5 {

            // Randomly choose the size of this light point
            let radius = CGFloat.random(
                in: box.width * 0.08...box.width * 0.22
            )

            // Randomly choose its position
            let center = CGPoint(
                x: CGFloat.random(
                    in: radius...(box.width - radius)
                ),
                y: CGFloat.random(
                    in: radius...(box.height - radius)
                )
            )

            // Draw this light point
            ctx.drawRadialGradient(
                gradient,
                startCenter: center,
                startRadius: 0,
                endCenter: center,
                endRadius: radius,
                options: []
            )
        }
    }

    // get the bag of bits that represent the image as a png file
    let data = image.pngData()

    let folder = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first

    // Output path for the file in the Documents folder
    // Use a different file name here to have file appear as most recently added
    let filePath = folder!.appendingPathComponent("10print2026-09.png");

    let err: ()? = try? data?.write(to: filePath)

    // Terminal command 'cp' to copy output file to Downloads folder
    // The trailing period means use the same file name as the source
    let copyCommand = "cp \(filePath.absoluteString.dropFirst(7)) ~/Downloads/."

}
