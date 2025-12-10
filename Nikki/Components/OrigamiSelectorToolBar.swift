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
                    } label: {
                        Image("leftChevron")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 21, height: 21)
                            .foregroundStyle(.blueNikki)
                            .padding(10)
                            .background(Circle().fill(Color.white.opacity(0.85)))
                            .padding(.leading, 16)
                        
                    }
                }
                
                Spacer()
                
                if thereIsTsuruAtRight {
                    Button {
                        navigateToTsuru("right")
                    } label: {
                        Image("rightChevron")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 21, height: 21)
                            .foregroundStyle(.blueNikki)
                            .padding(10)
                            .background(Circle().fill(Color.white.opacity(0.85)))
                            .padding(.trailing, 16)
                        
                    }
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
