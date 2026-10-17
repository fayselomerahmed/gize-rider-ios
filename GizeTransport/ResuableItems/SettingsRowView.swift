//
//  SettingsRowView.swift
//  GizeTransport
//
//  Created by User on 4/3/23.
//

import SwiftUI

struct SettingsRowView: View {
    let imageName : String
    let title : String
    let tintColor: Color
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: imageName)
                .imageScale(.medium)
                .font(.title)
                .foregroundColor(tintColor)
            
                Text (title)
                    .font(.system(size: 15))
                    .foregroundColor(.primary)
              
            
        }.padding(4)
    }
}

struct SettingsRowView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsRowView(imageName: "bell.circle.fill", title: "Notification",tintColor: Color(.systemPurple))
    }
}
