//
//  UserProfileView.swift
//  GizeTransport
//
//  Created by User on 10/24/23.
//
import SwiftUI
import FirebaseFirestore
import FirebaseStorage

struct UserProfileView: View {
    @Binding var user: User
    @State private var editedFullName: String
    @State private var editedEmail: String
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var selectedImage: UIImage?
    @State private var isImagePickerPresented = false
    @State private var isUploading = false
    @State private var profileImageURL: String?

    init(user: Binding<User>) {
        _user = user
        _editedFullName = State(initialValue: user.wrappedValue.fullname)
        _editedEmail = State(initialValue: user.wrappedValue.email)
        _profileImageURL = State(initialValue: user.wrappedValue.profileImageUrl)
    }

    var body: some View {
        Form {
            Section(header: Text("Personal Information")) {
                TextField("Full Name", text: $editedFullName)
                TextField("Email", text: $editedEmail)
                
                Button(action: {
                    isImagePickerPresented = true
                }) {
                    if let selectedImage = selectedImage {
                        Image(uiImage: selectedImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                    } else if profileImageURL?.isEmpty ?? true {
                        Image(systemName: "person.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                            .foregroundColor(.gray)
                    } else {
                        AsyncImage(url: URL(string: "\(profileImageURL ?? "")?t=\(Date().timeIntervalSince1970)")) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                        } placeholder: {
                            ProgressView()
                                .frame(width: 100, height: 100)
                        }
                    }
                }
            }
            .padding()

            Button(action: saveChanges) {
                if isUploading {
                    ProgressView()
                } else {
                    Text("Save Changes")
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                        .background(Color.darkGreen)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            .contentShape(Rectangle()) // Ensures the entire button area is tappable
            .onTapGesture {
                saveChanges()
            }
        }
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Profile Update"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
        .sheet(isPresented: $isImagePickerPresented) {
            ImagePicker(image: $selectedImage)
        }
    }

    private func saveChanges() {
        guard let userId = user.id else { return }
        _ = Firestore.firestore()

        if let selectedImage = selectedImage {
            uploadImage(selectedImage) { result in
                switch result {
                case .success(let imageURL):
                    self.profileImageURL = imageURL
                    updateUserProfile(imageURL: imageURL)
                    // Debug print
                    print("DEBUG: Successfully uploaded image. URL: \(imageURL)")
                case .failure(let error):
                    alertMessage = "Error uploading image: \(error.localizedDescription)"
                    showAlert = true
                    // Debug print
                    print("DEBUG: Error uploading image: \(error.localizedDescription)")
                }
            }
        } else {
            updateUserProfile(imageURL: nil)
        }
    }

    private func uploadImage(_ image: UIImage, completion: @escaping (Result<String, Error>) -> Void) {
        let storage = Storage.storage()
        let storageRef = storage.reference().child("profile_images/\(UUID().uuidString).jpg")

        // Compress and resize image
        guard let resizedImage = image.resized(toWidth: 500),
              let imageData = resizedImage.jpegData(compressionQuality: 0.5) else {
            completion(.failure(NSError(domain: "ImageError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not convert image to data."])))
            return
        }

        isUploading = true
        storageRef.putData(imageData, metadata: nil) { metadata, error in
            isUploading = false
            if let error = error {
                completion(.failure(error))
            } else {
                storageRef.downloadURL { url, error in
                    if let error = error {
                        completion(.failure(error))
                    } else if let url = url {
                        completion(.success(url.absoluteString))
                    }
                }
            }
        }
    }

    private func updateUserProfile(imageURL: String?) {
        let db = Firestore.firestore()
        var data: [String: Any] = [
            "fullname": editedFullName,
            "email": editedEmail
        ]

        if let imageURL = imageURL {
            data["profileImageUrl"] = imageURL
        }

        db.collection("users").document(user.id ?? "").updateData(data) { error in
            if let error = error {
                alertMessage = "Error updating profile: \(error.localizedDescription)"
                showAlert = true
                // Debug print
                print("DEBUG: Error updating profile: \(error.localizedDescription)")
            } else {
                user.fullname = editedFullName
                user.email = editedEmail
                if let imageURL = imageURL {
                    user.profileImageUrl = imageURL
                    selectedImage = nil // Clear the selected image after successful update
                }
                alertMessage = "Profile saved successfully!"
                showAlert = true
                // Debug print
                print("DEBUG: Profile updated successfully.")
            }
        }
    }
}

extension UIImage {
    func resized(toWidth width: CGFloat) -> UIImage? {
        let canvas = CGSize(width: width, height: CGFloat(ceil(width/size.width * size.height)))
        let format = imageRendererFormat
        format.opaque = false
        return UIGraphicsImageRenderer(size: canvas, format: format).image { _ in
            draw(in: CGRect(origin: .zero, size: canvas))
        }
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.presentationMode) private var presentationMode

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        @Binding var image: UIImage?
        var parent: ImagePicker
        
        init(image: Binding<UIImage?>, parent: ImagePicker) {
            _image = image
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                image = uiImage
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(image: $image, parent: self)
    }
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
}


