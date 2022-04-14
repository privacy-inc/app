//import SwiftUI
//import StoreKit
//import Specs
//
//struct Plus: View {
//    @State private var state = Store.Status.loading
//    
//    var body: some View {
//        List {
//            Section {
//                HStack {
//                    Spacer()
//                    Banner()
//                        .equatable()
//                        .frame(width: 250, height: 250)
//                    Spacer()
//                }
//            }
//            .listRowSeparator(.hidden)
//            .listSectionSeparator(.hidden)
//            .listRowBackground(Color.clear)
//            .allowsHitTesting(false)
//            
//            title
//            
//            if Defaults.isPremium {
//                isPremium
//            } else {
//                notPremium
//            }
//            
//            disclaimer
//        }
//        .listStyle(.insetGrouped)
//        .symbolRenderingMode(.hierarchical)
//        .animation(.easeInOut(duration: 0.3), value: state)
//        .navigationBarTitleDisplayMode(.inline)
//        .onReceive(store.status) {
//            state = $0
//        }
//        .task {
//            await store.load()
//        }
//    }
//    
//    private var title: some View {
//        Section {
//            Text("\(Text("Privacy").font(.title.weight(.medium))) \(Image(systemName: "plus"))")
//                .foregroundColor(.primary)
//                .font(.largeTitle.weight(.ultraLight))
//                .imageScale(.large)
//                .frame(maxWidth: .greatestFiniteMagnitude)
//        }
//        .listRowSeparator(.hidden)
//        .listSectionSeparator(.hidden)
//        .listRowBackground(Color.clear)
//        .allowsHitTesting(false)
//    }
//    
//    private var isPremium: some View {
//        Section {
//            Image(systemName: "checkmark.circle.fill")
//                .font(.largeTitle)
//                .symbolRenderingMode(.multicolor)
//                .frame(maxWidth: .greatestFiniteMagnitude)
//                
//            Group {
//                Text("We received your support\n")
//                    .foregroundColor(.secondary)
//                + Text("Thank you!")
//                    .foregroundColor(.primary)
//            }
//            .font(.footnote)
//            .multilineTextAlignment(.center)
//            .fixedSize(horizontal: false, vertical: true)
//            .frame(maxWidth: .greatestFiniteMagnitude)
//            .padding(.bottom)
//        }
//        .listRowSeparator(.hidden)
//        .listSectionSeparator(.hidden)
//        .listRowBackground(Color.clear)
//        .allowsHitTesting(false)
//    }
//    
//    @ViewBuilder private var notPremium: some View {
//        Section {
//            switch state {
//            case .loading:
//                Image(systemName: "hourglass")
//                    .font(.largeTitle.weight(.light))
//                    .symbolRenderingMode(.multicolor)
//                    .frame(maxWidth: .greatestFiniteMagnitude)
//                    .allowsHitTesting(false)
//            case let .error(error):
//                Text(verbatim: error)
//                    .foregroundColor(.secondary)
//                    .fixedSize(horizontal: false, vertical: true)
//                    .padding()
//                    .allowsHitTesting(false)
//            case let .products(products):
//                item(product: products.first!)
//            }
//        }
//        .listRowSeparator(.hidden)
//        .listSectionSeparator(.hidden)
//        .listRowBackground(Color.clear)
//        
//        Section("Already supporting Privacy?") {
//            Button {
//                Task {
//                    await store.restore()
//                }
//            } label: {
//                HStack {
//                    Text("Restore purchases")
//                    Spacer()
//                    Image(systemName: "leaf.arrow.triangle.circlepath")
//                }
//                .allowsHitTesting(false)
//            }
//        }
//        .font(.footnote)
//    }
//    
//    private var disclaimer: some View {
//        Section {
//            NavigationLink(destination: Info(title: "Why Purchases", text: Copy.why)) {
//                Label("Why In-App Purchases", systemImage: "questionmark.app.dashed")
//                    .allowsHitTesting(false)
//            }
//            NavigationLink(destination: Info(title: "Alternatives", text: Copy.alternatives)) {
//                Label("Alternatives", systemImage: "arrow.triangle.branch")
//                    .allowsHitTesting(false)
//            }
//        }
//        .font(.footnote)
//    }
//    
//    private func item(product: Product) -> some View {
//        VStack {
//            Text(verbatim: product.description)
//                .foregroundColor(.secondary)
//                .font(.callout)
//                .multilineTextAlignment(.center)
//                .fixedSize(horizontal: false, vertical: true)
//                .frame(maxWidth: 240)
//                .padding(.bottom)
//                .allowsHitTesting(false)
//            Text(verbatim: product.displayPrice)
//                .font(.body.monospacedDigit())
//                .padding(.top)
//                .frame(maxWidth: .greatestFiniteMagnitude)
//                .allowsHitTesting(false)
//            Button {
//                Task {
//                    await store.purchase(product)
//                }
//            } label: {
//                Text("Purchase")
//                    .font(.callout)
//                    .padding(.horizontal, 8)
//                    .padding(.vertical, 2)
//                    .allowsHitTesting(false)
//            }
//            .buttonStyle(.borderedProminent)
//            .buttonBorderShape(.capsule)
//            .tint(.blue)
//            .padding(.bottom)
//        }
//        .frame(maxWidth: .greatestFiniteMagnitude)
//    }
//}
