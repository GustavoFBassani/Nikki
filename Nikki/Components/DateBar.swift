//
//  DateBar.swift
//  Nikki
//
//  Created by sofia leitao on 03/12/25.
//
import SwiftUI

struct DateBar: View {
    @State private var selectedDate = Date()

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter.string(from: selectedDate)
    }

    var body: some View {
        HStack(spacing: 76) {
            Button {
                if let newDate = Calendar.current.date(
                    byAdding: .day,
                    value: -1,
                    to: selectedDate
                ) {
                    selectedDate = newDate
                }
            } label: {
                Image("chevronLeftCustom")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 18, height: 18)
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 999)
                            .fill(Color.white.opacity(0.85))
                    )
            }

            Button {
                //
            } label: {
                Text(formattedDate)
                    .font(Fonts.Footnote)
                    .foregroundStyle(.blueNikki)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 999)
                            .fill(Color.white.opacity(0.85))
                    )
            }

            Button {
                if let newDate = Calendar.current.date(
                    byAdding: .day,
                    value: 1,
                    to: selectedDate
                ) {
                    selectedDate = newDate
                }
            } label: {
                Image("chevronRightCustom")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 18, height: 18)
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 999)
                            .fill(Color.white.opacity(0.85))
                    )
            }
        }
    }
}
