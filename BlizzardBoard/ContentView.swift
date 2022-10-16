//
//  ContentView.swift
//  BlizzardBoard
//
//  Created by Hornbeck on 10/11/22.
//

import SwiftUI
import CoreServices
import UniformTypeIdentifiers

struct Theme: Hashable {
    var Icon: String
    var Name: String
    var ThemeType: String
    var IconCount: Int
    var IconBundlesExists: Bool
}

struct ContentView: View {
    @AppStorage("CurrentThemeIcons") var CurrentThemeIcons: Array<String> = []
    @AppStorage("CurrentTheme") var CurrentTheme = ""
    @State var Themes: Array<Theme> = []
    @AppStorage("HideLabels") var HideLabels = false
    @AppStorage("DisableWebClipRemoval") var DisableWebClipRemoval = false
    @State var RespringAlert = false
    var body: some View {
        NavigationView {
            Form {
                if Themes.isEmpty {
                    Section {
                        Text("No Themes Installed\nShare .theme Folder With BlizzBoard")
                    } footer: {
                        Text("Created By Benjamin Hornbeck (@AppInstalleriOS)")
                    }
                } else {
                    Section {
                        ForEach(Themes, id: \.self) { Theme in
                            HStack(spacing: 15) {
                                if Theme.Icon.isEmpty {
                                    Image("Icon")
                                        .resizable()
                                        .frame(width: 35, height: 35)
                                        .cornerRadius(10)
                                } else {
                                    Image(uiImage: UIImage(contentsOfFile: "/var/mobile/Themes/\(Theme.Name).theme/\(Theme.Icon)") ?? UIImage())
                                        .resizable()
                                        .frame(width: 35, height: 35)
                                        .cornerRadius(10)
                                }
                                VStack(alignment: .leading) {
                                    Text(Theme.Name)
                                        .font(.system(size: 19))
                                    if Theme.IconBundlesExists {
                                        Text("\(String(Theme.IconCount)) Icons")
                                            .font(.system(size: 15))
                                            .opacity(0.5)
                                    } else {
                                        Text("IconBundles Folder Doesn't Exist!")
                                            .font(.system(size: 15))
                                            .foregroundColor(.red)
                                    }
                                }
                                Spacer()
                                Button {
                                    if Theme.Name == CurrentTheme {
                                        RemoveTheme()
                                        RespringAlert.toggle()
                                    } else {
                                        if !CurrentTheme.isEmpty {
                                            RemoveTheme()
                                        }
                                        SetTheme(Theme, HideLabels, DisableWebClipRemoval)
                                        RespringAlert.toggle()
                                    }
                                } label: {
                                    if Theme.Name == CurrentTheme {
                                        Color.red
                                            .frame(width: 85, height: 35)
                                            .overlay(Text("Disable").foregroundColor(.white))
                                            .cornerRadius(20)
                                    } else {
                                        Color.green
                                            .frame(width: 85, height: 35)
                                            .overlay(Text("Enable").foregroundColor(.white))
                                            .cornerRadius(20)
                                    }
                                }
                                .disabled(!Theme.IconBundlesExists)
                            }
                        }
                        .onConfirmedDelete(
                            title: { IndexSet in
                                "Confirm Theme Removal"
                            }, message: { IndexSet in
                                "Removing the theme \(Themes[IndexSet.first!].Name)"
                            }, action: { IndexSet in
                                do {
                                    let ThemeToRemove = Themes[IndexSet.first!].Name
                                    var ShouldRespring = false
                                    if ThemeToRemove == CurrentTheme {
                                        RemoveTheme()
                                        ShouldRespring = true
                                    }
                                    try FileManager.default.removeItem(atPath: "/var/mobile/Themes/\(ThemeToRemove).theme")
                                    Themes.remove(at: IndexSet.first!)
                                    if ShouldRespring {
                                        RespringAlert.toggle()
                                    }
                                } catch {
                                    print("Error")
                                }
                            })
                    }
                    Section {
                        Toggle(isOn: $HideLabels) {
                            Text("Hide App Labels")
                        }
                        Toggle(isOn: $DisableWebClipRemoval) {
                            Text("Disable WebClip Removal")
                        }
                        Button {
                            respring()
                        } label: {
                            HStack {
                                Text("Respring")
                                Spacer()
                                Image(systemName: "arrow.clockwise")
                            }
                        }
                    } header: {
                        Text("Options")
                    } footer: {
                        Text("Created By @AppInstalleriOS\nBlizzBoard - Stable \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "") (\(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""))")
                    }
                }
            }
            .navigationTitle("BlizzBoard")
            .navigationBarItems(
                leading:
                    EditButton(),
                trailing:
                    Button {
                        UIApplication.shared.open(URL(string: "https://twitter.com/AppInstalleriOS")!)
                    } label: {
                        Image("Twitter")
                            .resizable()
                            .frame(width: 32, height: 32)
                            .cornerRadius(50)
                    }
            )
        }
        .navigationViewStyle(.stack)
        .alert(isPresented: $RespringAlert, content: {
            Alert(title: Text("Respring Now?"), message: Text("In order to take effect you need to respring."), primaryButton: Alert.Button.default(Text("Later")), secondaryButton: Alert.Button.default(Text("Respring"), action: {
                respring()
            }))
        })
        .onAppear {
            if !FileManager.default.fileExists(atPath: "/var/mobile/Themes") {
                do {
                    try FileManager.default.createDirectory(atPath: "/var/mobile/Themes", withIntermediateDirectories: false)
                } catch {
                    print("Error Making Themes Directory")
                }
            }
            Themes = GetThemes()
        }
        .onOpenURL { URL in
            do {
                try FileManager.default.copyItem(atPath: URL.path, toPath: "/var/mobile/Themes/\(URL.lastPathComponent)")
                Themes = GetThemes()
            } catch {
                print("Error \(URL.path) \(error)")
            }
        }
    }
}

