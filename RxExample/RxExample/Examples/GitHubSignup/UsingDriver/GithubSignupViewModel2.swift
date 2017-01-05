//
//  GithubSignupViewModel2.swift
//  RxExample
//
//  Created by Krunoslav Zaher on 12/6/15.
//  Copyright © 2015 Krunoslav Zaher. All rights reserved.
//

import Foundation
#if !RX_NO_MODULE
import RxSwift
import RxCocoa
#endif

/**
This is example where view model is mutable. Some consider this to be MVVM, some consider this to be Presenter,
 or some other name.
 In the end, it doesn't matter.
 
 If you want to take a look at example using "immutable VMs", take a look at `TableViewWithEditingCommands` example.
 
 This uses Driver builder for sequences.
 
 Please note that there is no explicit state, outputs are defined using inputs and dependencies.
 Please note that there is no dispose bag, because no subscription is being made.
*/
class GithubSignupViewModel2 {
    let disposeBag = DisposeBag()
    let store = GitHubStore.shared
    
    // outputs {

    //
    let validatedUsername: Driver<ValidationResult>
    let validatedPassword: Driver<ValidationResult>
    let validatedPasswordRepeated: Driver<ValidationResult>

    // Is signup button enabled
    let signupEnabled: Driver<Bool>

    // Has user signed in
    let signedIn: Driver<Bool>

    // Is signing process in progress
    let signingIn: Driver<Bool>

    // }

    init(
        input: (
            username: Driver<String>,
            password: Driver<String>,
            repeatedPassword: Driver<String>,
            loginTaps: Driver<Void>
        )
    ) {

        /**
         Notice how no subscribe call is being made. 
         Everything is just a definition.

         Pure transformation of input sequences to output sequences.
         
         When using `Driver`, underlying observable sequence elements are shared because
         driver automagically adds "shareReplay(1)" under the hood.
         
             .observeOn(MainScheduler.instance)
             .catchErrorJustReturn(.Failed(message: "Error contacting server"))
         
         ... are squashed into single `.asDriver(onErrorJustReturn: .Failed(message: "Error contacting server"))`
        */

        input.username
            .drive(onNext: {
                GitHubAction.shared.validateFor(username: $0)
            })
            .addDisposableTo(disposeBag)
        
        input.password
            .drive(onNext: {
                GitHubAction.shared.validateFor(password: $0)
            })
            .addDisposableTo(disposeBag)
        
        Driver.combineLatest(input.password, input.repeatedPassword) { $0 }
            .drive(onNext: {
                GitHubAction.shared.validateFor(password: $0.0, repeatedPassword: $0.1)
            })
            .addDisposableTo(disposeBag)
        
        validatedUsername = store.rx.validatedUsername
        validatedPassword = store.rx.validatedPassword
        validatedPasswordRepeated = store.rx.validatedPasswordRepeated

        let signingIn = ActivityIndicator()
        self.signingIn = signingIn.asDriver()

        let usernameAndPassword = Driver.combineLatest(input.username, input.password) { ($0, $1) }
        
        input.loginTaps.withLatestFrom(usernameAndPassword)
            .drive(onNext: { (username, password) in
                GitHubAction.shared.signup(username: username, password: password, indicator: signingIn)
            })
            .addDisposableTo(disposeBag)
        
        signedIn = store.rx.signedIn

        signupEnabled = Driver.combineLatest(
            store.rx.validatedUsername,
            store.rx.validatedPassword,
            store.rx.validatedPasswordRepeated,
            signingIn
        )   { username, password, repeatPassword, signingIn in
                username.isValid &&
                password.isValid &&
                repeatPassword.isValid &&
                !signingIn
            }
            .distinctUntilChanged()
    }
}
