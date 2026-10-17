//
//  SavedLocationRowView.swift
//  GizeTransport
//
//  Created by User on 4/3/23.
//

import SwiftUI

struct SavedLocationRowView: View {
    let viewModel: SavedLocationViewModel
    let user: User
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: viewModel.imageName)
                .imageScale(.medium)
                .font(.title)
                .foregroundColor(Color(.systemBlue))
            VStack(alignment: .leading, spacing: 4) {
                Text (viewModel.title)
                    .font(.system(size: 15 , weight: .semibold))
                    .foregroundColor(.primary)
//                Text (viewModel.subtitle(forUser: user))
//                    .font(.system(size: 14))
//                    .foregroundColor(.gray)
            }
        }

    }
}

//struct SavedLocationRowView_Previews: PreviewProvider {
//    static var previews: some View {
//        SavedLocationRowView(viewModel:.home)
//    }
//}
