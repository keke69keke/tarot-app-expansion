import SwiftUI
import WebKit

public struct TarotWebBrowserView: View {
    @State private var webView = WKWebView()
    @State private var urlString: String = "https://www.sacred-texts.com/tarot/"
    @State private var canGoBack = false
    @State private var canGoForward = false
    @State private var isLoading = false
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 0) {
            // Navigation Bar
            HStack {
                Button(action: {
                    webView.goBack()
                }) {
                    Image(systemName: "chevron.left")
                        .padding(8)
                }
                .disabled(!canGoBack)
                
                Button(action: {
                    webView.goForward()
                }) {
                    Image(systemName: "chevron.right")
                        .padding(8)
                }
                .disabled(!canGoForward)
                
                TextField("URL o buscar...", text: $urlString, onCommit: {
                    loadURL()
                })
                .textFieldStyle(RoundedBorderTextFieldStyle())
                #if os(iOS)
                .keyboardType(.URL)
                .autocapitalization(.none)
                #endif
                .padding(.horizontal, 8)
                
                Button(action: {
                    loadURL()
                }) {
                    Image(systemName: "arrow.clockwise")
                        .padding(8)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color.secondary.opacity(0.1))
            
            ZStack(alignment: .top) {
                WebViewRepresentable(
                    webView: webView,
                    canGoBack: $canGoBack,
                    canGoForward: $canGoForward,
                    isLoading: $isLoading,
                    currentURL: $urlString
                )
                
                if isLoading {
                    ProgressView()
                        .progressViewStyle(LinearProgressViewStyle())
                        .tint(.blue)
                        .background(Color.clear)
                }
            }
        }
        .onAppear {
            loadURL()
        }
    }
    
    private func loadURL() {
        var query = urlString
        if !query.starts(with: "http://") && !query.starts(with: "https://") {
            if query.contains(".") && !query.contains(" ") {
                query = "https://" + query
            } else {
                if let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
                    query = "https://www.google.com/search?q=\(encoded)"
                }
            }
        }
        
        if let url = URL(string: query) {
            urlString = query
            webView.load(URLRequest(url: url))
        }
    }
}

#if os(iOS)
private struct WebViewRepresentable: UIViewRepresentable {
    let webView: WKWebView
    @Binding var canGoBack: Bool
    @Binding var canGoForward: Bool
    @Binding var isLoading: Bool
    @Binding var currentURL: String
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> WKWebView {
        webView.navigationDelegate = context.coordinator
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {}
    
    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebViewRepresentable
        init(_ parent: WebViewRepresentable) { self.parent = parent }
        func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) { parent.isLoading = true; updateState(webView: webView) }
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) { parent.isLoading = false; updateState(webView: webView) }
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) { parent.isLoading = false; updateState(webView: webView) }
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            decisionHandler(.allow)
        }
        private func updateState(webView: WKWebView) {
            DispatchQueue.main.async {
                self.parent.canGoBack = webView.canGoBack
                self.parent.canGoForward = webView.canGoForward
                if let url = webView.url?.absoluteString, !url.isEmpty { self.parent.currentURL = url }
            }
        }
    }
}
#else
private struct WebViewRepresentable: NSViewRepresentable {
    let webView: WKWebView
    @Binding var canGoBack: Bool
    @Binding var canGoForward: Bool
    @Binding var isLoading: Bool
    @Binding var currentURL: String
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeNSView(context: Context) -> WKWebView {
        webView.navigationDelegate = context.coordinator
        return webView
    }
    
    func updateNSView(_ nsView: WKWebView, context: Context) {}
    
    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebViewRepresentable
        init(_ parent: WebViewRepresentable) { self.parent = parent }
        func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) { parent.isLoading = true; updateState(webView: webView) }
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) { parent.isLoading = false; updateState(webView: webView) }
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) { parent.isLoading = false; updateState(webView: webView) }
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            decisionHandler(.allow)
        }
        private func updateState(webView: WKWebView) {
            DispatchQueue.main.async {
                self.parent.canGoBack = webView.canGoBack
                self.parent.canGoForward = webView.canGoForward
                if let url = webView.url?.absoluteString, !url.isEmpty { self.parent.currentURL = url }
            }
        }
    }
}
#endif
