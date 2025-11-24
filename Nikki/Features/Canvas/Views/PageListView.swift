//
//  PageListView.swift
//  POCCanvas
//
//  Created by Alex Fraga on 18/11/25.
//

import SwiftUI
import SwiftData

struct PageListView: View {
    @Query var pages: [Page]
    @Environment(\.modelContext) private var context
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(pages) { page in
                    NavigationLink(destination: CanvasView(page: page, paperStyle: page.paperStyle)) {
                        Text(page.title ?? "Sem título")
                    }
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        let page = pages[index]
                        context.delete(page)
                    }
                    try? context.save()
                }
            }
            .navigationTitle("Minhas Páginas")
            .toolbar {
                Menu {
                    ForEach(PaperStyles.allCases, id: \.self) { style in
                        NavigationLink(
                            destination: CanvasView(
                                page: nil,
                                paperStyle: style.name
                            )
                        ) {
                            Text(style.title)
                        }
                    }
                } label: {
                    Label("Nova página", systemImage: "plus")
                }
            }
            
            
        }
    }
}
