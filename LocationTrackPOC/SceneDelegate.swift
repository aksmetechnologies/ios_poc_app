//
//  SceneDelegate.swift
//  LocationTrackPOC
//
//  Created by Ravindra Kumar on 11/04/24.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?


    @available(iOS 13.0, *)
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        guard let _ = (scene as? UIWindowScene) else { return }
    }

    @available(iOS 13.0, *)
    func sceneDidDisconnect(_ scene: UIScene) {
        if AppDelegate.appDelegateInstance?.socket?.status == .connected {
            AppDelegate.appDelegateInstance?.disconnectSocket(isTerminating: true)
        }
    }

    @available(iOS 13.0, *)
    func sceneDidBecomeActive(_ scene: UIScene) {
        
    }

    @available(iOS 13.0, *)
    func sceneWillResignActive(_ scene: UIScene) {
        
    }

    @available(iOS 13.0, *)
    func sceneWillEnterForeground(_ scene: UIScene) {
        if AppDelegate.appDelegateInstance?.socket?.status != .connected {
            AppDelegate.appDelegateInstance?.connectSocket()
        }
    }

    @available(iOS 13.0, *)
    func sceneDidEnterBackground(_ scene: UIScene) {
        if AppDelegate.appDelegateInstance?.socket?.status != .connected {
            AppDelegate.appDelegateInstance?.connectSocket()
        }
    }

}

