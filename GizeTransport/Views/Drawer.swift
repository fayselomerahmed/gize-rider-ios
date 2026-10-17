//
//  DrawerApp.swift
//  GizeTransport
//
//  Created by User on 12/24/22.
//

import SwiftUI

struct Drawer: View {
    var body: some View {
        VStack {
            HStack {
                Image ("logo")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 65,height: 65 , alignment: .leadingLastTextBaseline)
                    .clipShape(Circle())
                Spacer()
            }
            .padding()
            VStack(alignment: .leading,spacing: 10 , content: {
                Text ("Gize Transport")
                    .font(.largeTitle)
                    .fontWeight(.semibold)
                
                Divider()
                Button {
                    
                } label: {
                    Text ("Home")
                }.foregroundColor(.white)
                    .font(.title)
                    
            })
            .foregroundColor(.white)
            .frame(maxWidth : .infinity,alignment: .leading)
            .padding(.horizontal)
            .padding(.top , 5)
            
            Spacer()
        }
        .frame(width: 250)
        .background(Color(.systemGray2))
    }
}

