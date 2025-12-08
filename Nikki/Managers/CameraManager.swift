//
//  CameraManager.swift
//  Nikki
//
//  Created by Gustavo Ferreira bassani on 06/12/25.
//

import RealityKit
import SwiftUI

class CameraManager  {
    
    //MARK: - CAMERA PROPERTIES
    /// Câmera perspectiva usada para visualizar a cena
    var camera: PerspectiveCamera?
    
    
    private func cameraPosition(
        rho: Float,
        theta: Float,
        phi: Float,
        center: SIMD3<Float> //Center é o lookAt, o objeto que queremos focar
    ) -> SIMD3<Float> {
        let x = rho * sin(phi) * cos(theta) + center.x
        let y = rho * cos(phi)               + center.y
        let z = rho * sin(phi) * sin(theta) + center.z
        return [x, y, z]
    }
    

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
    /// Raio base para cálculo de zoom relativo
    /// Deve corresponder ao valor inicial de rho para evitar saltos no primeiro zoom
    private let baseRho: Float = 10.0
    /// Entidade que controla para onde a camera está olhando
    /// Deve estar atualizando para mudar o foco da camera
    private var cameraLook: SIMD3<Float>?

    //MARK: - CAMERA FUNCTIONS
    
    func animateCamera(
        toRho: Float? = nil,
        toTheta: Float? = nil,
        toPhi: Float? = nil,
        toLookAt: SIMD3<Float>? = nil,
        duration: TimeInterval = 1.5
    ) {
        guard let camera else { return }

        // Estado atual
        let currentRho   = self.rho
        let currentTheta = self.theta
        let currentPhi   = self.phi
        let currentLook  = self.cameraLook ?? toLookAt ?? .zero

        // Valor passado ou mantem atual em caso de nil
        let targetRho   = toRho   ?? currentRho
        let targetTheta = toTheta ?? currentTheta
        let targetPhi   = toPhi   ?? currentPhi
        let targetLook  = toLookAt ?? currentLook

        // Calcula a posição final da câmera em volta do lookAt(target look)
        let targetPos = cameraPosition(
            rho: targetRho,
            theta: targetTheta,
            phi: targetPhi,
            center: targetLook
        )

        // Mexe com transform (matriz de transformacao)
        // onde a câmera está agora
        let startTransform = camera.transform

        // Aqui atribui na camera a posicao final, onde ela deve parar ao final da animacao.
        // Isso e feito pq assim o reality kit calcula a matriz de transformacao final, sem precisar fazer esse calculo na mao
        camera.position = targetPos
        camera.look(at: targetLook, from: targetPos, relativeTo: nil)
        let targetTransform = camera.transform

        // Aqui volta a camera pra posicao inicial, uma vez que ja calculamos a matriz final e queremos animar ela ate la
        camera.transform = startTransform

        // Atualiza as variaveis de controle pros gestures nao ficarem desatualizados
        self.rho        = targetRho
        self.theta      = targetTheta
        self.phi        = targetPhi
        self.cameraLook = targetLook

        // Realiza a animacao com interpolacao nativa do framework
        camera.move(
            to: targetTransform,
            relativeTo: nil,
            duration: duration,
            timingFunction: .easeInOut
        )
    }

    func rotate(dTheta: Float, dPhi: Float) {
        /// Rotaciona a câmera orbital em torno da cena com base no gesto de arrastar.
        ///
        /// Use esta função para atualizar os ângulos esféricos da câmera e, em seguida,
        /// recalcular sua posição olhando para a origem (0, 0, 0). Os deltas recebidos
        /// normalmente vêm de um `DragGesture` na tela e são convertidos em variações
        /// nos ângulos azimutal (θ) e polar (φ).
        ///
        /// Comportamento (arrastar a cena):
        /// - Arrastar para a direita (dTheta > 0): a cena parece girar para a direita
        ///   (a câmera orbita para a esquerda) → `theta` diminui.
        /// - Arrastar para baixo (dPhi > 0): a cena inclina para baixo
        ///   (a câmera sobe em direção ao topo) → `phi` diminui.
        ///
        /// A função também limita `phi` para evitar que a câmera ultrapasse os polos,
        /// garantindo um intervalo confortável de visualização.
        ///
        /// - Parameters:
        ///   - dTheta: Delta horizontal do gesto (em pixels ou pontos), aplicado ao azimute (θ).
        ///   - dPhi: Delta vertical do gesto (em pixels ou pontos), aplicado à elevação (φ).
        ///
        /// - Note: Após ajustar `theta` e `phi`, a função chama `updateCamera()`
        ///   para aplicar imediatamente a nova posição/olhar da câmera.
        // Atualiza theta (rotação horizontal - Azimute)
        // Invertido (+=) para sensação de "pegar e arrastar" a cena
        theta += dTheta * 0.0002
        
        // Atualiza phi (rotação vertical - Elevação)
        // Invertido (-=) para que arrastar para baixo leve a câmera para o topo (phi -> 0)
        phi -= dPhi * 0.0002
        
        // Limita phi entre pi/60 e 57pi/100
        // Phi = 0 é o Polo Norte (Topo)
        phi = max(Float.pi / 6, min(51 * Float.pi / 100, phi))
        
        // Recalcula e aplica a nova posição da câmera
        updateCamera()
    }
    
