//
//  PageListView.swift
//  POCCanvas
//
//  Created by Alex Fraga on 18/11/25.
//

import SwiftUI
import SwiftData

//MARK: Essa tela navega pro canvasView depois de colocar o papel...
struct PageListView: View {
    @Query var pages: [Page]
    @Environment(\.modelContext) private var context
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(pages) { page in
                    NavigationLink(destination: CanvasView(page: page, paperStyle: page.paperStyle)) {
                        VStack(alignment: .leading, spacing: 4){
                            Text(page.title ?? "Sem título")
                                .font(.headline)
                            
                            if let createdAt = page.createdAt {
                                Text(createdAt, style: .date)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            }
                        }
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

#Preview {
    PageListView()
}
