import SwiftUI
import WebKit

extension Notification.Name {
    static let webReload = Notification.Name("web.reload")
}

struct ContentView: View {
    @State private var loading = true
    @State private var failed = false

    private let home = URL(string: "https://tire.pricc.fun")!

    var body: some View {
        ZStack(alignment: .top) {
            WebContainer(url: home, loading: $loading, failed: $failed)
                .ignoresSafeArea(edges: .bottom)

            if loading && !failed {
                ProgressView()
                    .progressViewStyle(.linear)
                    .tint(Color(red: 0.92, green: 0.35, blue: 0.05))
                    .frame(height: 2)
            }

            if failed {
                VStack(spacing: 14) {
                    Image(systemName: "wifi.exclamationmark")
                        .font(.system(size: 46))
                        .foregroundColor(.secondary)
                    Text("网络连接失败")
                        .font(.headline)
                    Text("请检查网络后重试")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Button("重新加载") {
                        failed = false
                        loading = true
                        NotificationCenter.default.post(name: .webReload, object: nil)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color(red: 0.92, green: 0.35, blue: 0.05))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemBackground))
            }
        }
    }
}

struct WebContainer: UIViewRepresentable {
    let url: URL
    @Binding var loading: Bool
    @Binding var failed: Bool

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> WKWebView {
        let cfg = WKWebViewConfiguration()
        cfg.allowsInlineMediaPlayback = true
        cfg.mediaTypesRequiringUserActionForPlayback = []
        cfg.websiteDataStore = .default()

        let wv = WKWebView(frame: .zero, configuration: cfg)
        wv.navigationDelegate = context.coordinator
        wv.uiDelegate = context.coordinator
        wv.allowsBackForwardNavigationGestures = true
        wv.scrollView.bounces = true
        wv.isOpaque = false
        wv.backgroundColor = .systemBackground

        let rc = UIRefreshControl()
        rc.tintColor = UIColor(red: 0.92, green: 0.35, blue: 0.05, alpha: 1)
        rc.addTarget(context.coordinator, action: #selector(Coordinator.pullToRefresh(_:)), for: .valueChanged)
        wv.scrollView.refreshControl = rc

        context.coordinator.webView = wv
        wv.load(URLRequest(url: url))
        return wv
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        var parent: WebContainer
        weak var webView: WKWebView?
        private var observer: NSObjectProtocol?

        init(_ parent: WebContainer) {
            self.parent = parent
            super.init()
            observer = NotificationCenter.default.addObserver(
                forName: .webReload, object: nil, queue: .main
            ) { [weak self] _ in
                self?.webView?.reload()
            }
        }

        deinit {
            if let o = observer { NotificationCenter.default.removeObserver(o) }
        }

        @objc func pullToRefresh(_ sender: UIRefreshControl) {
            webView?.reload()
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            parent.loading = true
            parent.failed = false
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            parent.loading = false
            webView.scrollView.refreshControl?.endRefreshing()
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            parent.loading = false
            parent.failed = true
            webView.scrollView.refreshControl?.endRefreshing()
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            parent.loading = false
            parent.failed = true
            webView.scrollView.refreshControl?.endRefreshing()
        }

        // 处理 tel: / mailto: 等非 http 链接，交给系统
        func webView(_ webView: WKWebView,
                     decidePolicyFor navigationAction: WKNavigationAction,
                     decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            guard let u = navigationAction.request.url else {
                decisionHandler(.allow); return
            }
            let scheme = (u.scheme ?? "").lowercased()
            if !["http", "https", "about", "file", "data"].contains(scheme) {
                UIApplication.shared.open(u, options: [:], completionHandler: nil)
                decisionHandler(.cancel)
                return
            }
            decisionHandler(.allow)
        }

        func webView(_ webView: WKWebView,
                     runJavaScriptAlertPanelWithMessage message: String,
                     initiatedByFrame frame: WKFrameInfo,
                     completionHandler: @escaping () -> Void) {
            let ac = UIAlertController(title: nil, message: message, preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "好", style: .default) { _ in completionHandler() })
            topVC()?.present(ac, animated: true)
        }

        func webView(_ webView: WKWebView,
                     runJavaScriptConfirmPanelWithMessage message: String,
                     initiatedByFrame frame: WKFrameInfo,
                     completionHandler: @escaping (Bool) -> Void) {
            let ac = UIAlertController(title: nil, message: message, preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "取消", style: .cancel) { _ in completionHandler(false) })
            ac.addAction(UIAlertAction(title: "确定", style: .default) { _ in completionHandler(true) })
            topVC()?.present(ac, animated: true)
        }

        func webView(_ webView: WKWebView,
                     runJavaScriptTextInputPanelWithPrompt prompt: String,
                     defaultText: String?,
                     initiatedByFrame frame: WKFrameInfo,
                     completionHandler: @escaping (String?) -> Void) {
            let ac = UIAlertController(title: nil, message: prompt, preferredStyle: .alert)
            ac.addTextField { $0.text = defaultText }
            ac.addAction(UIAlertAction(title: "取消", style: .cancel) { _ in completionHandler(nil) })
            ac.addAction(UIAlertAction(title: "确定", style: .default) { _ in
                completionHandler(ac.textFields?.first?.text)
            })
            topVC()?.present(ac, animated: true)
        }

        // H5 调用摄像头 / 麦克风（getUserMedia）时授权
        @available(iOS 15.0, *)
        func webView(_ webView: WKWebView,
                     requestMediaCapturePermissionFor origin: WKSecurityOrigin,
                     initiatedByFrame frame: WKFrameInfo,
                     type: WKMediaCaptureType,
                     decisionHandler: @escaping (WKPermissionDecision) -> Void) {
            decisionHandler(.grant)
        }

        private func topVC() -> UIViewController? {
            let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
            let window = scenes.flatMap { $0.windows }.first { $0.isKeyWindow }
            var vc = window?.rootViewController
            while let presented = vc?.presentedViewController { vc = presented }
            return vc
        }
    }
}
