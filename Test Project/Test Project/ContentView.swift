//
//  ContentView.swift
//  Test Project
//
//  Created by Elliot Williams on 2025-06-06.
//

import SwiftUI

struct CoverflowCarousel: View {
    // Use explicit image names with extensions
    let images: [String] = [
        "nature-1.jpg", "nature-2.jpg", "nature-3.jpg",
        "nature-4.jpg", "nature-5.jpg", "nature-6.jpg",
        "nature-7.jpg", "nature-8.jpg", "nature-9.jpg"
    ]
    
    @State private var currentIndex = 0
    @State private var scrollOffset: CGFloat = 0
    @State private var containerWidth: CGFloat = 0
    @State private var missingImages: [String] = []
    
    private let itemWidth: CGFloat = 300
    private let itemHeight: CGFloat = 300
    private let spacing: CGFloat = -50
    private let rotationAngle: Double = 50
    private let scaleFactor: Double = 0.2
    
    var body: some View {
        VStack {
            GeometryReader { geometry in
                let containerWidth = geometry.size.width
                let totalContentWidth = (itemWidth + spacing) * CGFloat(images.count) - spacing
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .center, spacing: spacing) {
                        ForEach(images.indices, id: \.self) { index in
                            imageView(for: index)
                                .modifier(CoverFlowEffect(
                                    index: index,
                                    scrollOffset: scrollOffset,
                                    containerWidth: containerWidth,
                                    itemWidth: itemWidth,
                                    spacing: spacing,
                                    maxRotation: rotationAngle,
                                    scaleFactor: scaleFactor
                                ))
                        }
                    }
                    .frame(width: totalContentWidth)
                    .background(
                        GeometryReader { geo in
                            Color.clear
                                .preference(
                                    key: ScrollOffsetPreferenceKey.self,
                                    value: -geo.frame(in: .named("scroll")).origin.x
                                )
                        }
                    )
                }
                .coordinateSpace(name: "scroll")
                .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                    scrollOffset = value
                    
                    // Calculate current index
                    let center = value + containerWidth / 2
                    let index = Int(round((center - itemWidth / 2) / (itemWidth + spacing)))
                    currentIndex = max(0, min(index, images.count - 1))
                }
                .onAppear {
                    self.containerWidth = containerWidth
                    checkMissingImages()
                }
            }
            .frame(height: itemHeight)
            .padding(.top, 50)
            
            if !missingImages.isEmpty {
                Text("Missing images: \(missingImages.joined(separator: ", "))")
                    .foregroundColor(.red)
                    .padding()
            }
            
            PageIndicator(currentPage: currentIndex, pageCount: images.count)
                .padding(.bottom, 20)
        }
        .background(Color.black)
    }
    
    @ViewBuilder
    private func imageView(for index: Int) -> some View {
        let imageName = images[index]
        
        if UIImage(named: imageName) != nil {
            Image(imageName)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: itemWidth, height: itemHeight)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        } else {
            // Fallback with debugging info
            ZStack {
                Color.gray
                VStack {
                    Image(systemName: "exclamationmark.triangle")
                    Text("\(imageName)")
                        .font(.caption)
                }
                .foregroundColor(.red)
            }
            .frame(width: itemWidth, height: itemHeight)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .border(Color.red, width: 2)
        }
    }
    
    private func checkMissingImages() {
        missingImages = images.filter { UIImage(named: $0) == nil }
        if !missingImages.isEmpty {
            print("⚠️ Missing images: \(missingImages.joined(separator: ", "))")
        }
    }
}

// MARK: - Cover Flow Effect Modifier
struct CoverFlowEffect: ViewModifier {
    let index: Int
    let scrollOffset: CGFloat
    let containerWidth: CGFloat
    let itemWidth: CGFloat
    let spacing: CGFloat
    let maxRotation: Double
    let scaleFactor: Double
    
    func body(content: Content) -> some View {
        let itemCenter = CGFloat(index) * (itemWidth + spacing) + itemWidth / 2
        let scrollCenter = scrollOffset + containerWidth / 2
        let distance = (itemCenter - scrollCenter) / containerWidth
        let normalizedDistance = min(max(distance, -2), 2)
        
        let rotation = normalizedDistance * maxRotation
        let scale = max(1 - abs(normalizedDistance) * scaleFactor, 0.1) // Ensure doesn't go below 0.1
        let opacity = max(scale, 0.3) // Ensure doesn't go below 0.3
        
        let zIndexValue = 1.0 - Double(abs(normalizedDistance))
        
        content
            .rotation3DEffect(.degrees(rotation), axis: (x: 0, y: 1, z: 0))
            .scaleEffect(scale)
            .opacity(opacity)
            .zIndex(zIndexValue)
    }
}

// MARK: - Page Indicator
struct PageIndicator: View {
    let currentPage: Int
    let pageCount: Int
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<pageCount, id: \.self) { index in
                Circle()
                    .fill(currentPage == index ? Color.white : Color.gray)
                    .frame(width: 8, height: 8)
            }
        }
    }
}

// MARK: - Scroll Offset Preference Key
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Preview
struct CoverflowCarousel_Previews: PreviewProvider {
    static var previews: some View {
        CoverflowCarousel()
    }
}
