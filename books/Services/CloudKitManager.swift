import CloudKit

@MainActor
class CloudKitManager: ObservableObject {
    @Published var isUserLoggedIn: Bool = false

    func checkAccountStatus() {
        CKContainer.default().accountStatus { [weak self] (accountStatus, error) in
            DispatchQueue.main.async {
                if let error = error {
                    print("Error checking iCloud account status: \(error.localizedDescription)")
                    self?.isUserLoggedIn = false
                    return
                }

                switch accountStatus {
                case .available:
                    self?.isUserLoggedIn = true
                case .noAccount, .restricted, .couldNotDetermine:
                    self?.isUserLoggedIn = false
                @unknown default:
                    self?.isUserLoggedIn = false
                }
            }
        }
    }
}

