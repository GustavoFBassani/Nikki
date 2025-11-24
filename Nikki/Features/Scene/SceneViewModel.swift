//
//  SceneViewModel.swift
//  Nikki
//
//  Created by Gustavo Ferreira bassani on 17/11/25.
//

import SwiftUI
import RealityKit
import NikkiProject

@Observable
class SceneViewModel {
    
    var scene: Entity?
    
    //MARK: - CAMERA PROPERTIES
    /// Câmera perspectiva usada para visualizar a cena
    var camera: PerspectiveCamera?
    /// Armazena a última posição do toque durante o gesto de arrastar
    var lastPos: CGPoint = .zero
    /// Flag que indica se o gesto de zoom está ativo no momento
    var isZooming = false
    // MARK: - Propriedades da Câmera Orbital
    /// Raio da órbita (ρ) - distância da câmera em relação ao centro da cena
    /// Em coordenadas esféricas, representa a distância radial do centro até o ponto
    private var rho: Float = 10.0
    /// Ângulo azimutal (theta/θ) - rotação horizontal em radianos
    /// Controla a rotação da câmera ao redor do eixo Z (esquerda/direita)
    /// Valores positivos rotacionam no sentido anti-horário visto de cima
    private var theta: Float = 0.0
    /// Ângulo polar (phi/φ) - ângulo em relação ao eixo Z positivo
    /// Controla a elevação da câmera (cima/baixo)
    /// - Valor 0: câmera no polo norte (topo, olhando para baixo)
    /// - Valor π/2: câmera no equador (plano XY)
    /// - Valor π: câmera no polo sul (embaixo, olhando para cima)
    private var phi: Float = Float.pi / 2
    /// Raio salvo no início do gesto de zoom para cálculo relativo
    /// Permite que o zoom seja calculado baseado na escala do gesto de pinch,
    /// mantendo o raio inicial como referência durante todo o gesto
    private var lastRho: Float = 3.0
    
    func loadScene() async {
        do {
            // Carrega a cena do arquivo Reality Composer Pro ou bundle
            let scene = try await Entity(named: "Scene", in: nikkiProjectBundle)
            self.scene = scene
            
            // Cria uma nova câmera perspectiva
            // PerspectiveCamera simula visão humana com perspectiva realista
            let camera = PerspectiveCamera()
            scene.addChild(camera)
            self.camera = camera
            
            // Posiciona a câmera usando os valores iniciais de theta, phi e distance
            updateCamera()
        } catch {
            print("Erro ao carregar cena: \(error)")
        }
    }
    
    func rotate(dx: Float, dy: Float) {
        
        // MARK: - Controle de Rotação
        
        /// Rotaciona a câmera orbital baseado no movimento do dedo na tela
        ///
        /// **Parâmetros:**
        /// - `dx`: Delta X (movimento horizontal em pixels)
        /// - `dy`: Delta Y (movimento vertical em pixels)
        ///
        /// **Comportamento (Drag Scene):**
        /// - Arrastar para Direita (dx > 0): A cena gira para direita (Câmera orbita para esquerda) -> Theta diminui
        /// - Arrastar para Baixo (dy > 0): A cena inclina para baixo (Câmera sobe para o topo) -> Phi diminui
        
        // Atualiza theta (rotação horizontal - Azimute)
        // Invertido (-=) para sensação de "pegar e arrastar" a cena
        theta -= dx * 0.01
        
        // Atualiza phi (rotação vertical - Elevação)
        // Invertido (-=) para que arrastar para baixo leve a câmera para o topo (phi -> 0)
        phi -= dy * 0.01
        
        // Limita phi entre pi/60 e 57pi/100
        // Phi = 0 é o Polo Norte (Topo)
        phi = max(Float.pi / 6, min(57 * Float.pi / 100, phi))
        
        // Recalcula e aplica a nova posição da câmera
        updateCamera()
    }
    
    func startZoom() {
        
        // MARK: - Controle de Zoom
        
        /// Salva o raio atual no início do gesto de zoom
        ///
        /// Chamado quando o usuário inicia o gesto de pinch (dois dedos).
        /// Armazena o raio atual para que o zoom seja calculado
        /// relativamente a este raio durante todo o gesto.
        ///
        /// **Exemplo:**
        /// - Raio inicial: 3.0
        /// - Usuário faz pinch com escala 2.0 (afasta dedos)
        /// - Novo raio: 3.0 / 2.0 = 1.5 (zoom in - câmera mais perto)
        
        lastRho = rho
    }
    
    func zoom(scale: Float) {
        
        /// Aplica zoom baseado na escala do gesto de pinch
        ///
        /// **Parâmetro:**
        /// - `scale`: Escala do gesto MagnificationGesture
        ///   - `scale > 1.0`: dedos se afastando → zoom in (câmera se aproxima)
        ///   - `scale < 1.0`: dedos se aproximando → zoom out (câmera se afasta)
        ///   - `scale = 1.0`: sem mudança
        ///
        /// **Cálculo:**
        /// ```
        /// rho = lastRho / scale
        /// ```
        /// - Se scale = 2.0: rho = lastRho / 2 (metade da distância = mais perto)
        /// - Se scale = 0.5: rho = lastRho / 0.5 (dobro da distância = mais longe)
        ///
        /// **Limites:**
        /// - Mínimo: 2.0 unidades (muito próximo, evita atravessar o objeto)
        /// - Máximo: 20.0 unidades (visão ampla, evita câmera muito distante)
        
        // Calcula novo raio inversamente proporcional à escala
        // Divisão por scale inverte o comportamento: afastar dedos = aproximar câmera
        rho = lastRho / scale
        
        // Limita entre 2 (muito perto) e 20 (muito longe)
        // Evita que a câmera atravesse o objeto ou fique distante demais
        rho = max(2, min(20, rho))
        
        // Recalcula e aplica a nova posição da câmera
        updateCamera()
    }
    
    private func updateCamera() {
        
        // MARK: - Atualização da Câmera
        
        /// **Mapeamento de Eixos:**
        /// - Math X  -> RealityKit X
        /// - Math Y  -> RealityKit Z (Profundidade)
        /// - Math Z  -> RealityKit Y (Altura)
        
        // Garante que a câmera existe antes de tentar atualizar
        guard let camera else { return }
        
        // 1. Cálculo Matemático (Convenção ISO: Z é altura)
        // x = ρ * sin(φ) * cos(θ)
        // y = ρ * sin(φ) * sin(θ)
        // z = ρ * cos(φ)
        
        let sinPhi = sin(phi)
        let cosPhi = cos(phi)
        let sinTheta = sin(theta)
        let cosTheta = cos(theta)
        
        let mathX = rho * sinPhi * cosTheta
        let mathY = rho * sinPhi * sinTheta
        let mathZ = rho * cosPhi
        
        //  Aplicação no RealityKit (Y é altura)
        let rkX = mathX
        let rkY = mathZ // Altura vem do Z matemático
        let rkZ = mathY // Profundidade vem do Y matemático
        
        // Define a posição calculada na câmera
        camera.position = [rkX, rkY, rkZ]
        
        // Faz a câmera sempre olhar para o centro da cena (origem 0,0,0)
        camera.look(at: [0, 0, 0], from: camera.position, relativeTo: nil)
    }
}
