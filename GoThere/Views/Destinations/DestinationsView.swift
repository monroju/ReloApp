import SwiftUI

struct DestinationsView: View {
    @EnvironmentObject var purchaseManager: PurchaseManager
    @StateObject private var vm = DestinationsViewModel()
    @State private var showPaywall = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ForEach(DestinationConfig.allDestinations) { dest in
                    let isUnlocked = purchaseManager.isCountryUnlocked(dest.id)

                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text(dest.flagEmoji)
                                .font(.largeTitle)
                            VStack(alignment: .leading) {
                                HStack {
                                    Text(dest.name)
                                        .font(.title2.bold())
                                    if !isUnlocked {
                                        Image(systemName: "lock.fill")
                                            .foregroundColor(.secondary)
                                    }
                                }
                                Text(dest.region)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            if vm.activeDestinationId == dest.id {
                                Text("Active")
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.goSuccess.opacity(0.2))
                                    .foregroundColor(.goSuccess)
                                    .cornerRadius(8)
                            }
                        }

                        Text(dest.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        // Visa tracks
                        Text("Visa Tracks")
                            .font(.caption.bold())
                            .foregroundColor(.secondary)

                        ForEach(dest.visaTracks) { track in
                            HStack(spacing: 8) {
                                Image(systemName: "doc.text")
                                    .foregroundColor(.goPrimary)
                                VStack(alignment: .leading) {
                                    Text(track.name)
                                        .font(.subheadline)
                                    if let time = track.estimatedProcessingTime {
                                        Text(time)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                Spacer()
                                if track.id == vm.activeVisaTrackId && dest.id == vm.activeDestinationId {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.goSuccess)
                                }
                            }
                            .padding(.vertical, 4)
                        }

                        if isUnlocked {
                            Button {
                                Task { await vm.selectDestination(dest.id) }
                            } label: {
                                Text(vm.activeDestinationId == dest.id ? "Currently Active" : "Select Destination")
                                    .font(.subheadline.bold())
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(vm.activeDestinationId == dest.id ? .goSuccess : .goPrimary)
                            .disabled(vm.activeDestinationId == dest.id)
                        } else {
                            Button {
                                showPaywall = true
                            } label: {
                                Label("Unlock \(dest.name)", systemImage: "lock.open.fill")
                                    .font(.subheadline.bold())
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.orange)
                        }
                    }
                    .goCard()
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Destinations")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
        .task {
            await vm.loadDestination()
        }
    }
}
