//
//  DispatchSubject.swift
//  RxExample
//
//  Created by Kyohei Ito on 2017/01/05.
//  Copyright © 2017年 Krunoslav Zaher. All rights reserved.
//

import RxSwift

class DispatchSubject<Element>: ObservableType, ObserverType {
    typealias E = Element
    fileprivate let subject = ReplaySubject<Element>.create(bufferSize: 1)
    
    func dispatch(_ value: Element) {
        on(.next(value))
    }
    
    func subscribe<O: ObserverType>(_ observer: O) -> Disposable where O.E == E {
        return subject.subscribe(observer)
    }
    
    func on(_ event: Event<E>) {
        subject.on(event)
    }
}
