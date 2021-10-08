import SwiftUI
import Specs

struct Activity: View {
    @State private var date: Date?
    @State private var stats: Events.Stats?
    @State private var prevented = 0
    
    var body: some View {
        List {
            if let stats = stats {
                Section {
                    VStack {
                        Timeline(values: stats.timeline)
                            .frame(height: 180)
                        if let date = date {
                            HStack {
                                Text(verbatim: date.formatted(.relative(presentation: .named, unitsStyle: .wide)))
                                Spacer()
                                Text("Now")
                            }
                            .foregroundStyle(.tertiary)
                            .font(.caption)
                            .padding(.horizontal, 7)
                        }
                    }
                    .allowsHitTesting(false)
                    .padding()
                    .modifier(Card())
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                
                Section("Events") {
                    VStack(alignment: .leading) {
                        Text(stats.websites, format: .number)
                            .font(.title3)
                            .foregroundStyle(.primary)
                        Text("Total events")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .greatestFiniteMagnitude, alignment: .leading)
                    
                    VStack(alignment: .leading) {
                        Text(prevented, format: .number)
                            .font(.title3)
                            .foregroundStyle(.primary)
                        Text("Trackers prevented")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .greatestFiniteMagnitude, alignment: .leading)
                }
                .listRowBackground(Color.clear)
                
                if let domains = stats.domains {
                    Section("Websites") {
                        VStack(alignment: .leading) {
                            Text(domains.count, format: .number)
                                .font(.title3)
                                .foregroundStyle(.primary)
                            Text("Total websites")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .greatestFiniteMagnitude, alignment: .leading)
                        
                        VStack(alignment: .leading) {
                            Text(verbatim: domains.top)
                                .font(.title3)
                                .foregroundStyle(.primary)
                            Text("Most visited")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .greatestFiniteMagnitude, alignment: .leading)
                    }
                    .listRowBackground(Color.clear)
                }
                
                if let trackers = stats.trackers {
                    Section("Trackers") {
                        VStack(alignment: .leading) {
                            Text(trackers.count, format: .number)
                                .font(.title3)
                                .foregroundStyle(.primary)
                            Text("Total trackers")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .greatestFiniteMagnitude, alignment: .leading)
                        
                        VStack(alignment: .leading) {
                            Text(verbatim: trackers.top)
                                .font(.title3)
                                .foregroundStyle(.primary)
                            Text("Most prevented")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .greatestFiniteMagnitude, alignment: .leading)
                    }
                    .listRowBackground(Color.clear)
                }
            }
        }
        .listStyle(.grouped)
        .navigationTitle("Activity")
        .navigationBarTitleDisplayMode(.large)
        .onReceive(cloud) {
            date = $0.events.since
            prevented = $0.events.prevented
            stats = $0.events.stats
        }
    }
}
