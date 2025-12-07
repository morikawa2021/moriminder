//
//  APIError.swift
//  Mamorunder
//
//  Created on 2025-11-09.
//

import Foundation

enum APIError: LocalizedError {
    case networkError
    case invalidResponse
    case timeout
    case rateLimitExceeded               // 使用量制限超過
    case invalidAPIKey                   // APIキーが無効
    case quotaExceeded                   // APIクォータ超過

    var errorDescription: String? {
        switch self {
        case .networkError:
            return "ネットワークエラーが発生しました。接続を確認してください"
        case .invalidResponse:
            return "サーバーからの応答が無効です"
        case .timeout:
            return "タイムアウトが発生しました。もう一度お試しください"
        case .rateLimitExceeded:
            return "本日の細分化回数上限に達しました。明日再度お試しください"
        case .invalidAPIKey:
            return "APIキーが無効です。開発者に連絡してください"
        case .quotaExceeded:
            return "APIの使用量上限に達しました"
        }
    }
}

