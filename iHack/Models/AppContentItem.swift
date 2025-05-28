//
//  AppContentItem.swift
//  iHack
//
//  Created by Yousef Jawdat on 28/05/2025.
//

import Foundation

class AppContentItem: Identifiable, ObservableObject {
    let id = UUID()
    let name: String
    let url: URL
    let isDirectory: Bool
    let isPlist: Bool
    let depth: Int
    @Published var isExpanded: Bool = false
    var children: [AppContentItem] = []
    
    init(name: String, url: URL, isDirectory: Bool, isPlist: Bool, depth: Int) {
        self.name = name
        self.url = url
        self.isDirectory = isDirectory
        self.isPlist = isPlist
        self.depth = depth
        print("Created item: \(name), isDirectory: \(isDirectory), children: \(children.count)")
    }
}