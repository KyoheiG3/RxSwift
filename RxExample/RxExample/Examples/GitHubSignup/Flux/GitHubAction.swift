//
//  GitHubAction.swift
//  RxExample
//
//  Created by Kyohei Ito on 2017/01/05.
//  Copyright © 2017年 Krunoslav Zaher. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

final class GitHubAction {
    static let shared = GitHubAction()
    
    let URLSession: Foundation.URLSession
    fileprivate let dispatcher: GitHubDispatcher
    fileprivate let wireframe: Wireframe
    
    init(URLSession: Foundation.URLSession = .shared,
         dispatcher: GitHubDispatcher = .shared,
         wireframe: Wireframe = DefaultWireframe.sharedInstance) {
        self.URLSession = URLSession
        self.dispatcher = dispatcher
        self.wireframe = wireframe
    }
    
    let minPasswordCount = 5
    
    @discardableResult
    func validateFor(username: String) -> Disposable {
        return validateUsername(username)
            .catchErrorJustReturn(.failed(message: "Error contacting server"))
            .subscribe(onNext: { [unowned self] in
                self.dispatcher.validateUsername.dispatch($0)
            })
    }
    
    func validateFor(password: String) {
        dispatcher.validatePassword.dispatch(validatePassword(password))
    }
    
    func validateFor(password: String, repeatedPassword: String) {
        dispatcher.validatePasswordRepeated.dispatch(validateRepeatedPassword(password, repeatedPassword: repeatedPassword))
    }
    
    @discardableResult
    func signup(username: String, password: String, indicator: ActivityIndicator) -> Disposable {
        return signup(username, password: password)
            .trackActivity(indicator)
            .asDriver(onErrorJustReturn: false)
            .flatMapLatest { [unowned self] loggedIn -> Driver<Bool> in
                let message = loggedIn ? "Mock: Signed in to GitHub." : "Mock: Sign in to GitHub failed"
                return self.wireframe.promptFor(message, cancelAction: "OK", actions: [])
                    // propagate original value
                    .map { _ in
                        loggedIn
                    }
                    .asDriver(onErrorJustReturn: false)
            }
            .drive(onNext:{
                self.dispatcher.signedIn.dispatch($0)
            })
    }
}

private extension GitHubAction {
    func validateUsername(_ username: String) -> Observable<ValidationResult> {
        if username.characters.count == 0 {
            return .just(.empty)
        }
        
        
        // this obviously won't be
        if username.rangeOfCharacter(from: CharacterSet.alphanumerics.inverted) != nil {
            return .just(.failed(message: "Username can only contain numbers or digits"))
        }
        
        let loadingValue = ValidationResult.validating
        
        return usernameAvailable(username)
            .map { available in
                if available {
                    return .ok(message: "Username available")
                }
                else {
                    return .failed(message: "Username already taken")
                }
            }
            .startWith(loadingValue)
    }
    
    func validatePassword(_ password: String) -> ValidationResult {
        let numberOfCharacters = password.characters.count
        if numberOfCharacters == 0 {
            return .empty
        }
        
        if numberOfCharacters < minPasswordCount {
            return .failed(message: "Password must be at least \(minPasswordCount) characters")
        }
        
        return .ok(message: "Password acceptable")
    }
    
    func validateRepeatedPassword(_ password: String, repeatedPassword: String) -> ValidationResult {
        if repeatedPassword.characters.count == 0 {
            return .empty
        }
        
        if repeatedPassword == password {
            return .ok(message: "Password repeated")
        }
        else {
            return .failed(message: "Password different")
        }
    }
}

private extension GitHubAction {
    func usernameAvailable(_ username: String) -> Observable<Bool> {
        // this is ofc just mock, but good enough
        
        let url = URL(string: "https://github.com/\(username.URLEscaped)")!
        let request = URLRequest(url: url)
        return self.URLSession.rx.response(request: request)
            .map { (response, _) in
                return response.statusCode == 404
            }
            .take(1)
            .catchErrorJustReturn(false)
    }
    
    func signup(_ username: String, password: String) -> Observable<Bool> {
        // this is also just a mock
        let signupResult = arc4random() % 5 == 0 ? false : true
        return Observable.just(signupResult)
            .concat(Observable.never())
            .throttle(0.4, scheduler: MainScheduler.instance)
            .take(1)
    }
}
