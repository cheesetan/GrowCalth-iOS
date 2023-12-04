//
//  AuthenticationManager+VerifyEmail.swift
//  GrowCalth
//
//  Created by Tristan Chay on 5/12/23.
//

import SwiftUI
import FirebaseAuth

extension AuthenticationManager { 
    private func internalVerifyEmail(
        _ completion: @escaping ((Result<Bool, Error>) -> Void)
    ) async {
        do {
            try await Auth.auth().currentUser?.sendEmailVerification()
            completion(.success(true))
        } catch {
            completion(.failure(error))
        }
    }
    
    func verifyEmail(
        _ completion: @escaping ((Result<Bool, Error>) -> Void)
    ) {
        Task {
            await self.internalVerifyEmail { result in
                switch result {
                case .success(_):
                    completion(.success(true))
                case .failure(let failure):
                    completion(.failure(failure))
                }
            }
        }
    }
}
