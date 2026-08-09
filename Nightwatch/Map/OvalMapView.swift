import SwiftUI
import MapKit
import AuroraCore

/// Where the auroral oval actually sits tonight, and where you are relative
/// to it.
///
/// The obvious build is a blurry probability heatmap over the pole. It looks
/// impressive in a screenshot and tells you almost nothing at the zoom level
/// a phone map is actually used at: a soft green smear does not answer "do I
/// need to drive north, and how far?" So the drawing is the *edge* of the
/// oval, computed from tonight's peak Kp, plus one sentence putting a number
/// on your distance from it. The overlay is the answer, not decoration.
struct OvalMapView: View {
    let appState: AppState

    @AppStorage("nightVisionEnabled") private var nightVisionEnabled = false
    @State private var model = OvalMapModel()
    @State private var services = AppServices.shared
    @State private var showingPaywall = false
    @State private var camera: MapCameraPosition = .automatic

    private var mode: Nightwatch.Mode { nightVisionEnabled ? .nightVision : .night }
    private var palette: Nightwatch.Palette { .forMode(mode) }

    var body: some View {
        NavigationStack {
            content
                .background(palette.background.ignoresSafeArea())
                .navigationTitle(Text("map.title"))
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(palette.background, for: .navigationBar)
        }
        .nightwatchTheme(mode)
        .tint(Nightwatch.Palette.ctaGreen)
        .preferredColorScheme(.dark)
        .premiumSheet(isPresented: $showingPaywall, appState: appState)
        .task(id: ForecastTrigger(placeID: services.selectedPlaceID, isPremium: appState.isPremium)) {
            if appState.isPremium { await model.syncToActiveLocation() }
        }
    }

    @ViewBuilder
    private var content: some View {
        if !appState.isPremium {
            LockedFeature(
                symbol: "globe.europe.africa",
                title: "map.locked.title",
                promise: "map.locked.promise",
                specifics: [
                    "map.locked.specific.edge",
                    "map.locked.specific.distance",
                    "map.locked.specific.tonight"
                ],
                onUnlock: { showingPaywall = true }
            )
        } else if let reading = model.reading {
            ZStack(alignment: .top) {
                map(for: reading)
                distanceCard(reading)
                    .padding(.horizontal, Nightwatch.Space.l)
                    .padding(.top, Nightwatch.Space.s)
            }
        } else {
            ProgressView()
                .controlSize(.large)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func map(for reading: OvalReading) -> some View {
        Map(position: $camera) {
            // The band between the oval edge and the pole, so the map reads
            // as "aurora is up there" at a glance before any line is traced.
            MapPolygon(coordinates: reading.polewardRegion)
                .foregroundStyle(palette.ramp[3].opacity(0.08))
                .stroke(.clear, lineWidth: 0)

            // The edge carries the information, so it is the only strong
            // mark on the map. The wash behind it just says which side of the
            // line you want to be on.
            MapPolyline(coordinates: reading.ovalEdge)
                .stroke(palette.ramp[3], lineWidth: 3)

            Annotation(
                String(localized: "map.youAreHere"),
                coordinate: reading.userLocation
            ) {
                Circle()
                    .fill(Nightwatch.Palette.ctaGreen)
                    .frame(width: 14, height: 14)
                    .overlay(Circle().strokeBorder(.white.opacity(0.9), lineWidth: 2))
            }
        }
        .mapStyle(.standard(elevation: .flat, pointsOfInterest: .excludingAll))
        .onAppear {
            camera = .region(
                MKCoordinateRegion(
                    center: reading.userLocation,
                    span: MKCoordinateSpan(latitudeDelta: 34, longitudeDelta: 44)
                )
            )
        }
        .ignoresSafeArea(edges: .bottom)
    }

    /// The number the screen exists to produce. Floating over the map rather
    /// than pushed above it, because the relationship between the sentence and
    /// the line it describes is the whole point.
    private func distanceCard(_ reading: OvalReading) -> some View {
        VStack(alignment: .leading, spacing: Nightwatch.Space.xs) {
            Text(verbatim: reading.headline)
                .font(Nightwatch.TypeScale.emphasis)
                .foregroundStyle(palette.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Text(verbatim: reading.subline)
                .font(Nightwatch.TypeScale.caption)
                .foregroundStyle(palette.textSecondary)
        }
        .padding(Nightwatch.Space.m)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: Nightwatch.Radius.chip))
        .overlay(
            RoundedRectangle(cornerRadius: Nightwatch.Radius.chip)
                .strokeBorder(palette.hairline, lineWidth: 1)
        )
    }
}

/// Everything the map screen draws, computed once off the night's forecast.
struct OvalReading: Equatable {
    let userLocation: CLLocationCoordinate2D
    let ovalEdge: [CLLocationCoordinate2D]
    let polewardRegion: [CLLocationCoordinate2D]
    let peakKp: Double
    let peakScore: Double
    let headline: String
    let subline: String

