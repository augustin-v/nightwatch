import Foundation

/// A centered-dipole approximation of geomagnetic latitude, used by
/// `VisibilityEngine` so that a mid-latitude viewer needs a much higher Kp
/// than a Tromsø-class viewer for the same activity score.
public enum GeomagneticLatitude {
    /// Geographic coordinates of the north geomagnetic pole used for the
    /// centered-dipole approximation, degrees. This is the commonly cited
    /// recent-epoch value (~80.7°N, 72.7°W); the pole drifts a fraction of a
    /// degree per year, which is negligible against the ±2.2°/Kp resolution
    /// of the oval-boundary approximation this feeds (`kpOvalBoundary`
    /// below), so it is treated as a constant rather than epoch-corrected.
    static let poleLatitude = 80.65
    static let poleLongitude = -72.68

    /// Geomagnetic latitude (degrees, signed, matching hemisphere) for a
    /// geographic latitude/longitude, via the standard centered-dipole
    /// formula:
    ///
    ///   sin(φ_m) = sin(φ)sin(φ_p) + cos(φ)cos(φ_p)cos(λ - λ_p)
    ///
    /// where (φ_p, λ_p) is the geomagnetic pole above. This intentionally
    /// ignores the dipole's ~500 km offset from Earth's center (the "eccentric
    /// dipole" correction) — the centered-dipole term is the dominant one and
    /// is well within the accuracy this product needs to separate "under the
    /// oval" from "not under the oval".
    public static func geomagneticLatitude(latitude: Double, longitude: Double) -> Double {
        let deltaLon = longitude - poleLongitude
        let sinPhiM = AstroMath.sinD(latitude) * AstroMath.sinD(poleLatitude)
            + AstroMath.cosD(latitude) * AstroMath.cosD(poleLatitude) * AstroMath.cosD(deltaLon)
        return AstroMath.asinD(sinPhiM)
    }

    /// Approximate equatorward geomagnetic-latitude boundary of the auroral
    /// oval for a given planetary Kp index, in degrees, using the widely
    /// cited simplified relation `boundary ≈ 66.5° - 2.2° × Kp` (a linear fit
    /// to published Kp/oval-boundary tables, e.g. the Yokoyama/Feldstein-
    /// style oval charts used by aurora-alert services). At Kp 0 the oval
    /// sits near 66.5° geomagnetic; each unit of Kp expands it about 2.2°
    /// equatorward. This is a coarse approximation deliberately chosen for
    /// its documented, defensible source rather than a bespoke fit — a more
    /// precise model (e.g. OVATION's own physics) is exactly what the
    /// `OvationGrid` nowcast supplies for near-term hours.
    public static func kpOvalBoundary(kp: Double) -> Double {
        66.5 - 2.2 * kp
    }
}
