//
//  MyNavigationList.swift
//  PCL.Mac
//
//  Created by 温迪 on 2025/12/5.
//

import SwiftUI

struct MyNavigationList: View {
    @ObservedObject private var router: AppRouter = .shared
    private let routes: [Route]
    private let performRefresh: ((AppRoute) -> Void)?
    
    init(_ routes: Route..., performRefresh: ((AppRoute) -> Void)? = nil) {
        self.init(routeList: routes, performRefresh: performRefresh)
    }
    
    init(routeList: [Route], performRefresh: ((AppRoute) -> Void)? = nil) {
        self.routes = routeList
        self.performRefresh = performRefresh
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(routes, id: \.route) { route in
                RouteView(route: route, refresh: performRefresh)
                    .onTapGesture {
                        if router.getLast() != route.route {
                            router.removeLast()
                            router.append(route.route)
                        }
                    }
            }
        }
    }
    
    struct Route {
        let route: AppRoute
        let image: String?
        let text: String
        
        init(_ route: AppRoute, _ image: String?, _ text: String) {
            self.route = route
            self.image = image
            self.text = text
        }
    }
}

private struct RouteView: View {
    @ObservedObject private var router: AppRouter = .shared
    @State private var hovered: Bool = false
    @State private var selected: Bool
    @State private var lastRefresh: Date = .distantPast
    private let route: AppRoute
    private let image: String?
    private let label: String
    private let refresh: ((AppRoute) -> Void)?
    
    init(route: MyNavigationList.Route, refresh: ((AppRoute) -> Void)?) {
        self.route = route.route
        self.image = route.image
        self.label = route.text
        self.refresh = refresh
        self._selected = State(initialValue: AppRouter.shared.getLast() == route.route)
    }
    
    var body: some View {
        HStack(spacing: 11) {
            RoundedRectangle(cornerRadius: 2)
                .fill(selected ? Color.color3 : .clear)
                .frame(width: 4, height: selected ? 24 : 10)
            if let image {
                Image(image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
            }
            Text(label)
                .font(.custom("PCLEnglish", size: 14))
            if selected, hovered, let refresh {
                Spacer(minLength: 0)
                Image("IconRefresh")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 13)
                    .contentShape(.rect)
                    .onTapGesture {
                        if Date.now.timeIntervalSince(lastRefresh) > 0.5 {
                            lastRefresh = Date.now
                            refresh(route)
                        }
                    }
                    .padding(.trailing, 6)
            }
        }
        .frame(height: 32)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(hovered ? Color.color2.opacity(0.1) : .clear)
        .foregroundStyle(selected ? Color.color3 : .color1)
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
        .init(.launch, "LaunchPageIcon", "启动")
    )
    .frame(width: 150)
    .padding()
    .background(.white)
}
