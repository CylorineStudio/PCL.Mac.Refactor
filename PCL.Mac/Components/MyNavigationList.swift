//
//  MyNavigationList.swift
//  PCL.Mac
//
//  Created by 温迪 on 2025/12/5.
//

import SwiftUI

struct MyNavigationList: View {
    @ObservedObject private var router: AppRouter = .shared
    private let routes: [(AppRoute, String, String)]
    
    init(_ routes: (AppRoute, String, String)...) {
        self.routes = routes
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(routes, id: \.0) { route in
                RouteView(route: route.0, image: route.1, label: route.2)
                    .onTapGesture {
                        if router.getLast() != route.0 {
                            router.removeLast()
                            router.append(route.0)
                        }
                    }
            }
        }
    }
}

private struct RouteView: View {
    @ObservedObject private var router: AppRouter = .shared
    @State private var hovered: Bool = false
    @State private var selected: Bool
    private let route: AppRoute
    private let image: String
    private let label: String
    
    init(route: AppRoute, image: String, label: String) {
        self.route = route
        self.image = image
        self.label = label
        self._selected = State(initialValue: AppRouter.shared.getLast() == route)
    }
    
    var body: some View {
        HStack(spacing: 11) {
            RoundedRectangle(cornerRadius: 2)
                .fill(selected ? Color(0x1370F3) : .clear)
                .frame(width: 4, height: selected ? 24 : 10)
            Image(image)
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
            Text(label)
                .font(.custom("PCLEnglish", size: 14))
        }
        .frame(height: 32)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(hovered ? Color.pclBlue.opacity(0.1) : .clear)
        .foregroundStyle(selected ? Color(0x1370F3) : Color(0x343D4A))
        .contentShape(Rectangle())
        .onHover { hovered = $0 }
        .animation(.easeInOut(duration: 0.2), value: hovered)
        .animation(.spring(response: 0.2), value: selected)
        .onChange(of: router.getLast()) { newValue in
            selected = newValue == route
        }
    }
}

#Preview {
    MyNavigationList(
        (.launch, "LaunchPageIcon", "启动")
    )
    .frame(width: 150)
    .padding()
    .background(.white)
}
