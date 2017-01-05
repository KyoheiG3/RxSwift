//
//  GitHubStore.swift
//  RxExample
//
//  Created by Kyohei Ito on 2017/01/05.
//  Copyright © 2017年 Krunoslav Zaher. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class GitHubStore: Store {
    static let shared = GitHubStore()
    
    let validatedUsername = Variable<ValidationResult>(.empty)
    let validatedPassword = Variable<ValidationResult>(.empty)
    let validatedPasswordRepeated = Variable<ValidationResult>(.empty)
    let signedIn = Variable<Bool>(false)
    
    init(dispatcher: GitHubDispatcher = .shared) {
        super.init()
        
        dispatcher.validateUsername
            .bindTo(validatedUsername)
            .addDisposableTo(disposeBag)
        
        dispatcher.validatePassword
            .bindTo(validatedPassword)
            .addDisposableTo(disposeBag)
        
        dispatcher.validatePasswordRepeated
            .bindTo(validatedPasswordRepeated)
            .addDisposableTo(disposeBag)
        
        dispatcher.signedIn
            .bindTo(signedIn)
            .addDisposableTo(disposeBag)
    }
}

extension Reactive where Base: GitHubStore {
    var validatedUsername: Driver<ValidationResult> {
        return base.validatedUsername.asDriver()
    }
    var validatedPassword: Driver<ValidationResult> {
        return base.validatedPassword.asDriver()
    }
    var validatedPasswordRepeated: Driver<ValidationResult> {
        return base.validatedPasswordRepeated.asDriver()
    }
    var signedIn: Driver<Bool> {
        return base.signedIn.asDriver()
    }
}
