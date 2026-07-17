//
//  SplashView.swift
//  Veyra
//
//  Created by Icung on 05/07/26.
//

import SwiftUI

struct SplashView: View {
    @Binding var isFinished: Bool

    @State private var iconScale: CGFloat = 0.5
    @State private var iconOpacity: Double = 0.0
    @State private var textOpacity: Double = 0.0
    @State private var textOffset: CGFloat = 20
    @State private var glowOpacity: Double = 0.0

    private let animationDuration: Double = 1.8

    var body: some View {
        ZStack {
            AppColor.background
                .ignoresSafeArea()

            VStack(spacing: AppSpacing.md) {
                Spacer()

                ZStack {
                    Circle()
                        .fill(AppColor.brandLavender.opacity(0.3))
                        .frame(width: 140, height: 140)
                        .blur(radius: 20)
                        .scaleEffect(iconScale * 1.2)
                        .opacity(glowOpacity)

                    Image("logo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100, height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 22))
                        .scaleEffect(iconScale)
                        .opacity(iconOpacity)
                        .accessibilityLabel("Veyra Logo")
                }

                VStack(spacing: AppSpacing.xs) {
                    Text(verbatim: AppConstants.appName)
                        .appFont(.largeTitle)
                        .foregroundStyle(AppColor.textPrimary)
                        .accessibilityAddTraits(.isHeader)

                    Text("Local. Private. Smart.")
                        .appFont(.footnote)
                        .foregroundStyle(AppColor.textSecondary)
                        .tracking(3)
                }
                .opacity(textOpacity)
                .offset(y: textOffset)

                Spacer()
            }
            .padding()
        }
        .onAppear {
            startAnimation()
        }
    }

    private func startAnimation() {
        withAnimation(.spring(response: 0.8, dampingFraction: 0.6, blendDuration: 0)) {
            iconScale = 1.0
            iconOpacity = 1.0
        }
        
        withAnimation(.easeOut(duration: 0.6).delay(0.3)) {
            glowOpacity = 0.8
            textOpacity = 1.0
            textOffset = 0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration) {
            withAnimation(.easeInOut(duration: 0.4)) {
                isFinished = true
            }
        }
    }
}

#Preview {
    SplashView(isFinished: .constant(false))
}
