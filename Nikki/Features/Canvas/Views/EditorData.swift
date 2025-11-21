//
//  EditorData.swift
//  POCCanvas
//
//  Created by Alex Fraga on 06/11/25.
//

import SwiftUI
import PencilKit
import PaperKit
import UIKit

/// Gerenciador de dados do editor PaperKit
/// Responsável por encapsular a lógica de inicialização e manipulação do PaperMarkupViewController
@Observable
class EditorData {
    // MARK: - Properties
    
    /// Controller principal do PaperKit (gerencia a área de markup)
    var controller: PaperMarkupViewController?
    
    /// Objeto de dados (markup) que representa o conteúdo desenhado ou inserido
    var markup: PaperMarkup?
    
    /// Ferramentas do PencilKit (borracha, caneta etc.)
    var toolPicker = PKToolPicker()
    
    /// Dados iniciais para carregar uma página existente
    var data: Data?
    
    // MARK: - Initialization
    
    init(data: Data?) {
        self.data = data
    }
    
    // MARK: - Controller Initialization
    
    /// Inicializa o controller e o markup com o retângulo desejado
    /// - Parameter rect: Área que o markup ocupará
    func initializeController(_ rect: CGRect) {
        // Cria o controller do PaperKit com suporte a todos os recursos mais recentes
        let controller = PaperMarkupViewController(supportedFeatureSet: .latest)
        // Caso queira um personalizado:
        // var featureSet = FeatureSet.latest
        // featureSet.remove(.loupes)
        // let controller = PaperMarkupViewController(supportedFeatureSet: featureSet) caso queira escolher as ferramentas igual WWDC
        
        // Caso usemos delegate tem que descomentar aqui
        // controller.delegate = self
        controller.loadViewIfNeeded()
        
        // Cria o modelo de markup novo
        var markup = PaperMarkup(bounds: rect)
        
        // Se tiver dados, estou carregando um canvas, sobrescreve o markup
        if let data {
            do {
                markup = try PaperMarkup(dataRepresentation: data)
            } catch {
                print(error.localizedDescription)
            }
        }
        
        // Verifica se já existe um controller armazenado (reaproveita se existir)
        if let existingController = self.controller {
            // Atualiza o markup do controller existente
            existingController.markup = markup
            self.markup = markup
        } else {
            // Caso contrário, cria e configura o novo controller
            self.markup = markup
            self.controller = controller
            self.controller?.markup = markup
            // Define o limite de zoom permitido na interface
            self.controller?.zoomRange = 0.8...1.5
        }
        
        // Configura imagem de fundo (template)
        let template = UIImage(named: "recycledPaper")
        let templateView = UIImageView(image: template)
        controller.contentView = templateView
    }
    
    // MARK: - Insertion Methods
    
    /// Insere um novo texto no markup
    /// - Parameters:
    ///   - text: Texto formatado a ser inserido
    ///   - rect: Retângulo onde o texto será posicionado
    func insertText(_ text: NSAttributedString, rect: CGRect) {
        // Sincroniza com o markup atual do controller
        if let currentMarkup = controller?.markup {
            self.markup = currentMarkup
        }
        
        markup?.insertNewTextbox(attributedText: text, frame: rect)
        
        // Atualiza o controller
        refreshController()
    }
    
    /// Insere uma imagem no markup
    /// - Parameters:
    ///   - image: Imagem a ser inserida
    ///   - rect: Retângulo onde a imagem será posicionada
    func insertImage(_ image: UIImage, rect: CGRect) {
        guard let cgImage = image.cgImage else { return }
        
        // Primeiro sincroniza o markup com o controller atual
        if let currentMarkup = controller?.markup {
            self.markup = currentMarkup
        }
        
        // Depois insere a nova imagem
        markup?.insertNewImage(cgImage, frame: rect)
        
        // E atualiza o controller
//        if let markup = self.markup {
//            controller?.markup = markup
//        }
        refreshController()
    }
    
    /// Insere uma forma geométrica no markup
    /// - Parameters:
    ///   - type: Configuração da forma a ser inserida
    ///   - rect: Retângulo onde a forma será posicionada
    func insertShape(_ type: ShapeConfiguration, rect: CGRect) {
        // Sincroniza com o markup atual do controller
        if let currentMarkup = controller?.markup {
            self.markup = currentMarkup
        }
        
        markup?.insertNewShape(configuration: type, frame: rect)
        
        // Atualiza o controller
        refreshController()
    }
    
