import SwiftUI
import TarotCore

public struct SecretVaultView: View {
    @StateObject private var vaultManager = SecretVaultManager()
    @State private var pinInput: String = ""
    @State private var pinError: String? = nil
    @State private var showingImagePicker = false
    @State private var showingAddSheet = false
    @State private var selectedImageData: Data? = nil
    @State private var newTitle: String = ""
    @State private var newNotes: String = ""
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                Color.tarotBackground.ignoresSafeArea()
                
                if !vaultManager.isUnlocked {
                    pinKeypadView
                } else {
                    unlockedVaultContent
                }
            }
            .navigationTitle("Bóveda Secreta")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                if vaultManager.isUnlocked {
                    ToolbarItem(placement: .automatic) {
                        Button {
                            vaultManager.lock()
                        } label: {
                            Label("Bloquear", systemImage: "lock.fill")
                                .foregroundStyle(Color.tarotGold)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                addEntrySheet
            }
        }
    }
    
    // MARK: - PIN Keypad View
    private var pinKeypadView: some View {
        VStack(spacing: 24) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 54))
                .foregroundStyle(Color.tarotGold)
                .padding(.bottom, 8)
            
            Text(vaultManager.hasPINSet ? "Introduce tu Código PIN" : "Crea tu Código PIN Secreto")
                .font(.system(size: 20, weight: .bold, design: .serif))
                .foregroundStyle(.primary)
            
            HStack(spacing: 16) {
                ForEach(0..<4) { index in
                    Circle()
                        .fill(index < pinInput.count ? Color.tarotGold : Color.tarotPanel)
                        .frame(width: 18, height: 18)
                        .overlay(Circle().stroke(Color.tarotGold, lineWidth: 1))
                }
            }
            .padding(.vertical, 12)
            
            if let error = pinError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
            
            // Keypad 1-9 & 0
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(72), spacing: 20), count: 3), spacing: 16) {
                ForEach(1...9, id: \.self) { digit in
                    keypadButton(number: "\(digit)")
                }
                
                Button(action: {
                    if !pinInput.isEmpty { pinInput.removeLast() }
                }) {
                    Image(systemName: "delete.left")
                        .font(.title2)
                        .frame(width: 72, height: 72)
                        .background(Color.tarotPanel)
                        .cornerRadius(36)
                        .foregroundStyle(.primary)
                }
                
                keypadButton(number: "0")
                
                Spacer()
            }
            .padding(.top, 12)
        }
        .padding()
    }
    
    private func keypadButton(number: String) -> some View {
        Button {
            TarotAudioService.shared.playCardSelect()
            if pinInput.count < 4 {
                pinInput.append(number)
                if pinInput.count == 4 {
                    verifyPIN()
                }
            }
        } label: {
            Text(number)
                .font(.system(size: 26, weight: .bold, design: .serif))
                .frame(width: 72, height: 72)
                .background(Color.tarotPanel)
                .cornerRadius(36)
                .overlay(Circle().stroke(Color.tarotBorder, lineWidth: 1))
                .foregroundStyle(Color.tarotGold)
        }
    }
    
    private func verifyPIN() {
        if vaultManager.unlock(with: pinInput) {
            pinInput = ""
            pinError = nil
        } else {
            pinError = "Código PIN incorrecto. Inténtalo de nuevo."
            pinInput = ""
        }
    }
    
    // MARK: - Unlocked Vault Content
    private var unlockedVaultContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Tiradas Físicas Guardadas")
                            .font(.system(size: 22, weight: .bold, design: .serif))
                            .foregroundStyle(Color.tarotGold)
                        Text("Fotos privadas y notas confidenciales de tus lecturas")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    
                    Button {
                        showingImagePicker = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "camera.fill")
                            Text("Capturar")
                        }
                        .font(.subheadline.bold())
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.tarotGold)
                        .foregroundStyle(.black)
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
                
                if vaultManager.entries.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "photo.badge.plus")
                            .font(.system(size: 48))
                            .foregroundStyle(Color.tarotGold.opacity(0.6))
                        Text("No tienes lecturas secretas registradas.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 40)
                } else {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 16)], spacing: 16) {
                        ForEach(vaultManager.entries) { entry in
                            vaultCardView(entry: entry)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        #if os(iOS)
        .sheet(isPresented: $showingImagePicker) {
            PhotoCapturePicker(imageData: $selectedImageData, onImagePicked: { data in
                self.selectedImageData = data
                self.showingAddSheet = true
            })
        }
        #endif
    }
    
    private func vaultCardView(entry: SecretVaultEntry) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            AsyncImage(url: vaultManager.getImageURL(for: entry)) { phase in
                if let image = phase.image {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 160)
                        .clipped()
                        .cornerRadius(12)
                } else {
                    Rectangle()
                        .fill(Color.tarotPanel)
                        .frame(height: 160)
                        .cornerRadius(12)
                        .overlay(Image(systemName: "photo").foregroundStyle(.secondary))
                }
            }
            
            Text(entry.title)
                .font(.headline)
                .lineLimit(1)
                .foregroundStyle(.primary)
            
            if !entry.notes.isEmpty {
                Text(entry.notes)
                    .font(.caption)
                    .lineLimit(2)
                    .foregroundStyle(.secondary)
            }
            
            Text(entry.dateAdded.formatted(date: .abbreviated, time: .omitted))
                .font(.caption2)
                .foregroundStyle(Color.tarotGold.opacity(0.8))
        }
        .padding(10)
        .background(Color.tarotPanel)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.tarotBorder, lineWidth: 1))
        .contextMenu {
            Button(role: .destructive) {
                vaultManager.deleteEntry(entry)
            } label: {
                Label("Eliminar", systemImage: "trash")
            }
        }
    }
    
    // MARK: - Add Entry Sheet
    private var addEntrySheet: some View {
        NavigationStack {
            Form {
                Section(header: Text("Detalles de la Lectura")) {
                    TextField("Título de la lectura", text: $newTitle)
                    TextField("Notas secretas o interpretación...", text: $newNotes, axis: .vertical)
                        .lineLimit(4...8)
                }
            }
            .navigationTitle("Nueva Lectura Secreta")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { showingAddSheet = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        if let data = selectedImageData {
                            _ = vaultManager.savePhoto(data: data, title: newTitle, notes: newNotes)
                        }
                        newTitle = ""
                        newNotes = ""
                        selectedImageData = nil
                        showingAddSheet = false
                    }
                }
            }
        }
    }
}

// MARK: - Photo Capture Picker Wrapper
#if os(iOS)
import PhotosUI

private struct PhotoCapturePicker: UIViewControllerRepresentable {
    @Binding var imageData: Data?
    let onImagePicked: (Data) -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            picker.sourceType = .camera
        } else {
            picker.sourceType = .photoLibrary
        }
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: PhotoCapturePicker
        init(_ parent: PhotoCapturePicker) { self.parent = parent }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage, let data = image.jpegData(compressionQuality: 0.8) {
                parent.imageData = data
                parent.onImagePicked(data)
            }
            picker.dismiss(animated: true)
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}
#endif
