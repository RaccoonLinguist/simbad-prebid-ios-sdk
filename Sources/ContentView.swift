import SwiftUI
import PrebidMobile

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

                // Это пример размещения разных баннерных мест на одной странице. 
                //Вместо 44959 и 44960 нужно указывать те ID баннерных мест, котроые мередаст менеджер SimbAD
                PrebidBannerView(configID: "44959", adSize: CGSize(width: 320, height: 150))
                    .frame(width: 320, height: 150)

                NavigationLink(value: AppRoute.land2) {
                    Text("тест2")
                        .font(.title)
                        .padding()
                }

                Spacer()
                    .frame(height: 15)

                // вызов второго баннера
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
// Обработчик диплинка ищет в <a href=""> баннера совпадение и перенаправляет на тот экран, который указан в path.append(AppRoute.XXX)
    private func handleDeepLink(_ url: URL) {
        let urlString = url.absoluteString
        if urlString.contains("land1") {
            path.append(AppRoute.land1)
        } else if urlString.contains("land2") {
            path.append(AppRoute.land2)
        }
    }
}
