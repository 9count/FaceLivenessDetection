//
//  NavigationWrapper.swift
//  WinkService
//
//  Created by 鍾哲玄 on 2024/7/24.
//

import SwiftUI
// https://developer.apple.com/documentation/swiftui/migrating-to-new-navigation-types
public struct NavigationViewStackWrapper<Root>: View where Root: View {
    private let content: Root

    public init(@ViewBuilder content: @escaping () -> Root) {
        self.content = content()
    }

    public var body: some View {
        if #available(iOS 16, *) {
            NavigationStack { content }
        } else {
            NavigationView { content }
        }
    }
}

public extension View {
    typealias Iterable = Hashable & CaseIterable
    @ViewBuilder
    func navigationDestinationWrapper<D, C>(
        for data: D.Type,
        isActive: Binding<D?>,
        @ViewBuilder destination: @escaping (D) -> C
    ) -> some View where D: Iterable, D.AllCases: RandomAccessCollection, C: View {
        if #available(iOS 16, *) {
            self.navigationDestination(for: data, destination: destination)
        } else {
            ZStack {
                ForEach(data.allCases, id: \.self) { type in
                    NavigationLink(
                        isActive: Binding(
                        get: { isActive.wrappedValue == type },
                        set: { newValue in
                            if newValue {
                                isActive.wrappedValue = type
                            } else if isActive.wrappedValue == type {
                                isActive.wrappedValue = nil
                            }
                        })
                    ) {
                        destination(type)
                    } label: {
                        EmptyView()
                    }
                }

                self
            }
        }
    }

    @ViewBuilder
    func navigationDestinationWrapper<V: View>(
        isPresented: Binding<Bool>,
        @ViewBuilder destination: () -> V
    ) -> some View where V: View {
        if #available(iOS 16, *) {
            self.navigationDestination(isPresented: isPresented, destination: destination)
        } else {
            ZStack {
                NavigationLink(isActive: isPresented, destination: destination, label: {
                    EmptyView()
                })
                self
            }
        }
    }
}
