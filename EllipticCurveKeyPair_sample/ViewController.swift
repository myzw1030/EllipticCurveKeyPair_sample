//
//  ViewController.swift
//  EllipticCurveKeyPair_sample
//
//  Created by USER on 2024/03/02.
//

import UIKit

import EllipticCurveKeyPair

struct KeyPair {
    static let manager: EllipticCurveKeyPair.Manager = {
        let publicAccessControl = EllipticCurveKeyPair.AccessControl(
            protection: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
            flags: [])
        let privateAccessControl = EllipticCurveKeyPair.AccessControl(
            protection: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
            flags: {
                return EllipticCurveKeyPair.Device.hasSecureEnclave
                ? [.userPresence, .privateKeyUsage]
                : [.userPresence]
            }()
        )
        let config = EllipticCurveKeyPair.Config(
            publicLabel: "payment.sign.public",
            privateLabel: "payment.sign.private",
            operationPrompt: "Confirm payment",
            publicKeyAccessControl: publicAccessControl,
            privateKeyAccessControl: privateAccessControl,
            token: .secureEnclaveIfAvailable)
        return EllipticCurveKeyPair.Manager(config: config)
    }()
}


class ViewController: UIViewController {
    
    @IBOutlet weak var originalTextLabel: UILabel!
    @IBOutlet weak var encryptButton: UIButton!
    @IBOutlet weak var decryptButton: UIButton!
    @IBOutlet weak var publicKeyButton: UIButton!
    
    let originalText = "これは秘密のメッセージです"
    // 暗号化されたデータを保存する
    var encryptedData: Data?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // オリジナルテキスト
        originalTextLabel.text = originalText
        // ボタンのテキスト
        encryptButton.setTitle("暗号化", for: .normal)
        decryptButton.setTitle("復号化", for: .normal)
        publicKeyButton.setTitle("公開鍵取得", for: .normal)
    }
    
    @IBAction func encryptButtonTapped(_ sender: UIButton) {
        guard let textData = originalText.data(using: .utf8) else { return }
        do {
            
            let encryptedData = try KeyPair.manager.encrypt(textData, hash: .sha256)
            // 暗号化されたデータを保存
            self.encryptedData = encryptedData
            // 表示用にBase64エンコード
            let encryptedString = encryptedData.base64EncodedString()
            // 暗号化されたテキストを表示
            originalTextLabel.text = encryptedString
        } catch {
            print("暗号化に失敗しました: \(error)")
        }
    }
    
    @IBAction func decryptButtonTapped(_ sender: UIButton) {
        guard let encryptedData = self.encryptedData else { return }
        // バックグラウンドスレッドで復号化処理を実行
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let decryptedData = try KeyPair.manager.decrypt(encryptedData, hash: .sha256)
                let decryptedString = String(data: decryptedData, encoding: .utf8)
                // メインスレッドでUIを更新(復号化されたテキストを表示)
                DispatchQueue.main.async {
                    self.originalTextLabel.text = decryptedString
                }
            } catch {
                print("復号化に失敗しました: \(error)")
            }
        }
    }
    
    @IBAction func getPublicKeyButtonTapped(_ sender: UIButton) {
        do {
            // 公開鍵を取得
            let publicKey = try KeyPair.manager.publicKey().data().PEM
            // デバッグでは、公開鍵をPEM形式で取得する
            print("Public Key:", publicKey)
        } catch {
            print("公開鍵の取得に失敗しました: \(error)")
        }
    }
}

