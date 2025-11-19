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
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(pages) { page in
                    NavigationLink(destination: CanvasView(page: page)) {
                        Text(page.title ?? "Sem título")
                    }
                }
            }
            .navigationTitle("Minhas Páginas")
            .toolbar {
                NavigationLink(destination: CanvasView(page: nil)){
                    Text("add")
                }
            }
        }
    }
}
