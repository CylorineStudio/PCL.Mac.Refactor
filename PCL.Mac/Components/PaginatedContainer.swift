//
//  PaginatedContainer.swift
//  PCL.Mac
//
//  Created by AnemoFlower on 2026/3/19.
//

import SwiftUI

struct PaginatedContainer<Content: View>: View {
    @Binding private var currentPage: Int
    @State private var disableAppearAnimation: Bool = false
    private let pageCount: Int
    private let content: (Int) -> Content
    
    init(currentPage: Binding<Int>, pageCount: Int, content: @escaping (Int) -> Content) {
        self._currentPage = currentPage
        self.pageCount = pageCount
        self.content = content
    }
    
    init<Data: RandomAccessCollection, ID: Hashable, ElementContent: View>(
        _ data: Data,
        id: KeyPath<Data.Element, ID>,
        currentPage: Binding<Int>,
        viewsPerPage: Int,
        content: @escaping (Data.Element) -> ElementContent
    ) where Content == AnyView {
        self._currentPage = currentPage
        self.pageCount = Int(ceil(Double(data.count) / Double(viewsPerPage)))
        self.content = { currentPage in
            AnyView(
                ForEach(data.dropFirst(currentPage * viewsPerPage).prefix(viewsPerPage), id: id) { element in
                    content(element)
                }
            )
        }
    }
    
    var body: some View {
        VStack(spacing: 15) {
            content(currentPage)
                .disableCardAppearAnimation(disableAppearAnimation)
                .animation(.easeInOut(duration: 0.2), value: currentPage)
            
            MyCard("", titled: false, padding: 8) {
                HStack(alignment: .center, spacing: 0) {
                    pageButton(.btnFirstPage) {
                        currentPage = 0
                    }
                    .opacity(currentPage == 0 ? 0.2 : 1)
                    pageButton(.btnPrevPage) {
                        if currentPage > 0 {
                            currentPage -= 1
                        }
                    }
                    .opacity(currentPage == 0 ? 0.2 : 1)
                    
                    MyText((currentPage + 1).description, size: 16, color: .colorGray2)
                        .padding(.horizontal, 8)
                    
                    pageButton(.btnNextPage) {
                        if currentPage < pageCount - 1 {
                            currentPage += 1
                        }
                    }
                    .opacity(currentPage == pageCount - 1 ? 0.2 : 1)
                }
                .foregroundStyle(Color.colorGray2)
                .frame(height: 23)
            }
            .fixedSize()
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                disableAppearAnimation = true
            }
        }
    }
    
    @ViewBuilder
    private func pageButton(_ icon: ImageResource, onClick: @escaping () -> Void) -> some View {
        Image(icon)
            .resizable()
            .scaledToFit()
            .frame(width: 23, height: 23)
            .contentShape(.rect)
            .onTapGesture(perform: onClick)
    }
}
