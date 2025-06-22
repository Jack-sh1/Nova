import SwiftUI

/**
 A view that displays a series of sine waves that animate and react to an amplitude value, 
 mimicking the Siri voice input animation.
 */
struct SiriWaveView: View {
    // The amplitude of the wave, which should be updated based on audio input level.
    @Binding var amplitude: CGFloat

    // The color of the waves.
    var colors: [Color] = [.blue, .cyan, .green, .purple]

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let time = timeline.date.timeIntervalSinceReferenceDate
                let viewCenterY = size.height / 2.0
                let viewWidth = size.width

                let waveConfigs: [(frequency: Double, amplitudeMultiplier: Double, phaseShift: Double)] = [
                    (2.0, 1.0, 0),
                    (1.5, 1.5, .pi / 3),
                    (3.0, 0.8, .pi),
                    (1.0, 2.0, .pi / 6),
                ]
                
                for (index, config) in waveConfigs.enumerated() {
                    var path = Path()
                    
                    let baseAmplitude = size.height * 0.1
                    
                    // Break down complex expressions to help the compiler
                    let normalizedAmplitude = min(amplitude, 1.0)
                    let dynamicAmplitudeMultiplier = 1.0 + (normalizedAmplitude * 4.0)
                    let waveAmplitude = baseAmplitude * dynamicAmplitudeMultiplier * CGFloat(config.amplitudeMultiplier)

                    path.move(to: CGPoint(x: 0, y: viewCenterY))

                    for x in stride(from: 0, to: Int(viewWidth), by: 1) {
                        let xPos = CGFloat(x)
                        let relativeX = xPos / viewWidth
                        
                        // Be explicit with types (Double) for math functions
                        let angle = (Double(relativeX) * 2.0 * .pi * config.frequency) + (time * 2.0) + config.phaseShift
                        let sine = sin(angle)
                        
                        let yPos = viewCenterY + (CGFloat(sine) * waveAmplitude)
                        path.addLine(to: CGPoint(x: xPos, y: yPos))
                    }

                    let color = colors[index % colors.count].opacity(0.7)
                    context.stroke(path, with: .color(color), lineWidth: 2)
                }
            }
        }
    }
}