    static func == (lhs: OvalReading, rhs: OvalReading) -> Bool {
        lhs.peakKp == rhs.peakKp
            && lhs.peakScore == rhs.peakScore
            && lhs.userLocation.latitude == rhs.userLocation.latitude
            && lhs.userLocation.longitude == rhs.userLocation.longitude
    }
}

@MainActor
@Observable
final class OvalMapModel {
    private(set) var reading: OvalReading?

    private let services: AppServices
    private var hasStarted = false
    private var loadedCoordinate: GeoCoordinate?

    init(services: AppServices = .shared) {
        self.services = services
    }

    func start() async {
        guard !hasStarted else { return }
        hasStarted = true
        await load()
    }

    func syncToActiveLocation() async {
        guard hasStarted else { return await start() }
        guard services.activeCoordinate != loadedCoordinate else { return }
        reading = nil
        await load()
    }

    private func load() async {
        guard let coordinate = services.activeCoordinate else { return }
        loadedCoordinate = coordinate
        let report = await services.forecastService.refreshTonight(at: coordinate)
        reading = Self.makeReading(report: report, at: coordinate)
    }

    /// Traces the oval edge by solving, meridian by meridian, for the
    /// geographic latitude whose *geomagnetic* latitude equals tonight's
    /// boundary. Geomagnetic latitude increases monotonically with geographic
    /// latitude along a meridian, so a short bisection is exact enough at map
    /// resolution and avoids shipping a lookup table that would go stale as
    /// the pole drifts.
    static func makeReading(
        report: NightForecastReport,
        at coordinate: GeoCoordinate
    ) -> OvalReading {
        let peakKp = report.readings.map(\.forecastKp).max() ?? 0
        let peakScore = report.verdict.hourly.map(\.combined).max() ?? 0
        let boundary = GeomagneticLatitude.kpOvalBoundary(kp: peakKp)

        var edge: [CLLocationCoordinate2D] = []
        for step in stride(from: -180.0, through: 180.0, by: 3.0) {
            let latitude = geographicLatitude(forGeomagnetic: boundary, longitude: step)
            edge.append(CLLocationCoordinate2D(latitude: latitude, longitude: step))
        }

        // Closing the band along 89° rather than the pole itself: a polygon
        // vertex exactly at 90° projects to a degenerate point and MapKit
        // draws a visible notch there.
        var region = edge
        region.append(contentsOf: stride(from: 180.0, through: -180.0, by: -3.0)
            .map { CLLocationCoordinate2D(latitude: 89, longitude: $0) })

        let boundaryHere = geographicLatitude(forGeomagnetic: boundary, longitude: coordinate.longitude)
        let degreesAway = boundaryHere - coordinate.latitude
        let kilometres = abs(degreesAway) * 111.19

        let distance = Measurement(value: kilometres, unit: UnitLength.kilometers)
            .formatted(.measurement(width: .abbreviated, usage: .road))
        let headlineKey: String.LocalizationValue = degreesAway <= 0
            ? "map.headline.inside"
            : "map.headline.northOfYou"

        return OvalReading(
            userLocation: CLLocationCoordinate2D(
                latitude: coordinate.latitude,
                longitude: coordinate.longitude
            ),
            ovalEdge: edge,
            polewardRegion: region,
            peakKp: peakKp,
            peakScore: peakScore,
            headline: String(format: String(localized: headlineKey), distance),
            subline: String(
                format: String(localized: "map.subline.kp"),
                peakKp.formatted(.number.precision(.fractionLength(0...1)))
            )
        )
    }

    private static func geographicLatitude(
        forGeomagnetic target: Double,
        longitude: Double
    ) -> Double {
        var low = 20.0
        var high = 89.0
        for _ in 0..<24 {
            let mid = (low + high) / 2
            let value = GeomagneticLatitude.geomagneticLatitude(latitude: mid, longitude: longitude)
            if value < target {
                low = mid
            } else {
                high = mid
            }
        }
        return (low + high) / 2
    }
}
