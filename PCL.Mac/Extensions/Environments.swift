//
//  Environments.swift
//  PCL.Mac
//
//  Created by 温迪 on 2026/2/13.
//

import SwiftUI

private struct CardIndexKey: EnvironmentKey {
    public static let defaultValue: Int = 0
}

private struct DisableCardAppearAnimationKey: EnvironmentKey {
    public static let defaultValue: Bool = false
}

private struct DisableHoverAnimationKey: EnvironmentKey {
    public static let defaultValue: Bool = false
}

extension EnvironmentValues {
    var cardIndex: Int {
        get { self[CardIndexKey.self] }
        set { self[CardIndexKey.self] = newValue }
    }
    
    var disableCardAppearAnimation: Bool {
        get { self[DisableCardAppearAnimationKey.self] }
        set { self[DisableCardAppearAnimationKey.self] = newValue }
    }
    
    var disableHoverAnimation: Bool {
        get { self[DisableHoverAnimationKey.self] }
        set { self[DisableHoverAnimationKey.self] = newValue }
    }
}

extension View {
    func cardIndex(_ index: Int) -> some View {
        environment(\.cardIndex, index)
    }
    
    func disableCardAppearAnimation(_ disabled: Bool = true) -> some View {
        environment(\.disableCardAppearAnimation, disabled)
    }
    
    func disableHoverAnimation(_ disabled: Bool = true) -> some View {
        environment(\.disableHoverAnimation, disabled)
    }
}
