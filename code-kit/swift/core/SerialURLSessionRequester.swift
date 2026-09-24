//
//  SerialURLSessionRequester.swift
//  
//
//  Created by kimi on 2026/9/23.
//

import Foundation



/**
 URLSession的简单封装 - 支持同时只有一个请求任务。
 */
final class SerialURLSessionRequester {

    private struct RequestItem {
        let request: URLRequest
        let success: (Data?, Int, URLRequest, URLResponse?) -> Void
        let fail: (Error, URLRequest) -> Void
    }

    private let session: URLSession

    // 只用于保护下面的状态
    private let stateQueue = DispatchQueue(
        label: "SerialURLSessionRequester.state"
    )

    private var requests: [RequestItem] = []
    private var isExecuting = false

    init(session: URLSession = .shared) {
        self.session = session
    }

    func request(
        _ request: URLRequest,
        success: @escaping (Data?, Int, URLRequest, URLResponse?) -> Void,
        fail: @escaping (Error, URLRequest) -> Void
    ) {
        stateQueue.async {
            self.requests.append(
                RequestItem(
                    request: request,
                    success: success,
                    fail: fail
                )
            )

            self.startNextIfNeeded()
        }
    }

    private func startNextIfNeeded() {
        dispatchPrecondition(condition: .onQueue(stateQueue))

        guard !isExecuting else {
            return
        }

        guard !requests.isEmpty else {
            return
        }

        isExecuting = true

        let item = requests.removeFirst()

        let task = session.dataTask(with: item.request) { [weak self] data, response, error in

            guard let self else {
                return
            }

            // 先执行用户回调
            if let error {
                item.fail(error, item.request)
            } else if let response = response as? HTTPURLResponse {
                item.success(
                    data,
                    response.statusCode,
                    item.request,
                    response
                )
            } else {
                let error = NSError(
                    domain: "SerialURLSessionRequester",
                    code: -1,
                    userInfo: [
                        NSLocalizedDescriptionKey: "Invalid HTTP response"
                    ]
                )

                item.fail(error, item.request)
            }

            // 用户回调结束以后，才开始下一个请求
            self.stateQueue.async {
                self.isExecuting = false
                self.startNextIfNeeded()
            }
        }

        task.resume()
    }
}
