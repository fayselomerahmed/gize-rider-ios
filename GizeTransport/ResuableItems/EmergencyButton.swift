import SwiftUI

struct EmergencyButtonView: View {
    var action: () -> Void
    
    var body: some View {
        Button(action: emergencyCall) {
            HStack(spacing: 10) {
                Image(systemName: "phone.fill")  // Icon representing emergency (e.g., a phone)
                    .font(.title)
                Text("Emergency")
                    .fontWeight(.bold)
                    .font(.headline)
            }
            .foregroundColor(.white)
            .padding()
            .frame(width: UIScreen.main.bounds.width - 128, height: 50)
            .background(Color.red)  // Red is a common color for emergency buttons
            .cornerRadius(12)
            .shadow(radius: 10)
        }
        .padding()
        .buttonStyle(PlainButtonStyle())  // Ensures no default styling interferes with your custom design
    }
}
     func emergencyCall() {
         // Example action: print a message or perform a more complex operation
         print("Emergency button tapped")
         
         // To open a phone dialer (not executable in SwiftUI directly; requires integration with UIKit):
         if let url = URL(string: "tel://911"), UIApplication.shared.canOpenURL(url) {
             UIApplication.shared.open(url)
         }
     }
 


struct EmergencyButtonView_Previews: PreviewProvider {
    static var previews: some View {
        EmergencyButtonView(action: { print("Emergency Button Tapped") })
    }
}
