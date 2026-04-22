import Foundation

final class DataLoader {
    static func loadJSON<T: Decodable>(_ filename: String, type: T.Type) -> T? {
        let bundle = Bundle.main
        if let url = bundle.url(forResource: filename, withExtension: nil) {
            return loadFromURL(url, type: type)
        }

        // Handle paths like "Data/ingredients.dictionary.json"
        let pathURL = URL(fileURLWithPath: filename)
        let resourceName = pathURL.deletingPathExtension().lastPathComponent
        let resourceExt = pathURL.pathExtension.isEmpty ? nil : pathURL.pathExtension
        let rawSubdir = pathURL.deletingLastPathComponent().path
        let resourceSubdir = (rawSubdir == "." || rawSubdir == "/") ? nil : rawSubdir

        if let url = bundle.url(forResource: resourceName, withExtension: resourceExt, subdirectory: resourceSubdir) {
            return loadFromURL(url, type: type)
        }

        // Many iOS bundles flatten file paths in the Copy Bundle Resources phase.
        if let url = bundle.url(forResource: resourceName, withExtension: resourceExt) {
            return loadFromURL(url, type: type)
        }

        // Try direct appending against bundle resource root.
        if let base = bundle.resourceURL {
            let direct = base.appendingPathComponent(filename)
            if FileManager.default.fileExists(atPath: direct.path) {
                return loadFromURL(direct, type: type)
            }
        }

        // Fallback: Attempt to load via file path in repo (useful when running from Xcode opened at project root)
        let fm = FileManager.default
        let cwd = fm.currentDirectoryPath
        let path = URL(fileURLWithPath: cwd).appendingPathComponent(filename)
        if fm.fileExists(atPath: path.path) {
            return loadFromURL(path, type: type)
        }

        print("DataLoader could not find resource: \(filename)")

        return nil
    }

    private static func loadFromURL<T: Decodable>(_ url: URL, type: T.Type) -> T? {
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            return try decoder.decode(T.self, from: data)
        } catch {
            print("DataLoader error loading \(url): \(error)")
            return nil
        }
    }
}
