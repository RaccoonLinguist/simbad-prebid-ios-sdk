import SwiftUI
import PrebidMobile

struct PrebidBannerView: UIViewRepresentable {
    let configID: String
    let adSize: CGSize
    
    func makeUIView(context: Context) -> UIView {
        let containerView = UIView()
        
        // Создаем баннер Prebid
        let banner = BannerView(frame: CGRect(origin: .zero, size: adSize),
                                configID: configID,
                                adSize: adSize)
        
        banner.delegate = context.coordinator
        containerView.addSubview(banner)
        
        // Настраиваем констрейнты для центрирования
        banner.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            banner.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            banner.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            banner.widthAnchor.constraint(equalToConstant: adSize.width),
            banner.heightAnchor.constraint(equalToConstant: adSize.height)
        ])
        
        // Загружаем рекламу с сервера
        banner.loadAd()
        
        return containerView
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // В данном случае обновление view не требуется
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    // Координатор для обработки событий Prebid
    class Coordinator: NSObject, BannerViewDelegate {
        func bannerViewPresentationController() -> UIViewController? {
            // Ищем активный контроллер, чтобы SDK мог правильно передать управление системе при клике
            guard let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
                  let window = scene.windows.first(where: { $0.isKeyWindow }) else {
                return nil
            }
            var topController = window.rootViewController
            while let presented = topController?.presentedViewController {
                topController = presented
            }
            return topController
        }
        
        func bannerViewDidReceiveAd(_ bannerView: BannerView) {
            print("Баннер \(bannerView.configID) загружен")
        }
        
        func bannerView(_ bannerView: BannerView, didFailToReceiveAdWith error: Error) {
            print("Ошибка загрузки баннера \(bannerView.configID): \(error.localizedDescription)")
        }
    }
}