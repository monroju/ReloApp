import SwiftUI
import MapKit

struct CityMapView: View {
    let cityId: String
    let countryId: String

    @State private var cityData: CityPoiData?
    @State private var activeCategories: Set<String> = Set(PoiCategory.allCases.map(\.rawValue))
    @State private var selectedPoi: Poi?
    @State private var cameraPosition: MapCameraPosition = .automatic

    var body: some View {
        ZStack(alignment: .top) {
            if let data = cityData {
                mapContent(data)
            } else {
                ProgressView("Loading map data...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle(cityDisplayName)
        .navigationBarTitleDisplayMode(.inline)
        .task { loadData() }
    }

    @ViewBuilder
    private func mapContent(_ data: CityPoiData) -> some View {
        let filteredPois = data.pois.filter { activeCategories.contains($0.category) }

        ZStack(alignment: .bottom) {
            Map(position: $cameraPosition, selection: $selectedPoi) {
                ForEach(filteredPois) { poi in
                    let cat = PoiCategory.from(poi.category)
                    Annotation(poi.name, coordinate: CLLocationCoordinate2D(latitude: poi.lat, longitude: poi.lng)) {
                        Image(systemName: cat?.systemImage ?? "mappin")
                            .font(.caption)
                            .foregroundColor(.white)
                            .frame(width: 28, height: 28)
                            .background(cat?.color ?? .gray)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(.white, lineWidth: 2))
                    }
                    .tag(poi)
                }
            }
            .mapControls {
                MapCompass()
                MapScaleView()
                MapUserLocationButton()
            }

            VStack(spacing: 0) {
                // Category filter chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(PoiCategory.allCases) { cat in
                            let count = data.pois.count { $0.category == cat.rawValue }
                            if count > 0 {
                                let isActive = activeCategories.contains(cat.rawValue)
                                Button {
                                    if isActive {
                                        activeCategories.remove(cat.rawValue)
                                    } else {
                                        activeCategories.insert(cat.rawValue)
                                    }
                                } label: {
                                    Text("\(cat.label) (\(count))")
                                        .font(.caption2)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(isActive ? cat.color : Color.secondary.opacity(0.2))
                                        .foregroundColor(isActive ? .white : .primary)
                                        .cornerRadius(14)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                }
                .background(.ultraThinMaterial)

                Spacer()

                // Detail card
                if let poi = selectedPoi {
                    poiDetailCard(poi)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                // Count badge
                if selectedPoi == nil {
                    HStack {
                        Text("\(filteredPois.count) places")
                            .font(.caption2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.ultraThinMaterial)
                            .cornerRadius(8)
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.bottom, 8)
                }
            }
        }
    }

    private func poiDetailCard(_ poi: Poi) -> some View {
        let cat = PoiCategory.from(poi.category)
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(poi.name)
                        .font(.headline)
                    if let cat {
                        Text(cat.label)
                            .font(.caption)
                            .foregroundColor(cat.color)
                    }
                }
                Spacer()
                Button { selectedPoi = nil } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }

            if let addr = poi.address, !addr.isEmpty {
                Text(addr)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if let notes = poi.notes, !notes.isEmpty {
                Text(notes)
                    .font(.caption)
                    .foregroundColor(.goPrimary)
            }

            HStack(spacing: 8) {
                if let phone = poi.phone, !phone.isEmpty, let url = URL(string: "tel:\(phone)") {
                    Link(destination: url) {
                        Label("Call", systemImage: "phone")
                            .font(.caption)
                    }
                    .buttonStyle(.bordered)
                }
                if let web = poi.website, !web.isEmpty, let url = URL(string: web) {
                    Link(destination: url) {
                        Label("Website", systemImage: "globe")
                            .font(.caption)
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .padding(16)
        .background(.regularMaterial)
        .cornerRadius(16)
        .shadow(radius: 4)
        .padding(12)
    }

    private func loadData() {
        guard let data = PoiRepository.shared.loadCity(cityId) else { return }
        cityData = data
        cameraPosition = .region(MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: data.centerLat, longitude: data.centerLng),
            latitudinalMeters: Double(data.defaultZoom) * 500,
            longitudinalMeters: Double(data.defaultZoom) * 500
        ))
    }

    private var cityDisplayName: String {
        let names: [String: String] = [
            "madrid": "Madrid", "barcelona": "Barcelona", "valencia": "Valencia",
            "malaga": "Malaga", "marbella": "Marbella", "seville": "Sevilla",
            "granada": "Granada", "alicante": "Alicante", "bilbao": "Bilbao",
            "sansebastian": "San Sebastian", "palma": "Palma de Mallorca",
            "tenerife": "Tenerife", "vitoria": "Vitoria-Gasteiz", "coruna": "A Coruna",
            "santander": "Santander", "zaragoza": "Zaragoza",
            "lisbon": "Lisbon", "porto": "Porto", "cascais": "Cascais",
            "sintra": "Sintra", "faro": "Faro", "lagos": "Lagos",
            "albufeira": "Albufeira", "coimbra": "Coimbra", "braga": "Braga",
            "funchal": "Funchal", "setubal": "Setubal", "aveiro": "Aveiro",
            "evora": "Evora", "tavira": "Tavira", "ericeira": "Ericeira",
            "mexico_city": "Mexico City", "guadalajara": "Guadalajara",
            "monterrey": "Monterrey", "merida": "Merida",
            "playa_del_carmen": "Playa del Carmen", "cancun": "Cancun",
            "puerto_vallarta": "Puerto Vallarta", "oaxaca": "Oaxaca",
            "san_miguel": "San Miguel de Allende", "queretaro": "Queretaro",
            "puebla": "Puebla", "guanajuato": "Guanajuato", "tulum": "Tulum",
            "los_cabos": "Los Cabos", "tijuana": "Tijuana", "leon": "Leon",
        ]
        return names[cityId] ?? cityId.capitalized
    }
}

// Make Poi conform to Hashable for Map selection
extension Poi: Hashable {
    static func == (lhs: Poi, rhs: Poi) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
