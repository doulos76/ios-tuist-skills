// Deliberately excluded by ExcludeFeature's `.glob(excluding:)` pattern.
// References a type that doesn't exist — if this file were ever
// accidentally compiled into the target (e.g. by an incorrect
// buildableFolders conversion silently dropping the exclusion), the
// build would fail here, making the omission observable, not silent.
struct ThisMustNotCompile {
    let broken: NonExistentType
}
