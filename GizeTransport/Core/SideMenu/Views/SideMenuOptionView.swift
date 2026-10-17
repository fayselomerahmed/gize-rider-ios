//
//  SideMenuOption.swift
//  GizeTransport
//
//  Created by User on 4/2/23.
//

import SwiftUI

struct SideMenuOptionView: View {
    let viewModel: SideMenuOptionViewModel

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: viewModel.imageName)
                .font(.system(size: 18, weight: .semibold))
                .frame(width: 40, height: 40)
                .foregroundColor(Color.theme.darkGreen)
                .background(Color.theme.darkGreen.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(viewModel.title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Color.theme.ink)
                    .lineLimit(1)

                Text(viewModel.subtitle)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color.theme.mutedText)
                    .lineLimit(1)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(Color.theme.mutedText)
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
}

struct SideMenuOptionView_Previews: PreviewProvider {
    static var previews: some View {
        SideMenuOptionView(viewModel: .history)
            .padding()
    }
}
