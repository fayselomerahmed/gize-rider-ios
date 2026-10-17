//
//  SlideView.swift
//  GizeTransport
//
//  Created by User on 12/23/22.
//

import SwiftUI

struct SlideView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading , spacing: 30) {
                    
                    
                    VStack(alignment: .leading) {
                            Image ("logo")
                                .resizable()
                                .frame(width: 100,height: 100)
                                .scaledToFit()
                                .cornerRadius(100)
                                .clipShape(Circle())
                            
                            Text("Gize Transport")
                                .font(.title2)
                                .fontWeight(.semibold)
                    }
                    
                    Divider()
                    HStack(spacing: 15) {
                        (Image(systemName: "house"))
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20,height: 20)
                            
                            .foregroundColor(.black)
                        Button {
                            
                        } label: {
                            Text ("Home")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(Color(.systemMint))
                        }
                        Spacer()
                    }
                    HStack(spacing: 15) {
                        (Image(systemName: "calendar"))
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20,height: 20)
                            
                        Button {
                            
                        } label: {
                            Text ("Pre order")
                                .font(.title2)
                               
                                .foregroundColor(Color(.systemMint))
                        }
                        Spacer()
                    }
                    HStack(spacing: 15) {
                        (Image(systemName: "clock"))
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20,height: 20)
                            
                        Button {
                            
                        } label: {
                            Text ("History")
                                .font(.title2)
                                
                                .foregroundColor(Color(.systemMint))
                        }
                        Spacer()
                    }
                    HStack(spacing: 15) {
                        (Image(systemName: "bell"))
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20,height: 20)
                           
                        
                        Button {
                            
                        } label: {
                            Text ("Notification")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(Color(.systemMint))
                        }
                        Spacer()
                    }
                    HStack(spacing: 15) {
                        (Image(systemName: "clock.circle"))
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20,height: 20)
                            
                        Button {
                            
                        } label: {
                            Text ("Gize Miles")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(Color(.systemMint))
                        }
                        Spacer()
                    }
                    HStack(spacing: 15) {
                        (Image(systemName: "questionmark.circle"))
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20,height: 20)
                            
                        Button {
                            
                        } label: {
                            Text ("Support")
                                .font(.title2)
                    
                                .foregroundColor(Color(.systemMint))
                        }
                        
                    }
                    
                    Spacer()
                }
            }
        }
    }
}

struct SlideView_Previews: PreviewProvider {
    static var previews: some View {
        SlideView()
    }
}
