//
//  ViewController.swift
//  WebSocketPractice
//
//  Created by Euijoon Jung on 2020/02/10.
//  Copyright © 2020 Euijoon Jung. All rights reserved.
//

import UIKit
import Starscream


enum WebSocketErrorType: CustomStringConvertible {
    case connectionFail
    
    var description: String {
        switch self {
        case .connectionFail:
            return "Connection Failed.."
        default:
            return "unknown error"
        }
    }
}

class WebSocketError: Error {
    let type: WebSocketErrorType
    init(type: WebSocketErrorType) {
        self.type = type
    }
}
//
//struct Sentence : Codable {
//    let sentence : String
//    let lang : String
//}
//
//let sentences = [Sentence(sentence: "Hello world", lang: "en"),
//                 Sentence(sentence: "Hallo Welt", lang: "de")]
//
//do {
//    let jsonData = try JSONEncoder().encode(sentences)
//    let jsonString = String(data: jsonData, encoding: .utf8)!
//    print(jsonString) // [{"sentence":"Hello world","lang":"en"},{"sentence":"Hallo Welt","lang":"de"}]
//
//    // and decode it back
//    let decodedSentences = try JSONDecoder().decode([Sentence].self, from: jsonData)
//    print(decodedSentences)
//} catch { print(error) }

struct ViewPoint: Codable {
    var x: Double
    var y: Double
}


class ViewController: UIViewController {
    var circleView: UIView!
    var webSocketTask: URLSessionWebSocketTask!
    var webSocket: WebSocket!
    
    var xCoord: Double = 0.0
    var yCoord: Double = 0.0
    
    var isConnected: Bool = false
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var responseLabel: UILabel!
    
    @IBAction func didTapSendBtn(_ sender: Any) {
        guard let text = textField.text else { return }
        
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupView()
        
        initStarScreamWebSocket()
        
//        initWebSocket()
//        receiveMessage()

    }

    func initWebSocket() {
        let urlSession = URLSession(configuration: .default)
        if let url = URL(string: "ws://ec2-52-79-72-47.ap-northeast-2.compute.amazonaws.com:8080/") {
            webSocketTask = urlSession.webSocketTask(with: url)
            webSocketTask.resume()
        }
    }
    
    func initStarScreamWebSocket() {
        if let url = URL(string: "ws://ec2-52-79-72-47.ap-northeast-2.compute.amazonaws.com:8080/") {
            webSocket = WebSocket(request: URLRequest(url: url))
            webSocket.delegate = self
            webSocket.connect()
        }
        
    }
    
    func setupView() {
        circleView = UIView(frame: CGRect(origin: view.center, size: CGSize(width: 100.0, height: 100.0)))
        
        circleView.layer.cornerRadius = 50.0
        circleView.center = view.center
        circleView.backgroundColor = .green
        view.addSubview(circleView)
        
        let gestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(circleMoved))
        circleView.addGestureRecognizer(gestureRecognizer)
    }
    
    @objc func circleMoved(_ recongnizer: UIPanGestureRecognizer) {
        
        guard isConnected else {
            initStarScreamWebSocket()
            return
        }
        
        let location = recongnizer.location(in: view)        
        let viewPoint = ViewPoint(x: Double(location.x), y: Double(location.y))
        
        
        do {
            let jsonEncoder = JSONEncoder()
            let jsonData = try jsonEncoder.encode(viewPoint)
            webSocket.write(data: jsonData) {
                print("writing...")
            }
        } catch let error {
            print("json encoding failed")
        }

//        let location = recongnizer.location(in: view)
//        let message = URLSessionWebSocketTask.Message.string("\(location)")
//
//        webSocketTask.send(message) { (error) in
//            if let error = error {
//                print("WebSocket cound'nt send message because \(error)")
//            }
//        }
    }
    
    func moveCircle(_ text: String) {
        let trimmedString = text.split(separator: ",")
        
        let firstFragment = trimmedString[0]
        let secondFragment = trimmedString[1]

        let firstStringStartIndex = firstFragment.index(firstFragment.startIndex, offsetBy: 1)
        let firstStringEndIndex = firstFragment.index(firstFragment.endIndex, offsetBy: 0)
        
        let firstString = String(firstFragment[firstStringStartIndex..<firstStringEndIndex])

        let secondStringStartIndex = secondFragment.index(secondFragment.startIndex, offsetBy: 1)
        let secondStringEndIndex = secondFragment.index(secondFragment.endIndex, offsetBy: -1)
        
        let secondString = String(secondFragment[secondStringStartIndex..<secondStringEndIndex])
        
        guard let xCoor = Double(firstString), let yCoor = Double(secondString) else { return }
        let point = CGPoint(x: xCoor, y: yCoor)
        circleView.center = point
    }
    
    func moveCircle(with viewPoint: ViewPoint) {
        let point = CGPoint(x: viewPoint.x, y: viewPoint.y)
        circleView.center = point
    }
    
    func receiveMessage() {
        webSocketTask.receive { [weak self](result) in
            switch result {
            case .failure(let error):
                self?.closeWebSocket()
                print(error)
                return
            case .success(let message):
                switch message {
                case .string(let text):
//                    self?.responseLabel.text = text
                    DispatchQueue.main.async {
                        self?.updateResponseLabel(text)
                        self?.moveCircle(text)
                    }
                    
//                    print("received string: \(text)")
                case .data(let data):
                    print("received data: \(data)")
                }
            }
            self?.receiveMessage()
        }
    }
    
    func updateResponseLabel(_ text: String) {
        responseLabel.text = text
    }
    
    func sendPing() {
        webSocketTask.sendPing { (error) in
            if let error = error {
                print("Sending Ping failed: \(error)")
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            self.sendPing()
        }
    }
    
    func closeWebSocket() {
        webSocketTask.cancel(with: .goingAway, reason: nil)
    }


}

extension ViewController: URLSessionWebSocketDelegate {
    // connection disconnected
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        print("disconnected... ")
    }
    
    // conneciton established
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        print("connected... ")
    }
}

extension ViewController: WebSocketDelegate {
    
    func didReceive(event: WebSocketEvent, client: WebSocket) {
        switch event {
        case .connected(let headers):
            isConnected = true
            print("websocket is connected: \(headers)")
        case .disconnected(let reason, let code):
            isConnected = false
            print("websocket is disconnected: \(reason) with code: \(code)")
        case .text(let string):
            print("Received text: \(string)")
        case .binary(let data):
//            let jsonString = String(data: data, encoding: .utf8)
            if let decoder = try? JSONDecoder().decode(ViewPoint.self, from: data) {
                DispatchQueue.main.async {
                    self.moveCircle(with: decoder)
                }
            }
        case .ping(_):
            print("ping..")
            break
        case .pong(_):
            print("pong..")
            break
        case .viablityChanged(_):
            print("viablityChanged...")
            break
        case .reconnectSuggested(_):
            print("reconnectSuggested...")
            break
        case .cancelled:
            print("canceleed..")
        case .error(let error):
            isConnected = false
            print("error...")
            print(error)
        }
    }
}
