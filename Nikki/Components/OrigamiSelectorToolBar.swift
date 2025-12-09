//
//  DateBar.swift
//  Nikki
//
//  Created by sofia leitao on 05/12/25.
//
import SwiftUI

struct OrigamiSelectorToolBar: View {
    var selectedDate: Date
    var shouldShowLeftButton = true
    var shouldShowRightButton = true
    var action: (SceneViewModel.SideToMove) -> Void = {_ in }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter.string(from: selectedDate)
    }
    
    var body: some View {
        HStack(spacing: 76) {
            if shouldShowLeftButton {
                Button {
                    action(.left)
                } label: {
                    Image("leftChevron")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 18, height: 18)
                        .foregroundStyle(.blueNikki)
                        .padding(10)
                        .background(Circle().fill(Color.white.opacity(0.85)))

                }
            } else {
                Spacer()
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
            
            
            if shouldShowRightButton {
                Button {
                    action(.right)
                } label: {
                    Image("rightChevron")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 18, height: 18)
                        .foregroundStyle(.blueNikki)
                        .padding(10)
                        .background(Circle().fill(Color.white.opacity(0.85)))

                }
            } else {
                Spacer()
            }
            
        }
    }
}


#Preview {
    OrigamiSelectorToolBar(selectedDate: Date())
}
