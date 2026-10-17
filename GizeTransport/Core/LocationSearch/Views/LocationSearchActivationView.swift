//
//  LocationSearchActivationView.swift
//  UberSwiftUitutorial
//
//  Created by User on 12/6/22.
//
import SwiftUI

struct LocationSearchActivationView: View {
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.theme.darkGreen.opacity(0.12))
                Image(systemName: "mappin.and.ellipse")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(Color.theme.darkGreen)
            }
            .frame(width: 46, height: 46)

            VStack(alignment: .leading, spacing: 4) {
                Text("Where to?")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Color.theme.ink)
                Text("Search destination or choose a saved place")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color.theme.mutedText)
            }

            Spacer()

            Image(systemName: "magnifyingglass")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(Color.theme.darkGreen)
        }
        .padding(16)
        .gizePanel()
        .padding(.horizontal, 20)
        .padding(.bottom, 18)
    }
}

struct LocationSearchActivationView_Previews: PreviewProvider {
    static var previews: some View {
        LocationSearchActivationView()
            .padding()
            .background(Color.theme.softSurface)
    }
}
