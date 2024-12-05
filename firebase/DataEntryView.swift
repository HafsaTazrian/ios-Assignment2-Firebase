//
//  DataEntryView.swift
//  firetest
//
//  Created by Faysal Mahmud on 5/12/24.
//

import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseAuth

struct DataEntryView: View {
    let user: FirebaseAuth.User
    @State private var inputText = ""
    @State private var storedDataList: [StoredData] = []
    @State private var errorMessage: String?
    @State private var isLoading = false
    @State private var isIndexing = false
    private let db = Firestore.firestore()
    
    var body: some View {
        VStack {
            Text("Logged in as: \(user.email ?? "")")
                .padding()
            
            TextField("Enter your data", text: $inputText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .padding()
            }
            
            Button(action: saveDataToFirestore) {
                if isLoading {
                    ProgressView()
                } else {
                    Text("Save")
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
            }
            .disabled(inputText.isEmpty || isLoading)
            .padding()
            
            List(storedDataList) { data in
                VStack(alignment: .leading) {
                    Text(data.text)
                    Text("Added on: \(data.timestamp, formatter: itemFormatter)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .refreshable {
                await fetchStoredData()
            }
        }
        .navigationTitle("Data Entry")
        .onAppear {
            Task {
                await fetchStoredData()
            }
        }
    }
    
    private let itemFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
    
    private func saveDataToFirestore() {
        isLoading = true
        errorMessage = nil
        
        let dataToStore: [String: Any] = [
            "text": inputText,
            "userId": user.uid,
            "timestamp": FieldValue.serverTimestamp()
        ]
        
        db.collection("userData").addDocument(data: dataToStore) { error in
            isLoading = false
            if let error = error {
                errorMessage = "Error saving data: \(error.localizedDescription)"
            } else {
                inputText = ""
                Task {
                    await fetchStoredData()
                }
            }
        }
    }
    
    private func fetchStoredData() async {
            isLoading = true
            errorMessage = nil
            
            do {
                let query = db.collection("userData")
                    .whereField("userId", isEqualTo: user.uid)
                    .order(by: "timestamp", descending: true)
                
                let snapshot = try await query.getDocuments()
                
                DispatchQueue.main.async {
                    self.storedDataList = snapshot.documents.compactMap { document in
                        let data = document.data()
                        let timestamp = data["timestamp"] as? Timestamp
                        return StoredData(
                            id: document.documentID,
                            text: data["text"] as? String ?? "",
                            timestamp: timestamp?.dateValue() ?? Date()
                        )
                    }
                    self.isLoading = false
                    self.isIndexing = false
                }
            } catch let error as NSError {
                DispatchQueue.main.async {
                    self.isLoading = false
                    if error.domain == "FIRFirestoreErrorDomain" && error.code == 9 {
                        self.isIndexing = true
                        self.errorMessage = "Building database index. Please wait a moment and try again."
                    } else {
                        self.errorMessage = "Error fetching data: \(error.localizedDescription)"
                    }
                }
            }
        }
}


struct StoredData: Identifiable {
    let id: String
    let text: String
    let timestamp: Date
}

