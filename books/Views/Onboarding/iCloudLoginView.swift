import SwiftUI

struct iCloudLoginView: View {
    @Binding var hasBypassedICloudLogin: Bool

    var body: some View {
        VStack {
            Text("iCloud Account Required")
                .font(.title)
                .padding()
            Text("To keep your library synced across all your devices, please sign in to your iCloud account.")
                .multilineTextAlignment(.center)
                .padding()
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .padding()
            .buttonStyle(.borderedProminent)

            Button("Continue without iCloud") {
                UserDefaults.standard.set(true, forKey: "hasBypassedICloudLogin")
                hasBypassedICloudLogin = true
            }
            .padding()
        }
    }
}

struct iCloudLoginView_Previews: PreviewProvider {
    static var previews: some View {
        iCloudLoginView(hasBypassedICloudLogin: .constant(false))
    }
}