func SetTheme(_ Theme: Theme, _ HideLabels: Bool, _ DisableWebClipRemoval: Bool) {
    @AppStorage("CurrentThemeIcons") var CurrentThemeIcons: Array<String> = []
    @AppStorage("CurrentTheme") var CurrentTheme = ""
    do {
        let Icons = try FileManager.default.contentsOfDirectory(atPath: "/var/mobile/Themes/\(Theme.Name).theme/IconBundles")
        for icon in Icons {
            let BundleID = icon.replacingOccurrences(of: Theme.ThemeType, with: "")
            if GetApps().contains(BundleID) {
                let WebClipID = MakeWebClip(IconPath: "/var/mobile/Themes/\(Theme.Name).theme/IconBundles/\(BundleID)\(Theme.ThemeType)", BundleID: BundleID, HideLabels: HideLabels, DisableWebClipRemoval: DisableWebClipRemoval)
                CurrentThemeIcons.append(WebClipID)
            }
        }
        CurrentTheme = Theme.Name
    } catch {
        
    }
}

func RemoveTheme() {
    @AppStorage("CurrentThemeIcons") var CurrentThemeIcons: Array<String> = []
    @AppStorage("CurrentTheme") var CurrentTheme = ""
    do {
        for webclip in CurrentThemeIcons {
            if FileManager.default.fileExists(atPath: "/var/mobile/Library/WebClips/\(webclip).webclip") {
                try FileManager.default.removeItem(atPath: "/var/mobile/Library/WebClips/\(webclip).webclip")
            }
        }
        CurrentTheme = ""
        CurrentThemeIcons = []
    } catch {
        print("Error")
    }
}

func MakeWebClip(IconPath: String, BundleID: String, HideLabels: Bool, DisableWebClipRemoval: Bool) -> String {
    do {
        let WebClipUUID = UUID().description
        let WebClipPath = "/var/mobile/Library/WebClips/\(WebClipUUID).webclip"
        let InfoPlist = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">\n<plist version=\"1.0\">\n<dict>\n<key>ApplicationBundleIdentifier</key>\n<string>\(BundleID)</string>\n<key>ApplicationBundleVersion</key>\n<integer>1</integer>\n<key>ClassicMode</key>\n<false/>\n<key>ConfigurationIsManaged</key>\n<false/>\n<key>ContentMode</key>\n<string>UIWebClipContentModeRecommended</string>\n<key>FullScreen</key>\n<true/>\n<key>IconIsPrecomposed</key>\n<false/>\n<key>IconIsScreenShotBased</key>\n<false/>\n<key>IgnoreManifestScope</key>\n<false/>\n<key>IsAppClip</key>\n<false/>\n<key>Orientations</key>\n<integer>0</integer>\n<key>ScenelessBackgroundLaunch</key>\n<true/>\n<key>Title</key>\n<string>\(HideLabels ? "" : SBFApplication(applicationBundleIdentifier: BundleID).displayName ?? "Unknown")</string>\n<key>WebClipStatusBarStyle</key>\n<string>UIWebClipStatusBarStyleDefault</string>\n<key>RemovalDisallowed</key>\n<\(DisableWebClipRemoval ? "true" : "false")/>\n</dict>\n</plist>"
        if !FileManager.default.fileExists(atPath: "/var/mobile/Library/WebClips") {
            try FileManager.default.createDirectory(atPath: "/var/mobile/Library/WebClips", withIntermediateDirectories: false)
        }
        try FileManager.default.createDirectory(atPath: WebClipPath, withIntermediateDirectories: false)
        try FileManager.default.createSymbolicLink(atPath: "\(WebClipPath)/icon.png", withDestinationPath: IconPath)
        FileManager.default.createFile(atPath: "\(WebClipPath)/Info.plist", contents: Data(InfoPlist.utf8))
        return WebClipUUID
    } catch {
        return "Error"
    }
}

