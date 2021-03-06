import SwiftUI
import Specs

struct Search: View {
    @StateObject var field: Field
    let focus: Bool
    @State private var items = [[Website]]()
    @State private var settings = false
    @AppStorage(Defaults.premium.rawValue) private var premium = false
    
    var body: some View {
        ScrollView {
            field
                .equatable()
                .frame(height: 1)
            
            if field.session.froob && !premium && !field.typing {
                Froob()
            }
            
            if items.first?.isEmpty == false {
                HStack(alignment: .top, spacing: 9) {
                    ForEach(0 ..< items.count, id: \.self) { index in
                        LazyVStack {
                            ForEach(items[index]) {
                                Item(field: field, website: $0)
                            }
                        }
                    }
                }
                .padding(.horizontal, 9)
                .padding(.top)
                .padding(.bottom, 40)
            } else {
                Label("No bookmarks or history", systemImage: "clock")
                    .font(.callout)
                    .imageScale(.large)
                    .foregroundStyle(.secondary)
                    .padding([.top, .leading], 30)
                    .frame(maxWidth: .greatestFiniteMagnitude, alignment: .leading)
            }
        }
        .frame(maxWidth: .greatestFiniteMagnitude)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Bar(items: [
                .init(size: 17, icon: "line.3.horizontal") {
                    field.cancel(clear: false)
                    settings = true
                },
                field.typing ? .init(size: 15, icon: "xmark") {
                    field.cancel(clear: true)
                } : .init(size: 20, icon: "magnifyingglass") {
                    field.becomeFirstResponder()
                },
                .init(size: 16, icon: "square.on.square") {
                    field.cancel(clear: false)
                    
                    Task {
                        await field.session.items[field.index].web?.thumbnail()
                        field.session.previous = field.index
                        withAnimation(.easeInOut(duration: 0.4)) {
                            field.session.current = nil
                        }
                    }
                }
            ],
                material: field.typing ? .regular : .ultraThin)
            .animation(.easeInOut(duration: 0.6), value: field.typing)
            .sheet(isPresented: $settings, content: Settings.init)
        }
        .transition(.move(edge: .bottom))
        .onChange(of: field.websites, perform: update(websites:))
        .onAppear {
            update(websites: field.websites)
            if focus {
                field.becomeFirstResponder()
                
                if field.session.items[field.index].web == nil {
                    field.session.items[field.index].flow = .search(false)
                }
            }
        }
    }
    
    private func update(websites: [Website]) {
        let items: [[Website]] = websites
            .reduce(into: .init(repeating: .init(), count: 2)) {
                if $0[0].count > $0[1].count {
                    $0[1].append($1)
                } else {
                    $0[0].append($1)
                }
            }
        guard items != self.items else { return }
        self.items = items
    }
}
