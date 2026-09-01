import SwiftUI
import PrebidMobile

// ... (перечисление AppRoute остается без изменений) ...
enum AppRoute: Hashable {
    case land1
    case land2
}

struct ContentView: View {
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: 0) {
                NavigationLink(value: AppRoute.land1) {
                    Text("тест1")
                        .font(.title)
                        .padding()
                }

                Spacer()
                    .frame(height: 15)

                // Ставим ваш БОЕВОЙ ID баннера (из блока imp.ext.prebid.storedrequest.id)
                PrebidBannerView(configID: "44959", adSize: CGSize(width: 320, height: 150))
                    .frame(width: 320, height: 150)

                NavigationLink(value: AppRoute.land2) {
                    Text("тест2")
                        .font(.title)
                        .padding()
                }

                Spacer()
                    .frame(height: 15)

                // Если для второго места нет ID, пока можно продублировать 44959 
                // или оставить заглушку
                PrebidBannerView(configID: "44960", adSize: CGSize(width: 320, height: 150))
                    .frame(width: 320, height: 150)

                Spacer()
                    .frame(height: 15)
                
                Text("тест3")
            }
            .background(Color.gray.opacity(0.1)) 
            .navigationDestination(for: AppRoute.self) { route in
                switch route {
                case .land1:
                    Land1View()
                case .land2:
                    Land2View()
                }
            }
            .onOpenURL { url in
                handleDeepLink(url)
            }
        }
    }

    private func handleDeepLink(_ url: URL) {
        let urlString = url.absoluteString
        if urlString.contains("land1") {
            path.append(AppRoute.land1)
        } else if urlString.contains("land2") {
            path.append(AppRoute.land2)
        }
    }
}