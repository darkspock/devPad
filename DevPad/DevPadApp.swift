import SwiftUI

@main
struct DevPadApp: App {
    static var initialDirectory: String = FileManager.default.homeDirectoryForCurrentUser.path

    init() {
        // Parse command line arguments
        let args = CommandLine.arguments
        if args.count > 1 {
            let path = args[1]
            var isDirectory: ObjCBool = false
            if FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory) && isDirectory.boolValue {
                DevPadApp.initialDirectory = path
            } else {
                // If it's a file, use its parent directory
                let url = URL(fileURLWithPath: path)
                DevPadApp.initialDirectory = url.deletingLastPathComponent().path
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView(initialDirectory: DevPadApp.initialDirectory)
        }
        .windowStyle(.automatic)
        .commands {
            SidebarCommands()
        }
    }
}
