//
//  VisionSplashView.swift
//  Nikki
//
//  Created by Alex Fraga on 30/06/26.
//

import SwiftUI

struct VisionSplashView: View {

    // Enum de fases da animação para controle das mesmas
    @State private var phase: Phase = .idle
    // Fim da animação para transição para próxima tela
    @State private var showEnvironmentSelection = false

    // Ajustes
    private let sunSizeRatio: CGFloat = 0.7        // diâmetro do sol
    private let sunCenterYRatio: CGFloat = 0.37      // altura do centro do sol
    private let mountainWidthRatio: CGFloat = 2.5   // largura da montanha
    private let mountainHeightRatio: CGFloat = 2  // altura da montanha / altura da janela
    private let mountainCenterYRatio: CGFloat = 0.9 // altura do centro da montanha

    // O asset da montanha tem mais margem à direita
    // Este valor centraliza na janela
    private let mountainRecenterX: CGFloat = 0.1

    // Tamanho final da janela (deve bater com o .defaultSize do AppDelegate)
    private let windowFullWidth: CGFloat = 1280
    private let windowHeight: CGFloat = 720
    // Largura da faixa fina no início da abertura lateral
    private let windowStartWidth: CGFloat = 0

    // Largura atual do conteúdo. Como o WindowGroup usa .windowResizability(.contentSize),
    // animar esta largura faz a janela física do visionOS abrir lateralmente.
    private var contentWidth: CGFloat {
        phase >= .windowOpen ? windowFullWidth : windowStartWidth
    }

    private var contentHeight: CGFloat? {
        showEnvironmentSelection ? nil : windowHeight
    }

    var body: some View {
        ZStack {
            if showEnvironmentSelection {
                #if os(visionOS)
                VisionHomeRouter()
                    .transition(.opacity)
                #else
                EnvironmentSelectionView()
                    .transition(.opacity)
                #endif
            } else {
                splashAnimation()
            }
        }
        .nikkiGradientBackground()
        .frame(width: contentWidth, height: contentHeight)
        .task {
            await runAnimationsSequence()
            withAnimation(.easeInOut(duration: 0.6)) { showEnvironmentSelection = true }
        }
    }

    // MARK: - Splash (a animação)

    private func splashAnimation() -> some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            let sunDiameter = CGFloat(427)
            let sunY = h * sunCenterYRatio

            ZStack {
                // Sol nasce subindo de baixo até o centro (x: meio, y: sunY)
                Circle()
                    .fill(Color("sunNikki"))
                    .frame(width: sunDiameter, height: sunDiameter)
                    .position(x: w / 2, y: phase >= .sunUp ? sunY : sunY + sunDiameter * 1.4)
                    .opacity(phase >= .sunUp ? 1 : 0)

                // "Nikki", tamanho conforme figma
                Text(StringCatalog.nikki)
                    .font(.custom("CaveatBrush-Regular", size: 117))
                    .foregroundStyle(.white)
                    .position(x: w / 2, y: sunY - 60)
                    .opacity(phase >= .textIn ? 1 : 0)

                // Montanha
                Image("mountainNoSun")
                    .resizable()
                    .frame(width: w * mountainWidthRatio, height: h * mountainHeightRatio)
                    .position(
                        x: w / 2 + mountainRecenterX * (w * mountainWidthRatio),
                        y: phase >= .mountainUp ? h * mountainCenterYRatio : h * 1.6
                    )
                    .opacity(phase >= .mountainUp ? 1 : 0)
            }
        }
        .opacity(phase == .fadingOut ? 0 : 1)
    }

    // MARK: - Sequencia de animações
    private func runAnimationsSequence() async {
        
        withAnimation(.easeInOut(duration: VisionSplashTiming.windowOpen)) { phase = .windowOpen }
        try? await Task.sleep(for: .seconds(VisionSplashTiming.windowOpen))

        try? await Task.sleep(for: .seconds(VisionSplashTiming.initialDelay))

        withAnimation(.easeOut(duration: VisionSplashTiming.mountainRise)) { phase = .mountainUp }
        try? await Task.sleep(for: .seconds(VisionSplashTiming.mountainRise))

        withAnimation(.easeOut(duration: VisionSplashTiming.sunRise)) { phase = .sunUp }
        try? await Task.sleep(for: .seconds(VisionSplashTiming.sunRise))

        withAnimation(.easeIn(duration: VisionSplashTiming.textFadeIn)) { phase = .textIn }
        try? await Task.sleep(for: .seconds(VisionSplashTiming.textFadeIn))

        try? await Task.sleep(for: .seconds(VisionSplashTiming.hold))

        withAnimation(.easeInOut(duration: VisionSplashTiming.fadeOut)) { phase = .fadingOut }
        try? await Task.sleep(for: .seconds(VisionSplashTiming.fadeOut))
    }
}