    // MARK: - Tool Management
    
    /// Mostra ou esconde as ferramentas do PencilKit
    /// - Parameter isVisible: Se as ferramentas devem estar visíveis
    func showPencilKitTools(_ isVisible: Bool) {
        guard let controller else { return }
        toolPicker.addObserver(controller)
        toolPicker.setVisible(isVisible, forFirstResponder: controller.view)
        if isVisible {
            controller.view.becomeFirstResponder()
        }
    }
    
    // MARK: - Controller Management
    
    /// Atualiza o controller para refletir mudanças no markup
    private func refreshController() {
        controller?.markup = markup
    }
    
    // MARK: - Export Methods
    
    /// Exporta o markup como imagem
    /// - Parameters:
    ///   - rect: Retângulo a ser capturado
    ///   - scale: Escala da imagem (1.0 = tamanho original)
    /// - Returns: Imagem gerada ou nil em caso de erro
    func exportAsImage(_ rect: CGRect, scale: CGFloat = 1) async -> UIImage? {
        guard let context = makeCGContext(size: rect.size, scale: scale),
              let markup = controller?.markup else {
            return nil
        }

        await markup.draw(in: context, frame: rect)
        guard let cgImage = context.makeImage() else {
            return nil
        }

        return UIImage(cgImage: cgImage)
    }
    
    /// Exporta o markup como Data para persistência
    /// - Returns: Representação em Data do markup ou nil
    func exportMarkupData() async -> Data? {
        do {
            self.markup = controller?.markup
            return try await markup?.dataRepresentation()
        } catch {
            print("Erro ao exportar markup: \(error.localizedDescription)")
        }
        return nil
    }
    
    // MARK: - Import Methods
    
    /// Importa markup a partir de Data
    /// - Parameter data: Dados do markup a serem carregados
    func importMarkupData(_ data: Data) {
        do {
            self.markup = try PaperMarkup(dataRepresentation: data)
            refreshController()
        } catch {
            print("Erro ao importar markup: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Private Helpers
    
    /// Cria um contexto gráfico para renderização
    private func makeCGContext(size: CGSize, scale: CGFloat) -> CGContext? {
        let width = Int(size.width * scale)
        let height = Int(size.height * scale)
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: bitmapInfo
        ) else { return nil }
        
        context.scaleBy(x: scale, y: scale)
        context.translateBy(x: 0, y: size.height)
        context.scaleBy(x: 1, y: -1)
        
        return context
    }
}

// MARK: - NSAttributedString Extension
extension NSAttributedString {
    /// Centraliza o retângulo do texto dentro de um retângulo maior
    func centerRect(in rect: CGRect) -> CGRect {
        let textSize = self.size()
        let textCenter = CGPoint(
            x: rect.midX - (textSize.width / 2),
            y: rect.midY - (textSize.height / 2)
        )
        return CGRect(origin: textCenter, size: textSize)
    }
}

// Usando delegate (atualmente, quando salvamos, apenas atribuimos o markup da controller com o markup dessa clase, para nao salvar a todo instante com o didChangeMarkup. Questão de esolha apenas. Importante lembrar que tem 2 markups, dessa classe e da controller)
//extension EditorData: PaperMarkupViewController.Delegate {
//    func paperMarkupViewControllerDidChangeSelection(_ paperMarkupViewController: PaperMarkupViewController) {}
//
//    func paperMarkupViewControllerDidBeginDrawing(_ paperMarkupViewController: PaperMarkupViewController) {}
//
//    func paperMarkupViewControllerDidChangeContentVisibleFrame(_ paperMarkupViewController: PaperMarkupViewController) { }
//
//    func paperMarkupViewControllerDidChangeMarkup(_ paperMarkupViewController: PaperMarkupViewController) {
//        self.markup = paperMarkupViewController.markup
//    }
//}

// Possivelmente problemas posteriores que teremos estarão respondidos aqui: https://blog.objectivepixel.com/posts/using-paperkit-papermarkerview-in-swiftui/#architecture-overview
