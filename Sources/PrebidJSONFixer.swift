import Foundation

class PrebidJSONFixerProtocol: URLProtocol, URLSessionDataDelegate {
    private var dataTask: URLSessionDataTask?
    private var responseData = Data()
    private var responseObj: URLResponse?

    // 1. Проверяем, наш ли это запрос
    override class func canInit(with request: URLRequest) -> Bool {
        guard let url = request.url?.absoluteString, url.contains("hb.xoalt.com") else { return false }
        // Защита от зацикливания
        if URLProtocol.property(forKey: "PrebidJSONFixerHandled", in: request) != nil { return false }
        return true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { 
        return request 
    }

    // 2. Перехватываем и модифицируем ИСХОДЯЩИЙ запрос перед отправкой
override func startLoading() {
        guard let mutableRequest = (request as NSURLRequest).mutableCopy() as? NSMutableURLRequest else { return }
        URLProtocol.setProperty(true, forKey: "PrebidJSONFixerHandled", in: mutableRequest)
        
        // ==========================================
        // ПАТЧ ЗАГОЛОВКОВ
        // ==========================================
        // Удаляем служебный заголовок Prebid, который убивает выдачу рекламы на Xoalt
        mutableRequest.setValue(nil, forHTTPHeaderField: "PBMIsPBMRequest")
        
        // ==========================================
        // ПАТЧ ИСХОДЯЩЕГО JSON (Оставляем проверенный рабочий вариант)
        // ==========================================
        if let httpBody = mutableRequest.httpBody,
           var jsonDict = try? JSONSerialization.jsonObject(with: httpBody, options: []) as? [String: Any] {
            
            // Вырезаем массив places
            jsonDict.removeValue(forKey: "places")
            
            // Вырезаем глобальный storedrequest
            if var ext = jsonDict["ext"] as? [String: Any],
               var prebid = ext["prebid"] as? [String: Any] {
                prebid.removeValue(forKey: "storedrequest")
                ext["prebid"] = prebid
                jsonDict["ext"] = ext
            }
            
            if let patchedData = try? JSONSerialization.data(withJSONObject: jsonDict, options: []) {
                mutableRequest.httpBody = patchedData
                mutableRequest.setValue("\(patchedData.count)", forHTTPHeaderField: "Content-Length")
            }
        }
        // ==========================================
        
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = config.protocolClasses?.filter { $0 != PrebidJSONFixerProtocol.self }
        
        let session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
        dataTask = session.dataTask(with: mutableRequest as URLRequest)
        dataTask?.resume()
    }
    override func stopLoading() {
        dataTask?.cancel()
        dataTask = nil
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        self.responseObj = response
        completionHandler(.allow)
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        responseData.append(data)
    }

    // 3. Перехватываем и лечим ВХОДЯЩИЙ ответ от сервера
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            client?.urlProtocol(self, didFailWithError: error)
            return
        }
        
        let brokenString = String(data: responseData, encoding: .utf8) ?? ""
        
        // Очищаем мусорные символы, ломающие парсер
        var fixedString = brokenString.replacingOccurrences(of: "\u{FEFF}", with: "")
        fixedString = fixedString.replacingOccurrences(of: "\n", with: "")
        fixedString = fixedString.replacingOccurrences(of: "\r", with: "")
        fixedString = fixedString.replacingOccurrences(of: "\t", with: "")
        
        // Вставляем type: banner, так как сервер Xoalt забывает его присылать
        fixedString = fixedString.replacingOccurrences(of: "\"prebid\":{\"targeting\"", with: "\"prebid\":{\"type\":\"banner\",\"targeting\"")
        
        let fixedData = fixedString.data(using: .utf8) ?? responseData
        
        // Пересчитываем заголовки ответа (Content-Length изменился после удаления переносов)
        if let httpResponse = responseObj as? HTTPURLResponse, let url = httpResponse.url {
            var headers = httpResponse.allHeaderFields as? [String: String] ?? [:]
            headers["Content-Length"] = String(fixedData.count)
            
            let newResponse = HTTPURLResponse(url: url, statusCode: httpResponse.statusCode, httpVersion: "HTTP/1.1", headerFields: headers) ?? httpResponse
            client?.urlProtocol(self, didReceive: newResponse, cacheStoragePolicy: .notAllowed)
        }
        
        // Отдаем вылеченные данные в SDK
        client?.urlProtocol(self, didLoad: fixedData)
        client?.urlProtocolDidFinishLoading(self)
    }
}

// ==========================================
// ИНТЕГРАЦИЯ В URLSESSION (Swizzling)
// ==========================================
extension URLSession {
    private static var isSwizzled = false
    
    static func enablePrebidJSONFixer() {
        guard !isSwizzled else { return }
        isSwizzled = true
        
        URLProtocol.registerClass(PrebidJSONFixerProtocol.self)
        
        // Перехват метода с делегатом
        if let original = class_getClassMethod(URLSession.self, NSSelectorFromString("sessionWithConfiguration:delegate:delegateQueue:")),
           let swizzled = class_getClassMethod(URLSession.self, #selector(swizzled_sessionWithConfig(_:delegate:delegateQueue:))) {
            method_exchangeImplementations(original, swizzled)
        }
        
        // Перехват обычного метода
        if let original = class_getClassMethod(URLSession.self, NSSelectorFromString("sessionWithConfiguration:")),
           let swizzled = class_getClassMethod(URLSession.self, #selector(swizzled_sessionWithConfigOnly(_:))) {
            method_exchangeImplementations(original, swizzled)
        }
    }
    
    @objc class func swizzled_sessionWithConfig(_ configuration: URLSessionConfiguration, delegate: URLSessionDelegate?, delegateQueue queue: OperationQueue?) -> URLSession {
        var protocols = configuration.protocolClasses ?? []
        if !protocols.contains(where: { $0 == PrebidJSONFixerProtocol.self }) {
            protocols.insert(PrebidJSONFixerProtocol.self, at: 0)
            configuration.protocolClasses = protocols
        }
        return self.swizzled_sessionWithConfig(configuration, delegate: delegate, delegateQueue: queue)
    }
    
    @objc class func swizzled_sessionWithConfigOnly(_ configuration: URLSessionConfiguration) -> URLSession {
        var protocols = configuration.protocolClasses ?? []
        if !protocols.contains(where: { $0 == PrebidJSONFixerProtocol.self }) {
            protocols.insert(PrebidJSONFixerProtocol.self, at: 0)
            configuration.protocolClasses = protocols
        }
        return self.swizzled_sessionWithConfigOnly(configuration)
    }
}
