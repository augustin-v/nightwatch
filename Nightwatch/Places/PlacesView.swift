import SwiftUI
import AuroraCore

/// Saved spots: home, the cabin, the dark-sky site an hour up the road.
///
/// This screen is not a bookmark list, it is the app's location switch. Every
/// other screen forecasts for whatever is selected here, so selection state is
/// the loudest thing on each row and "Follow my location" is a first-class
/// entry rather than an absence of choice.
struct PlacesView: View {
    @AppStorage("nightVisionEnabled") private var nightVisionEnabled = false
    @State private var services = AppServices.shared
    @State private var showingAddSheet = false
    @State private var renaming: SavedPlace?

    private var mode: Nightwatch.Mode { nightVisionEnabled ? .nightVision : .night }
    private var palette: Nightwatch.Palette { .forMode(mode) }

    var body: some View {
        NavigationStack {
            list
                .background(palette.background.ignoresSafeArea())
                .navigationTitle(Text("places.title"))
                .toolbarBackground(palette.background, for: .navigationBar)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showingAddSheet = true
                        } label: {
                            Image(systemName: "plus")
                        }
                        .accessibilityLabel(Text("places.add.accessibilityLabel"))
                    }
                }
                .sheet(isPresented: $showingAddSheet) {
                    AddPlaceSheet(services: services)
                }
                .sheet(item: $renaming) { place in
                    RenamePlaceSheet(place: place, services: services)
                }
        }
        .nightwatchTheme(mode)
        .tint(Nightwatch.Palette.ctaGreen)
        .preferredColorScheme(.dark)
    }

    private var list: some View {
        ScrollView {
            VStack(spacing: Nightwatch.Space.s) {
                row(
                    title: Text("places.followMe"),
                    subtitle: services.location.currentCoordinate.map(Self.coordinateText),
                    symbol: "location.fill",
                    isSelected: services.selectedPlaceID == nil
                ) {
                    services.selectedPlaceID = nil
                }

                ForEach(services.places.places) { place in
                    row(
                        title: Text(verbatim: place.name),
                        subtitle: Self.coordinateText(place.coordinate),
                        symbol: "mappin",
                        isSelected: services.selectedPlaceID == place.id
                    ) {
                        services.selectedPlaceID = place.id
                    }
                    .contextMenu {
                        Button { renaming = place } label: {
                            Label { Text("places.rename") } icon: { Image(systemName: "pencil") }
                        }
                        Button(role: .destructive) {
                            if services.selectedPlaceID == place.id { services.selectedPlaceID = nil }
                            services.places.remove(id: place.id)
                        } label: {
                            Label { Text("places.delete") } icon: { Image(systemName: "trash") }
                        }
                    }
                }

                if services.places.places.isEmpty {
                    emptyPrompt
                }

                Text("places.footnote")
                    .font(Nightwatch.TypeScale.caption)
                    .foregroundStyle(palette.textTertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, Nightwatch.Space.m)
            }
            .padding(.horizontal, Nightwatch.Space.l)
            .padding(.bottom, Nightwatch.Space.xxl * 2)
        }
    }

    private func row(
        title: Text,
        subtitle: String?,
        symbol: String,
        isSelected: Bool,
        select: @escaping () -> Void
    ) -> some View {
        Button(action: select) {
            HStack(spacing: Nightwatch.Space.m) {
                Image(systemName: symbol)
                    .font(.body)
                    .frame(width: 22)
                    .foregroundStyle(isSelected ? Nightwatch.Palette.ctaGreen : palette.textTertiary)

                VStack(alignment: .leading, spacing: 2) {
                    title
                        .font(isSelected ? Nightwatch.TypeScale.emphasis : Nightwatch.TypeScale.body)
                        .foregroundStyle(palette.textPrimary)
                    if let subtitle {
                        Text(verbatim: subtitle)
                            .font(Nightwatch.TypeScale.caption)
                            .monospacedDigit()
                            .foregroundStyle(palette.textTertiary)
                    }
                }

                Spacer(minLength: Nightwatch.Space.s)

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Nightwatch.Palette.ctaGreen)
                }
            }
            .padding(Nightwatch.Space.m)
            .background(
                RoundedRectangle(cornerRadius: Nightwatch.Radius.chip)
                    .fill(palette.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: Nightwatch.Radius.chip)
                            .strokeBorder(
                                isSelected ? Nightwatch.Palette.ctaGreen.opacity(0.5) : .clear,
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    /// With nothing saved yet, the list is one row and a lot of nothing, and
    /// the only way to add a place is a small glyph in the corner. This makes
    /// the primary action the size of the intent behind it.
    private var emptyPrompt: some View {
        VStack(spacing: Nightwatch.Space.m) {
            Text("places.empty.title")
                .font(Nightwatch.TypeScale.title)
                .foregroundStyle(palette.textPrimary)
                .multilineTextAlignment(.center)

            Text("places.empty.message")
                .font(Nightwatch.TypeScale.body)
                .foregroundStyle(palette.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Button {
                showingAddSheet = true
            } label: {
                Text("places.empty.action")
                    .font(Nightwatch.TypeScale.emphasis)
                    .padding(.horizontal, Nightwatch.Space.l)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .buttonBorderShape(.roundedRectangle(radius: Nightwatch.Radius.chip))
            .padding(.top, Nightwatch.Space.xs)
            .disabled(services.location.currentCoordinate == nil)
        }
        .padding(.vertical, Nightwatch.Space.xxl)
        .padding(.horizontal, Nightwatch.Space.m)
        .frame(maxWidth: .infinity)
    }

    /// Coordinates are shown to two decimals: enough to tell two saved spots
    /// apart, not so much that the row turns into a wall of digits.
    static func coordinateText(_ coordinate: GeoCoordinate) -> String {
        String(
            format: String(localized: "places.coordinate"),
            coordinate.latitude.formatted(.number.precision(.fractionLength(2))),
            coordinate.longitude.formatted(.number.precision(.fractionLength(2)))
        )
    }
}

/// Adding a place means naming where you already are. There is no map picker
/// and no search: the spots that matter are ones you physically stand in, and
/// a geocoding search field would be a third-party dependency and a privacy
/// surface for a job the device already does.
private struct AddPlaceSheet: View {
    let services: AppServices

    @Environment(\.dismiss) private var dismiss
    @Environment(\.palette) private var palette
    @State private var name = ""
    @FocusState private var nameFieldFocused: Bool

    private var coordinate: GeoCoordinate? { services.location.currentCoordinate }

    var body: some View {
        NightSurface(intensity: 0.4) {
            NavigationStack {
                VStack(alignment: .leading, spacing: Nightwatch.Space.l) {
                    Text("places.add.prompt")
                        .font(Nightwatch.TypeScale.body)
                        .foregroundStyle(palette.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)

                    TextField(text: $name) {
                        Text("places.add.namePlaceholder")
                    }
                    .textFieldStyle(.plain)
                    // Place names are proper nouns, often local ones. Left to
                    // autocorrect, "Kvaloya" is silently saved as "Jealous".
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.words)
                    .submitLabel(.done)
                    .focused($nameFieldFocused)
                    .font(Nightwatch.TypeScale.title)
                    .foregroundStyle(palette.textPrimary)
                    .padding(Nightwatch.Space.m)
                    .background(palette.surface, in: RoundedRectangle(cornerRadius: Nightwatch.Radius.chip))

                    if let coordinate {
                        Text(verbatim: PlacesView.coordinateText(coordinate))
                            .font(Nightwatch.TypeScale.caption)
                            .monospacedDigit()
                            .foregroundStyle(palette.textTertiary)
                    } else {
                        Text("places.add.noLocation")
                            .font(Nightwatch.TypeScale.caption)
                            .foregroundStyle(palette.warning)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer()
                }
                .padding(Nightwatch.Space.l)
                .frame(maxWidth: .infinity, alignment: .leading)
                .navigationTitle(Text("places.add.title"))
                .task { nameFieldFocused = true }
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button { dismiss() } label: { Text("common.cancel") }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button {
                            guard let coordinate else { return }
                            let place = SavedPlace(name: trimmedName, coordinate: coordinate)
                            services.places.add(place)
                            services.selectedPlaceID = place.id
                            dismiss()
                        } label: {
                            Text("common.save")
                        }
                        .disabled(coordinate == nil || trimmedName.isEmpty)
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private struct RenamePlaceSheet: View {
    let place: SavedPlace
    let services: AppServices

    @Environment(\.dismiss) private var dismiss
    @Environment(\.palette) private var palette
    @State private var name: String
    @FocusState private var nameFieldFocused: Bool

    init(place: SavedPlace, services: AppServices) {
        self.place = place
        self.services = services
        _name = State(initialValue: place.name)
    }

    var body: some View {
        NightSurface(intensity: 0.4) {
            NavigationStack {
                VStack(alignment: .leading, spacing: Nightwatch.Space.l) {
                    TextField(text: $name) {
                        Text("places.add.namePlaceholder")
                    }
                    .textFieldStyle(.plain)
                    // Place names are proper nouns, often local ones. Left to
                    // autocorrect, "Kvaloya" is silently saved as "Jealous".
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.words)
                    .submitLabel(.done)
                    .focused($nameFieldFocused)
                    .font(Nightwatch.TypeScale.title)
                    .foregroundStyle(palette.textPrimary)
                    .padding(Nightwatch.Space.m)
                    .background(palette.surface, in: RoundedRectangle(cornerRadius: Nightwatch.Radius.chip))

                    Spacer()
                }
                .padding(Nightwatch.Space.l)
                .navigationTitle(Text("places.rename"))
                .task { nameFieldFocused = true }
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button { dismiss() } label: { Text("common.cancel") }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button {
                            let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                            if !trimmed.isEmpty { services.places.rename(id: place.id, to: trimmed) }
                            dismiss()
                        } label: {
                            Text("common.save")
                        }
                    }
                }
            }
        }
        .presentationDetents([.height(220)])
    }
}
