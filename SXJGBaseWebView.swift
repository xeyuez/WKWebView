//
//  WebView.swift
//
//  Created by yumez on 2018/9/19.
//  Copyright © 2018 yumez. All rights reserved.
//

import UIKit
import WebKit
protocol BaseWebViewDelegateProtocol: class {
    func BaseWebViewClickBack()
}

class SXJGBaseWebView: UIView {
    
    weak var delegate: BaseWebViewDelegateProtocol?
    
    private var webViewBaseUrl: URL = URL(string: loginAddress + serverAddress)!
    
    private lazy var webView: WKWebView = {
        let usercontent = WKUserContentController.init()
        let  cookes = "document.cookie=\(self.ajaxSessionID())"
        let cookieScript = WKUserScript.init(source: cookes, injectionTime: WKUserScriptInjectionTime.atDocumentStart, forMainFrameOnly: false)
        
        let config = WKWebViewConfiguration.init()
        config.userContentController.addUserScript(cookieScript)
        config.userContentController.add(self, name: "backToHomeVC")
        let webview = WKWebView.init(frame: CGRect.zero, configuration: config)
        webview.uiDelegate = self
        webview.navigationDelegate = self
        //去除底部黑条
        webview.isOpaque = false
        webview.backgroundColor = UIColor.white
        self.addSubview(webview)
        return webview
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        initUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func initUI(){
        self.webView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        
        self.webView.backgroundColor = UIColor.white
    }
    
    /**
     * params: JSONObject
     * route: mobileFlueGasMgmt/listRealTimeFlueGasByOrg.do
     */
    func loadRequest(_ params: JSONObject, route: String) {
        let request = self.handelerRuest(routString: route, params: params)
        
        self.webView.load(request)
    }
    
    
    private func handelerRuest(routString: String, params: JSONObject) -> URLRequest {
        var momarlParams: JSONObject = ["userId": JSWXJYJGLoginManager.shared.loginUserId!]
        for (k, v) in params {
            momarlParams[k] = v
        }
        
        let data: JSONObject = ["data": momarlParams]
        let requestGsonStr = "requestGson=\(JSONToString(data))"
        let url = URL(string: webViewBaseUrl.absoluteString + "/" + routString)!
        
        if #available(iOS 11, *) {
            debugLog("postUrl: \(url), params: \(requestGsonStr)")
            var request = URLRequest(url: url)
            request.addValue(JSWXJYJGLoginManager.shared.sessionID ?? "", forHTTPHeaderField: "Cookie")
            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            request.httpBody = requestGsonStr.data(using: String.Encoding.utf8)
            request.httpMethod = "POST"
            return request
            
        }else {
            // 将参数带在url后面
            let getUrlStr = url.absoluteString + "?" + requestGsonStr
            let encodeUrlString = getUrlStr.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
            let requestUrl = URL(string: encodeUrlString)!
            
            debugLog(requestUrl)
            var request = URLRequest(url: requestUrl)
            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            request.addValue(JSWXJYJGLoginManager.shared.sessionID ?? "", forHTTPHeaderField: "Cookie")
            request.httpBody = requestGsonStr.data(using: String.Encoding.utf8)
            request.httpMethod = "POST"
            return request
            
        }
    }
    
    //网页里面添加的请求用到的sessionID
    func ajaxSessionID() -> String {
        return "document.cookie = '\(LoginManager.shared.sessionID ?? "");path=/';"
    }
    
}



extension SXJGBaseWebView:  WKUIDelegate,WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "backToHomeVC" {
            self.delegate?.BaseWebViewClickBack()
        }
        debugLog("message:\(message.body)")
        
    }
    
    /**
     * 在JS端调用alert函数时，会触发此代理方法。JS端调用alert时所传的数据可以通过message拿到。在原生得到结果后，需要回调JS，是通过completionHandler回调。
     */
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        debugLog("Alertmessage: \(message)")
        let alertVC = UIAlertController.init(title: "提示", message: message, preferredStyle: UIAlertController.Style.alert)
        let action = UIAlertAction.init(title: "确定", style: UIAlertAction.Style.default) { (action) in
            completionHandler()
            
        }
        alertVC.addAction(action)
        self.viewController?.present(alertVC, animated: true, completion: nil)
    }

    /**
     * JS端调用confirm函数时，会触发此方法，通过message可以拿到JS端所传的数据，在iOS端显示原生alert得到YES/NO后，通过completionHandler回调给JS端
     */
//    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
//        debugLog("Confirmmessage: \(message)")
//
//    }

    /**
     * JS端调用prompt函数时，会触发此方法,要求输入一段文本,在原生输入得到文本内容后，通过completionHandler回调给JS
     */
    func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
        debugLog("TextInput prompt: \(prompt)")
    }
}

extension SXJGBaseWebView:  WKNavigationDelegate {
    /**
     * 加载错误时调用
     */
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        
    }
    
    /**
     * 当内容开始到达主帧时被调用（即将完成）
     */
    
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
    }
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        MBProgressUtil.showWait(in:self)
    }
    
    /**
     * 加载完成
     */
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        MBProgressUtil.hide(in:self)
        let  offSetValue:String
        if isPhoneX() {
            offSetValue = "40"
        }else{
            offSetValue = "20"
        }
        let headHeight = "whole_com_func.headAddHeight(\(offSetValue))"
        webView.evaluateJavaScript(headHeight) { (value, error) in
        }
    }
    
    
//    /**
//     * 判断链接是否允许跳转
//     */
//    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
//        //如果是跳转一个新页面
//        if (navigationAction.targetFrame == nil) {
//            webView.load(navigationAction.request)
//
//        }
//        decisionHandler(WKNavigationActionPolicy.allow)
//    }
//
//    /**
//     * 拿到响应后决定是否允许跳转
//     */
//    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
//
//    }
//
//    /**
//     * 链接开始加载时调用
//     */
//    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
//
//    }
//
//    /**
//     * 收到服务器重定向时调用
//     */
//    func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
//
//    }
//
//    /**
//     * 在提交的主帧中发生错误时调用
//     */
//    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
//
//    }
//
//    /**
//     * 当webView需要响应身份验证时调用(如需验证服务器证书)
//     */
//    func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
//
//    }
//
//    /**
//     * 当webView的web内容进程被终止时调用。(iOS 9.0之后)
//     */
//    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
//
//    }
//
    
    //    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
    //
    //    }
    
    
}

