//
//  DropDelegates.swift
//  GatePass
//
//

import SwiftUI
import UniformTypeIdentifiers


struct DropQuarantine: DropDelegate {

    @ObservedObject var appState: AppState
    @Binding var isTargeted: Bool

    func validateDrop(info: DropInfo) -> Bool {
        !appState.isLoading && !info.itemProviders(for: [UTType.fileURL]).isEmpty
    }

    func dropEntered(info: DropInfo) {
        updateOnMain {
            isTargeted = true
        }
    }

    func dropExited(info: DropInfo) {
        updateOnMain {
            isTargeted = false
        }
    }

    func performDrop(info: DropInfo) -> Bool {

        updateOnMain {
            isTargeted = false
        }

        let itemProviders = info.itemProviders(for: [UTType.fileURL])

//        guard itemProviders.count == 1 else {
//            return false
//        }

        if itemProviders.count == 1 {
            updateOnMain {
                appState.multiDrop = false
            }
        } else {
            updateOnMain {
                appState.multiDrop = true
            }
        }

        for itemProvider in itemProviders {
            itemProvider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, error in
                let url: URL?
                if let data = item as? Data {
                    url = URL(dataRepresentation: data, relativeTo: nil)
                } else if let urlValue = item as? URL {
                    url = urlValue
                } else if let urlValue = item as? NSURL {
                    url = urlValue as URL
                } else {
                    dump(error)
                    return
                }
                guard let url, url.pathExtension.lowercased() == "app" else {
                    printOS("Error: Not a valid URL.")
                    return
                }

                updateOnMain {
                    appState.status = "正在移除 App 的隔离标记"
                    appState.isLoading = true
                }
                Task
                {
                    await removeQuarantine(path: url.path, appState: appState)
                }

            }
        }

        return true
    }
}
