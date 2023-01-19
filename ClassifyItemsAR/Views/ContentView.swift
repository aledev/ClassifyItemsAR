//
//  ContentView.swift
//  ClassifyItemsAR
//
//  Created by Alejandro Ignacio Aliaga Martinez on 19/1/23.
//

import SwiftUI
import RealityKit

struct ContentView : View {
    var body: some View {
        
        ARViewContainer()
            .edgesIgnoringSafeArea(.all)
        
    }
}

#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif
