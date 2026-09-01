import UIKit
import PrebidMobile

class AppDelegate: NSObject, UIApplicationDelegate {
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        // ВАЖНО: вызываем метод у URLSession
        URLSession.enablePrebidJSONFixer() //Вызов клиентской части отредактированного SDK
        
        // 1. Указываем ваш Account ID - ВМЕСТО 273000419 НУЖНО УКАЗАТЬ ТОТ, КОТОРЫЙ ВЫ ПОЛУЧИТЕ ОТ МЕНЕДЖЕРА SIMB-AD
        Prebid.shared.prebidServerAccountId = "273000419"
        
        // 2. Указываем Stored Request ID для аукциона - НЕ МЕНЯТЬ
        Prebid.shared.storedAuctionResponse = "0689a263-318d-448b-a3d4-b02e8a709d9d"
        
        // 3. Вызываем инициализацию безопасно
        do {
            try Prebid.initializeSDK(serverURL: "https://hb.xoalt.com/x-simb/", { status, error in
                if status == .succeeded {
                    print("✅ Prebid SDK успешно инициализирован")
                } else if let error = error {
                    print("❌ Ошибка инициализации SDK: \(error.localizedDescription)")
                }
            })
        } catch {
            print("❌ Критическая ошибка: не удалось передать URL в SDK (\(error.localizedDescription))")
        }
        
        return true
    }
}
