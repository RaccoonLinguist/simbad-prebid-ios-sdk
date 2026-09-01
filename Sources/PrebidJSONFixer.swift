import Foundation

class PrebidJSONFixerProtocol: URLProtocol, URLSessionDataDelegate {
    private var dataTask: URLSessionDataTask?
    private var responseData = Data()
    private var responseObj: URLResponse?

    override class func canInit(with request: URLRequest) -> Bool {
        guard let url = request.url?.absoluteString, url.contains("hb.xoalt.com") else { return false }
        if URLProtocol.property(forKey: "PrebidJSONFixerHandled", in: request) != nil { return false }
        return true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { return request }

    override func startLoading() {
        guard let mutableRequest = (request as NSURLRequest).mutableCopy() as? NSMutableURLRequest else { return }
        URLProtocol.setProperty(true, forKey: "PrebidJSONFixerHandled", in: mutableRequest)
        
        let config = URLSessionConfiguration.ephemeral
        // Дополнительная защита от бесконечного цикла
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

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            client?.urlProtocol(self, didFailWithError: error)
            return
        }
        
        let brokenString = String(data: responseData, encoding: .utf8) ?? ""
        var fixedString = brokenString.replacingOccurrences(of: "\u{FEFF}", with: "")
        fixedString = fixedString.replacingOccurrences(of: "\n", with: "")
        fixedString = fixedString.replacingOccurrences(of: "\r", with: "")
        
        let fixedData = fixedString.data(using: .utf8) ?? responseData
        
        if let httpResponse = responseObj as? HTTPURLResponse, let url = httpResponse.url {
            var headers = httpResponse.allHeaderFields as? [String: String] ?? [:]
            headers["Content-Length"] = String(fixedData.count) // Пересчитываем размер вылеченного файла!
            
            let newResponse = HTTPURLResponse(url: url, statusCode: httpResponse.statusCode, httpVersion: "HTTP/1.1", headerFields: headers) ?? httpResponse
            client?.urlProtocol(self, didReceive: newResponse, cacheStoragePolicy: .notAllowed)
        }
        
        client?.urlProtocol(self, didLoad: fixedData)
        client?.urlProtocolDidFinishLoading(self)
    }
}

// УЛЬТИМАТИВНЫЙ ПЕРЕХВАТЧИК (Ловит Objective-C инициализаторы)
extension URLSession {
    private static var isSwizzled = false
    
    static func enablePrebidJSONFixer() {
        guard !isSwizzled else { return }
        isSwizzled = true
        
        URLProtocol.registerClass(PrebidJSONFixerProtocol.self)
        
        // Перехват [NSURLSession sessionWithConfiguration:delegate:delegateQueue:]
        if let original = class_getClassMethod(URLSession.self, NSSelectorFromString("sessionWithConfiguration:delegate:delegateQueue:")),
           let swizzled = class_getClassMethod(URLSession.self, #selector(swizzled_sessionWithConfig(_:delegate:delegateQueue:))) {
            method_exchangeImplementations(original, swizzled)
        }
        
        // Перехват [NSURLSession sessionWithConfiguration:]
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