    func zoom(scale: Float) {
        
        /// Aplica zoom baseado na escala do gesto de pinch
        ///
        /// **Parâmetro:**
        /// - `scale`: Escala do gesto MagnificationGesture
        ///
        /// **Cálculo:**
        /// ```
        /// rho = baseRho / scale
        /// ```
        
        // Calcula novo raio inversamente proporcional à escala
        // Divisão por scale inverte o comportamento: afastar dedos = aproximar câmera
        rho = baseRho / scale
        
        // Limita entre 2 (muito perto) e 20 (muito longe)
        // Evita que a câmera atravesse o objeto ou fique distante demais
        rho = max(0.5, min(21, rho))
        
        // Recalcula e aplica a nova posição da câmera
        updateCamera()
    }
    
    func repositioningCameraNewToTsuru(animated: Bool = true, tsuruToFocus: Entity?) {
        guard let tsuruToFocus = tsuruToFocus else { return }

        // Foca lookAt no tsuru que vai olhar
        let look = tsuruToFocus.position(relativeTo: nil)

        let targetRho:   Float = 4
        let targetTheta: Float = self.theta
        let targetPhi:   Float = self.phi
        

        if animated {
            animateCamera(
                toRho: targetRho,
                toTheta: targetTheta,
                toPhi: targetPhi,
                toLookAt: look,
                duration: 1.2
            )
        } else {
            cameraLook = look
            rho = targetRho
            theta = targetTheta
            phi = targetPhi
            updateCamera()
        }    
    } // novo
    
    func repositioningCameraToTree(animated: Bool = true, tree: Entity?) {
            guard let tree = tree else { return }
    
            //Posicao da arvore e para onde olhar, que nem antes
            let treePos = tree.position
            let look = SIMD3<Float>(
                treePos.x - 4,
                treePos.y,
                treePos.z
            )
    
            // Define angulos especificos
            let targetTheta: Float = -4.776666
            let targetPhi:   Float = self.phi
            let targetRho:   Float = 21.0
    
            if animated {
                animateCamera(
                    toRho: targetRho,
                    toTheta: targetTheta,
                    toPhi: targetPhi,
                    toLookAt: look,
                    duration: 1.5
                )
            } else {
                self.cameraLook = look
                self.rho = targetRho
                self.theta = targetTheta
                self.phi = targetPhi
                updateCamera()
            }
        } //novo

    func updateCamera() {
        
        // Garante que a câmera existe antes de tentar atualizar
        guard let camera else { return }
        
        if let cameraLook {
            let x = rho * sin(phi) * cos(theta) + cameraLook.x
            let y = rho * cos(phi) +  cameraLook.y
            let z = rho * sin(phi) * sin(theta) + cameraLook.z
            //            print("theta: ", theta)
            //            print("rho: ", rho)
            camera.position = [x, y, z]
            camera.look(at: cameraLook, from: camera.position, relativeTo: nil)
            
        }
    }
    
    func focusOnBandstand() {
        // Posicao do coreto
        let look = SIMD3<Float>(-7.3, -0.3, -8.2)

        // Posicao da camera
        let desiredPos = SIMD3<Float>(-3.5, -0.3, -8.2)

        // Vetor do centro (look) até a câmera
        let distance = desiredPos - look
        let x = distance.x
        let y = distance.y
        let z = distance.z

        // Converte pra coordenadas esfericas
        let rho   = simd_length(distance)
        let phi   = acosf(y / rho)
        let theta = atan2f(z, x)

        animateCamera(
            toRho: rho,
            toTheta: theta,
            toPhi: phi,
            toLookAt: look,
            duration: 1.5
        )
    }

}


