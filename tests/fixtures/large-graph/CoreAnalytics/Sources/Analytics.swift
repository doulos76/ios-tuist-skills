import LogKit

public enum Analytics {
    public static func event(_ name: String) -> String {
        Log.message("event " + name)
    }
}
