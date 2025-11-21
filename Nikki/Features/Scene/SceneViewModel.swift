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
    /// Distância da câmera em relação ao centro da cena (raio da órbita)
    private var distance: Float = 3.0
    /// Ângulo azimutal (theta/θ) - rotação horizontal em radianos
    /// Controla a rotação da câmera ao redor do eixo Y (esquerda/direita)
    /// Valores positivos rotacionam no sentido anti-horário visto de cima
    private var theta: Float = 0.0
    /// Ângulo polar (phi/φ) - rotação vertical em radianos
    /// Controla a elevação da câmera (cima/baixo)
    /// - Valor 0: câmera no plano XZ (altura neutra)
    /// - Valores positivos: câmera acima do objeto
    /// - Valores negativos: câmera abaixo do objeto
    private var phi: Float = 0.0
    /// Distância salva no início do gesto de zoom para cálculo relativo
    /// Permite que o zoom seja calculado baseado na escala do gesto de pinch,
    /// mantendo a distância inicial como referência durante todo o gesto
    private var lastDistance: Float = 3.0
    
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
        ///   - Valores positivos: arrasta para direita → câmera orbita para esquerda
        ///   - Valores negativos: arrasta para esquerda → câmera orbita para direita
        /// - `dy`: Delta Y (movimento vertical em pixels)
        ///   - Valores positivos: arrasta para baixo → câmera sobe
        ///   - Valores negativos: arrasta para cima → câmera desce
        ///
        /// **Sensibilidade:** 0.01 radianos por pixel de movimento
        /// - Aproximadamente 0.57° por pixel
        /// - Isso significa que arrastar 175 pixels = uma volta completa (360°/2π)
        ///
        /// **Limitação de Phi:**
        /// O ângulo phi é limitado entre -1.5 e 1.5 radianos (~-86° a +86°)
        /// para evitar que a câmera vire completamente de cabeça para baixo,
        /// o que causaria uma inversão confusa dos controles
        
        // Atualiza theta (rotação horizontal) sem limites
        // Permite rotação infinita ao redor do objeto
        theta += dx * 0.01
        
        // Atualiza phi (rotação vertical)
        phi += dy * 0.01
        
        // Limita phi para não virar de cabeça pra baixo
        // -1.5 rad ≈ -86° (quase olhando de baixo)
        // +1.5 rad ≈ +86° (quase olhando de cima)
        phi = max(-1, min(1.5, phi))
        
        // Recalcula e aplica a nova posição da câmera
        updateCamera()
    }
    
    func startZoom() {
        
        // MARK: - Controle de Zoom
        
        /// Salva a distância atual no início do gesto de zoom
        ///
        /// Chamado quando o usuário inicia o gesto de pinch (dois dedos).
        /// Armazena a distância atual para que o zoom seja calculado
        /// relativamente a esta distância durante todo o gesto.
        ///
        /// **Exemplo:**
        /// - Distância inicial: 3.0
        /// - Usuário faz pinch com escala 2.0 (afasta dedos)
        /// - Nova distância: 3.0 / 2.0 = 1.5 (zoom in - câmera mais perto)
        
        lastDistance = distance
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
        /// distance = lastDistance / scale
        /// ```
        /// - Se scale = 2.0: distance = lastDistance / 2 (metade da distância = mais perto)
        /// - Se scale = 0.5: distance = lastDistance / 0.5 (dobro da distância = mais longe)
        ///
        /// **Limites:**
        /// - Mínimo: 0.5 unidades (muito próximo, evita atravessar o objeto)
        /// - Máximo: 30.0 unidades (visão ampla, evita câmera muito distante)
        
        // Calcula nova distância inversamente proporcional à escala
        // Divisão por scale inverte o comportamento: afastar dedos = aproximar câmera
        distance = lastDistance / scale
        
        // Limita entre 0.5 (muito perto) e 30 (muito longe)
        // Evita que a câmera atravesse o objeto ou fique distante demais
        distance = max(2, min(20, distance))
        
        // Recalcula e aplica a nova posição da câmera
        updateCamera()
    }
    
    private func updateCamera() {
        
        // MARK: - Atualização da Câmera
        
        /// Atualiza a posição da câmera convertendo coordenadas esféricas para cartesianas
        ///
        /// **Conversão de Coordenadas Esféricas → Cartesianas:**
        ///
        /// Coordenadas esféricas são mais intuitivas para órbita:
        /// - `theta` (θ): "para que lado estou olhando" (bússola)
        /// - `phi` (φ): "quão alto estou" (elevação)
        /// - `distance` (r): "quão longe estou" (raio)
        ///
        /// Fórmulas de conversão:
        /// ```
        /// x = r * cos(φ) * sin(θ)  ← posição horizontal (eixo X)
        /// y = r * sin(φ)            ← altura (eixo Y)
        /// z = r * cos(φ) * cos(θ)  ← profundidade (eixo Z)
        /// ```
        ///
        /// **Visualização:**
        /// ```
        ///        Y (cima)
        ///        |
        ///        |  * câmera (x,y,z)
        ///        | /
        ///        |/_____ X (direita)
        ///       /|
        ///      / |
        ///     Z (frente)
        ///   origem (0,0,0) = centro da cena
        /// ```
        ///
        /// **Processo:**
        /// 1. Calcula coordenadas cartesianas (x, y, z) usando as fórmulas
        /// 2. Define a posição da câmera com estas coordenadas
        /// 3. Faz a câmera olhar sempre para o centro da cena (0, 0, 0)
        ///
        /// - Note: O método `look(at:from:relativeTo:)` ajusta automaticamente
        ///   a orientação da câmera para apontar ao alvo especificado

        
        // Garante que a câmera existe antes de tentar atualizar
        guard let camera else { return }
        
        // Converte coordenadas esféricas (theta, phi, distance) para
        // coordenadas cartesianas (x, y, z)
        
        // X: posição horizontal (esquerda-direita)
        // cos(phi) projeta no plano XZ, sin(theta) define posição no círculo
        let x = distance * cos(phi) * sin(theta)
        
        // Y: altura (cima-baixo)
        // sin(phi) eleva ou abaixa a câmera
        let y = distance * sin(phi)
        
        // Z: profundidade (frente-trás)
        // cos(phi) projeta no plano XZ, cos(theta) define posição no círculo
        let z = distance * cos(phi) * cos(theta)
        
        // Define a posição calculada na câmera
        // SIMD3 é um vetor 3D otimizado para operações matemáticas
        camera.position = [x, y, z]
        
        // Faz a câmera sempre olhar para o centro da cena (origem 0,0,0)
        // - at: ponto alvo (centro da cena)
        // - from: posição da câmera (calculada acima)
        // - relativeTo: nil = coordenadas absolutas no mundo
        // Este método ajusta automaticamente a rotação da câmera
        camera.look(at: [0, 0, 0], from: camera.position, relativeTo: nil)
    }


}
