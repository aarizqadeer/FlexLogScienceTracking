import SwiftUI
import WebKit

struct TrainingHostView: View {
    let trainingLink: URL

    @State private var isLoading = true
    @State private var hasCompletedInitialLoad = false

    var body: some View {
        ZStack {
            TrainingRepresentable(trainingLink: trainingLink,
                                     isLoading: $isLoading,
                                     hasCompletedInitialLoad: $hasCompletedInitialLoad)
                .ignoresSafeArea()
            if isLoading && !hasCompletedInitialLoad {
                Color.black.ignoresSafeArea()
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
            }
        }
        .statusBarHidden(true)
        .onAppear {
            TrainingOrientationManager.setTrainingScreenActive(true)
        }
        .onDisappear {
            TrainingOrientationManager.setTrainingScreenActive(false)
        }
    }
}

private struct TrainingRepresentable: UIViewRepresentable {
    let trainingLink: URL
    @Binding var isLoading: Bool
    @Binding var hasCompletedInitialLoad: Bool

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let trainingView = WKWebView(frame: .zero, configuration: config)
        trainingView.navigationDelegate = context.coordinator
        trainingView.allowsBackForwardNavigationGestures = false
        trainingView.scrollView.contentInsetAdjustmentBehavior = .never
        trainingView.scrollView.showsHorizontalScrollIndicator = false
        trainingView.scrollView.showsVerticalScrollIndicator = false
        trainingView.backgroundColor = .black
        trainingView.scrollView.backgroundColor = .black
        return trainingView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        let coordinator = context.coordinator
        guard coordinator.lastLoadedRequest != trainingLink else { return }
        coordinator.prepareForInitialLoad(of: trainingLink)
        let request = URLRequest(url: trainingLink)
        uiView.load(request)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(isLoading: $isLoading, hasCompletedInitialLoad: $hasCompletedInitialLoad)
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        @Binding var isLoading: Bool
        @Binding var hasCompletedInitialLoad: Bool
        var lastLoadedRequest: URL?

        init(isLoading: Binding<Bool>, hasCompletedInitialLoad: Binding<Bool>) {
            self._isLoading = isLoading
            self._hasCompletedInitialLoad = hasCompletedInitialLoad
        }

        func prepareForInitialLoad(of request: URL) {
            lastLoadedRequest = request
            hasCompletedInitialLoad = false
            isLoading = true
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            guard !hasCompletedInitialLoad else { return }
            isLoading = true
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            isLoading = false
            if !hasCompletedInitialLoad {
                hasCompletedInitialLoad = true
            }
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            isLoading = false
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            isLoading = false
        }
    }
}

