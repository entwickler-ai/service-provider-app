//
//  User.swift
//  findurdevswift
//
//  Created by Amanullah Naderi on 01.09.25.
//

import Foundation

struct UserModel: Identifiable, Codable, Equatable {
    var id: String { uid }
    let uid: String
    var name: String
    var email: String
    var role: String
    var profileImage: String
    var description: String
    var location: String

    init(uid: String = "",
         name: String = "",
         email: String = "",
         role: String = "",
         profileImage: String = "",
         description: String = "",
         location: String = "") {
        self.uid = uid
        self.name = name
        self.email = email
        self.role = role
        self.profileImage = profileImage
        self.description = description
        self.location = location
    }

    init(from dict: [String: Any]) {
        self.uid = dict["uid"] as? String ?? ""
        self.name = dict["name"] as? String ?? ""
        self.email = dict["email"] as? String ?? ""
        self.role = dict["role"] as? String ?? ""
        self.profileImage = dict["profileImage"] as? String ?? ""
        self.description = dict["description"] as? String ?? ""
        self.location = dict["location"] as? String ?? ""
    }

    func toDict() -> [String: Any] {
        return [
            "uid": uid,
            "name": name,
            "email": email,
            "role": role,
            "profileImage": profileImage,
            "description": description,
            "location": location
        ]
    }
}