func GetApps() -> Array<String> {
    var apps: Array<String> = []
    for app in LSApplicationWorkspace().allInstalledApplications() as! [LSApplicationProxy] {
        let BundleID = NSDictionary(contentsOfFile: "\(app.bundleURL.path)/Info.plist")?.value(forKey: "CFBundleIdentifier") ?? "Unknown"
        apps.append(BundleID as! String)
    }
    return apps
}

extension Array: RawRepresentable where Element: Codable {
    public init?(rawValue: String) {
        guard let data = rawValue.data(using: .utf8),
              let result = try? JSONDecoder().decode([Element].self, from: data)
        else {
            return nil
        }
        self = result
    }
    public var rawValue: String {
        guard let data = try? JSONEncoder().encode(self),
              let result = String(data: data, encoding: .utf8)
        else {
            return "[]"
        }
        return result
    }
}

func GetThemes() -> Array<Theme> {
    var Themes: Array<Theme> = []
    do {
        for theme in try FileManager.default.contentsOfDirectory(atPath: "/var/mobile/Themes") {
            Themes.append(Theme(Icon: GetThemeIcon(theme), Name: theme.replacingOccurrences(of: ".theme", with: ""), ThemeType: GetThemeType(theme), IconCount: GetThemeIconCount(theme), IconBundlesExists: FileManager.default.fileExists(atPath: "/var/mobile/Themes/\(theme)/IconBundles")))
        }
        return Themes
    } catch {
        return Themes
    }
}

func GetThemeType(_ Theme: String) -> String {
    do {
        var ThemeType = "-large.png"
        if FileManager.default.fileExists(atPath: "/var/mobile/Themes/\(Theme)/IconBundles") {
            let IconBundles = try FileManager.default.contentsOfDirectory(atPath: "/var/mobile/Themes/\(Theme)/IconBundles")
            if IconBundles.isEmpty {
                ThemeType = "-large.png"
            } else {
                if (IconBundles.first ?? "").contains("-large.png") {
                    ThemeType = "-large.png"
                } else if (IconBundles.first ?? "").contains("@3x.png") {
                    ThemeType = "@3x.png"
                } else if (IconBundles.first ?? "").contains("@2x.png") {
                    ThemeType = "@2x.png"
                }
            }
        }
        return ThemeType
    } catch {
        return "-large.png"
    }
}

func GetThemeIcon(_ Theme: String) -> String {
    var Icon = ""
    if FileManager.default.fileExists(atPath: "/var/mobile/Themes/\(Theme)/icon.png") {
        Icon = "icon.png"
    } else if FileManager.default.fileExists(atPath: "/var/mobile/Themes/\(Theme)/Icon.png") {
        Icon = "Icon.png"
    }
    return Icon
}

func GetThemeIconCount(_ Theme: String) -> Int {
    var IconCount = 0
    if FileManager.default.fileExists(atPath: "/var/mobile/Themes/\(Theme)/IconBundles") {
        do {
            IconCount = try FileManager.default.contentsOfDirectory(atPath: "/var/mobile/Themes/\(Theme)/IconBundles").count
        } catch {
            print("Error \(error)")
        }
    }
    return IconCount
}

extension DynamicViewContent {
    func onConfirmedDelete(title: @escaping (IndexSet) -> String, message: @escaping (IndexSet) -> String, action: @escaping (IndexSet) -> Void) -> some View {
        DeleteConfirmation(source: self, title: title, message: message, action: action)
    }
}

struct DeleteConfirmation<Source>: View where Source: DynamicViewContent {
    let source: Source
    let title: (IndexSet) -> String
    let message: (IndexSet) -> String
    let action: (IndexSet) -> Void
    @State var indexSet: IndexSet = []
    @State var isPresented: Bool = false
    var body: some View {
        source
            .onDelete { indexSet in
                self.indexSet = indexSet
                isPresented = true
            }
            .alert(isPresented: $isPresented) {
                Alert(
                    title: Text(title(indexSet)),
                    message: Text(message(indexSet)),
                    primaryButton: .cancel(),
                    secondaryButton: .destructive(
                        Text("Remove"),
                        action: {
                            withAnimation {
                                action(indexSet)
                            }
                        }
                    )
                )
            }
    }
}
