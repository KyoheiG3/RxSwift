//
//  GitHubDispatcher.swift
//  RxExample
//
//  Created by Kyohei Ito on 2017/01/05.
//  Copyright © 2017年 Krunoslav Zaher. All rights reserved.
//

import UIKit

final class GitHubDispatcher {
    static let shared = GitHubDispatcher()
    
    let validateUsername = DispatchSubject<ValidationResult>()
    let validatePassword = DispatchSubject<ValidationResult>()
    let validatePasswordRepeated = DispatchSubject<ValidationResult>()
    let signedIn = DispatchSubject<Bool>()
    
}
