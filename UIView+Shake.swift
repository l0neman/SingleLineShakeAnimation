//
//  UIView+Shake.swift
//  SingleLineShakeAnimation
//
//  Created by Håkon Bogen on 24/04/15.
//  Copyright (c) 2015 haaakon. All rights reserved.
//

import UIKit


public enum ShakeDirection : Int {
    case Horizontal
    case Vertical

    private func startPosition() -> ShakePosition {
        switch self {
        case .Horizontal:
            return ShakePosition.Left
        default:
            return ShakePosition.Top
        }
    }
}


public struct DefaultValues {
    public static let numberOfTimes = 5
    public static let totalDuration : Float = 0.5
}

extension UIView {

    /**
    Shake a view back and forth for the number of times given in the duration specified.
    If the total duration given is 1 second, and the number of shakes is 5, it will use 0.20 seconds per shake.
    After it's done shaking, the completion handler is called, if specified.

    :param: direction     The direction to shake (horizontal or vertical motion)
    :param: numberOfTimes The total number of times to shake back and forth, default value is 5
    :param: totalDuration Total duration to do the shakes, default is 0.5 seconds
    :param: completion    Optional completion closure
    */
    public func shake(direction: ShakeDirection, numberOfTimes: Int = DefaultValues.numberOfTimes, totalDuration : Float = DefaultValues.totalDuration, completion: (() -> Void)? = nil) -> UIView? {
        if UIAccessibility.isVoiceOverRunning {
            return self
        } else {
            let timePerShake = Double(totalDuration) / Double(numberOfTimes)
            shake(forTimes: numberOfTimes, position: ShakePosition.Left, durationPerShake: timePerShake, completion: completion)
            return nil
        }

    }

    public func postAccessabilityNotification(text : String ) {
        var hasRead = false
        NotificationCenter.default.addObserver(forName: UIAccessibility.announcementDidFinishNotification, object: nil, queue: nil) { Notification in
            if hasRead == false {
                UIAccessibility.post(notification: UIAccessibility.Notification.announcement, argument: text)
                hasRead = true
                
                
                NotificationCenter.default.removeObserver(self, name: UIAccessibility.announcementDidFinishNotification, object: nil)
            }
        }
        // seems to be a bug with UIAccessability that does not allow to post a notification with text in the action when tapping a button
        dispatch(after: 0.01, closure: {
            UIAccessibility.post(notification: UIAccessibility.Notification.announcement, argument: " ")
        })
    }

    func didFinishReadingAccessabilityLabel() {
        DispatchQueue.main.async {
            UIAccessibility.post(notification: UIAccessibility.Notification.announcement, argument: "hello world")
        }
    }

    private func shake(forTimes: Int, position: ShakePosition, durationPerShake: TimeInterval, completion: (() -> Void)?) {
        UIView.animate(withDuration: durationPerShake) {
            switch position.direction {
            case .Horizontal:
                self.layer.setAffineTransform(CGAffineTransform.init(translationX: 2 * position.value, y: 0))
                break
            case .Vertical:
                self.layer.setAffineTransform(CGAffineTransform.init(translationX: 0, y: 2 * position.value))
                break
            }
        } completion: { Bool in
            if (forTimes == 0) {
                UIView.animate(withDuration: durationPerShake) {
                    self.layer.setAffineTransform(CGAffineTransform.identity)
                } completion: { Bool in
                    completion?()
                }
            } else {
                self.shake(forTimes: forTimes - 1, position: position.oppositePosition(), durationPerShake: durationPerShake, completion:completion)
            }
        }
    }

}

private func dispatch(after: TimeInterval, closure: (() -> Void)? = nil) {
    dispatch(after: after, queue: DispatchQueue.main, closure: closure)
}

private func dispatch(after: TimeInterval, queue: DispatchQueue, closure: (() -> Void)? = nil) {
    let time = DispatchTime.init(uptimeNanoseconds: UInt64(after) * UInt64(NSEC_PER_SEC))
    DispatchQueue.global().asyncAfter(deadline: time) {
        closure?()
    }
}

private struct ShakePosition  {
    let value : CGFloat
    let direction : ShakeDirection

    init(value: CGFloat, direction : ShakeDirection) {
        self.value = value
        self.direction = direction
    }


    func oppositePosition() -> ShakePosition {
        return ShakePosition(value: (self.value * -1), direction: direction)
    }

    static var Left : ShakePosition {
        get {
            return ShakePosition(value: 1, direction: .Horizontal)
        }
    }

    static var Right : ShakePosition {
        get {
            return ShakePosition(value: -1, direction: .Horizontal)
        }
    }

    static var Top : ShakePosition {
        get {
            return ShakePosition(value: 1, direction: .Vertical)
        }
    }

    static var Bottom : ShakePosition {
        get {
            return ShakePosition(value: -1, direction: .Vertical)
        }
    }
}
