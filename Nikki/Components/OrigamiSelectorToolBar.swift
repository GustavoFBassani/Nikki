//
//  DateBar.swift
//  Nikki
//
//  Created by sofia leitao on 05/12/25.
//
import SwiftUI

struct OrigamiSelectorToolBar: View {
    var selectedDate: Date
    var thereIsTsuruAtRight: Bool
    var thereIsTsuruAtLeft: Bool
    var navigateToTsuru: (String)  -> Void
    @State var isButtonDisabled: Bool = false //desabilitar botao de ir para o proximo tsuru enquanto a animação acontece
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter.string(from: selectedDate)
    }
    
    var body: some View {
        ZStack {
            HStack(spacing: 76) {
                if thereIsTsuruAtLeft {
                    Button {
                        navigateToTsuru("left")
                        
                        Task {
                            isButtonDisabled = true
                            try? await Task.sleep(nanoseconds: 500_000_100)
                            isButtonDisabled = false
                        }
                    } label: {
                        Image("leftChevron")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 18, height: 18)
                            .foregroundStyle(.blueNikki)
                            .padding(10)
                            .background(Circle().fill(Color.white.opacity(0.85)))
                            .padding(.leading, 16)
                        
                    }
                    .disabled(isButtonDisabled)
                }
                
                Spacer()
                
                if thereIsTsuruAtRight {
                    Button {
                        navigateToTsuru("right")
                        
                        Task {
                            isButtonDisabled = true
                            try? await Task.sleep(nanoseconds: 500_000_100)
                            isButtonDisabled = false
                        }
                    } label: {
                        Image("rightChevron")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 18, height: 18)
                            .foregroundStyle(.blueNikki)
                            .padding(10)
                            .background(Circle().fill(Color.white.opacity(0.85)))
                            .padding(.trailing, 16)
                        
                    }
                    .disabled(isButtonDisabled)

                }
                
            }
            
            Text(formattedDate)
                .font(Fonts.Footnote)
                .foregroundColor(.blueNikki)
                .padding(.horizontal, 24)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 100)
                        .fill(Color.white.opacity(0.85))
                )
        }
    }
}

#Preview {
    OrigamiSelectorToolBar(
        selectedDate: Date(),
        thereIsTsuruAtRight: true,
        thereIsTsuruAtLeft: false,
        navigateToTsuru: { side in
            print("Navegando para o lado: \(side)")
        }
    )
}
