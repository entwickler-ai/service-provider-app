//
//  AuthService.swift
//  findurdevswift
//
//  Created by Amanullah Naderi on 01.09.25.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

final class AuthService {
    static let shared = AuthService()

    private let auth = Auth.auth()
    private let db = Firestore.firestore()

    private init() {}

    func register(email: String,
                  password: String,
                  name: String,
                  role: String,
                  completion: @escaping (Result<UserModel, Error>) -> Void) {

        auth.createUser(withEmail: email, password: password) { [weak self] authResult, error in
            guard let self = self else { return }

            if let error = error {
                completion(.failure(error))
                return
            }

            guard let uid = authResult?.user.uid else {
                completion(.failure(NSError(domain: "AuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "UID fehlt"])))
                return
            }

            let user = UserModel(uid: uid, name: name, email: email, role: role)
            let data = user.toDict()

            self.db.collection("users").document(uid).setData(data) { firestoreError in
                if let firestoreError = firestoreError {
                    completion(.failure(firestoreError))
                } else {
                    completion(.success(user))
                }
            }
        }
    }

    func login(email: String,
               password: String,
               completion: @escaping (Result<UserModel, Error>) -> Void) {

        auth.signIn(withEmail: email, password: password) { [weak self] authResult, error in
            guard let self = self else { return }

            if let error = error {
                completion(.failure(error))
                return
            }

            guard let uid = authResult?.user.uid else {
                completion(.failure(NSError(domain: "AuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "UID fehlt"])))
                return
            }

            self.fetchUser(uid: uid, completion: completion)
        }
    }

    func fetchUser(uid: String, completion: @escaping (Result<UserModel, Error>) -> Void) {
        db.collection("users").document(uid).getDocument { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = snapshot?.data() else {
                completion(.failure(NSError(domain: "AuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User data fehlt"])))
                return
            }
            let user = UserModel(from: data)
            completion(.success(user))
        }
    }

    func getCurrentUID() -> String? {
        return auth.currentUser?.uid
    }

    func logout() {
        do {
            try auth.signOut()
        } catch {
            print("SignOut Fehler: \(error.localizedDescription)")
        }
    }
}

extension AuthService {
    func getCurrentUser() -> UserModel? {
        return nil
    }
    
    func getCurrentUserInfo() async throws -> UserModel {
        guard let uid = getCurrentUID() else {
            throw NSError(domain: "AuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Benutzer nicht angemeldet"])
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            fetchUser(uid: uid) { result in
                continuation.resume(with: result)
            }
        }
    }
    
    func getCurrentUserInfo(completion: @escaping (Result<UserModel, Error>) -> Void) {
        guard let uid = getCurrentUID() else {
            completion(.failure(NSError(domain: "AuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Benutzer nicht angemeldet"])))
            return
        }
        
        fetchUser(uid: uid, completion: completion)
    }
}
