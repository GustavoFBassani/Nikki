//
//  PageListView.swift
//  POCCanvas
//
//  Created by Alex Fraga on 18/11/25.
//

import SwiftUI
import SwiftData

// Struct created to link the paper style with canvas without keeping reference to an old canvas
struct NewPageRoute: Identifiable, Hashable {
    let id = UUID()
    let style: PaperStyles
}

//MARK: Essa tela navega pro canvasView depois de colocar o papel...
struct PageListView: View {
    @Query var pages: [Page]
    @Environment(\.modelContext) private var context
    
    @State private var newPageRoute: NewPageRoute?
    
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
                toolbarContent
            }
            .navigationDestination(item: $newPageRoute) { route in
                CanvasView(page: nil, paperStyle: route.style.name)
            }
        }
    }
    
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                ForEach(PaperStyles.allCases, id: \.self) { style in
                    Button(style.title) {
                        newPageRoute = NewPageRoute(style: style)
                    }
                }
            } label: {
                Label("Nova página", systemImage: "plus")
            }
        }
    }
}

#Preview {
    PageListView()
}
