//
//  ContentView.swift
//  MagnificationLoupe
//
//  Created by Janum Trivedi on 6/15/23.
//

import SwiftUI
import Wave

struct ContentView: View {

    static let loupeRestingPosition = CGPoint(x: 0.15, y: 0.85)

    static let loupeRestingSize = 0.1
    static let loupeDraggingSize = 0.2

    @State var loupeCenter = loupeRestingPosition
    @State var loupeSize = loupeRestingSize

    @State var isDragging: Bool = false
    @State var initialTouchLocation: CGPoint? = nil

    @State var loupePositionAnimator = SpringAnimator<CGPoint>(
        spring: .init(dampingRatio: 0.92, response: 0.2),
        value: loupeRestingPosition
    )

    @State var loupeSizeAnimator = SpringAnimator<CGFloat>(
        spring: .init(dampingRatio: 0.72, response: 0.7),
        value: loupeRestingSize
    )

    func loupeEffect(center: CGPoint, size: CGFloat) -> Shader {
        Shader(function: .init(library: .default, name: "loupe"), arguments: [
            .boundingRect,
            .float2(center.x, center.y),
            .float(size),
        ])
    }

    func rotation3D(for loupeCenter: CGPoint, isDragging: Bool) -> CGPoint {
        let maxRotationDegrees = isDragging ? 10.0 : 0
        let rotX = mapRange(loupeCenter.x, 0, 1, maxRotationDegrees, -maxRotationDegrees)
        let rotY = mapRange(loupeCenter.y, 0, 1, -maxRotationDegrees, maxRotationDegrees)
        return CGPoint(x: rotX, y: rotY)
    }

    var body: some View {
        TimelineView(.animation) { context in
            GeometryReader { proxy in
                let size = proxy.size
                let maxSampleOffset = CGSize(width: 40, height: 40)

                let rotation = rotation3D(for: loupeCenter, isDragging: isDragging)

                VStack {
                    Spacer()
                    Image("maps")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .scaleEffect(x: isDragging ? 1.05 : 1, y: isDragging ? 1.05 : 1)
                        .rotation3DEffect(
                            .degrees(rotation.x), axis: (x: 0.0, y: 1.0, z: 0.0)
                        )
                        .rotation3DEffect(
                            .degrees(rotation.y), axis: (x: 1.0, y: 0.0, z: 0.0)
                        )
                        .layerEffect(loupeEffect(center: loupeCenter, size: loupeSize), maxSampleOffset: maxSampleOffset)

                    Spacer()
                }
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged{ value in
                            if initialTouchLocation == nil {
                                initialTouchLocation = loupeCenter
                            }

                            guard let initialTouchLocation else {
                                return
                            }

                            let translation = value.translation
                            let normTranslation = CGPoint(
                                x: translation.width / size.width,
                                y: translation.height / size.width
                            )

                            let newLoupeCenter = CGPoint(
                                x: initialTouchLocation.x + normTranslation.x,
                                y: initialTouchLocation.y + normTranslation.y
                            )

                            loupePositionAnimator.spring = .init(dampingRatio: 0.92, response: 0.2)
                            loupePositionAnimator.target = newLoupeCenter
                            loupePositionAnimator.start()

                            loupeSizeAnimator.target = Self.loupeDraggingSize
                            loupeSizeAnimator.start()

                            withAnimation(.spring(response: 0.4, dampingFraction: 1.1)) {
                                isDragging = true
                            }
                        }
                        .onEnded { value in
                            let liftOffVelocity = value.velocity
                            loupePositionAnimator.velocity = CGPoint(
                                x: liftOffVelocity.width / size.width,
                                y: liftOffVelocity.height / size.height
                            )

                            loupePositionAnimator.spring = .init(dampingRatio: 0.72, response: 0.7)
                            loupePositionAnimator.target = Self.loupeRestingPosition
                            loupePositionAnimator.start()

                            loupeSizeAnimator.target = Self.loupeRestingSize
                            loupeSizeAnimator.start()

                            initialTouchLocation = nil

                            withAnimation(.spring(response: 0.4, dampingFraction: 1.1)) {
                                isDragging = false
                            }
                        }
                )
                .onAppear {
                    loupePositionAnimator.valueChanged = { value in
                        loupeCenter = value
                    }

                    loupeSizeAnimator.valueChanged = { value in
                        loupeSize = value
                    }
                }
            }
        }
        .background {
            Color.black
        }
        .ignoresSafeArea(.all)
    }
}

#Preview {
    ContentView()
}
