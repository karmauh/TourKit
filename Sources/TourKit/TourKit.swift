// Placeholder that gives the target a source file until the model types are
// added in the next stage. Deliberately not named `TourKit`: a type with the
// module's name would shadow module-qualified lookups such as `TourKit.CostMatrix`.
enum PackageInfo {
    static let version = "0.1.0-dev"
}
