//
//  ViewController.swift
//  coffeeDetec
//
//  Created by Julius Schmid on 03.04.22.
//

import UIKit
import CoreNFC


class ViewController: UIViewController, NFCNDEFReaderSessionDelegate, UITextFieldDelegate {

    // MARK: -Outlets und Variablen
   
    @IBOutlet weak var kaffeeTagAuslesenButton: UIButton!
    @IBOutlet weak var neuerKaffeeTagButton: UIButton!
    
    @IBOutlet weak var herstellerTextField: UITextField!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var bohnenartenTextField: UITextField!
    @IBOutlet weak var bohnenherkunftTextField: UITextField!
    @IBOutlet weak var roestdatumTextField: UITextField!
    @IBOutlet weak var mahlgradTextField: UITextField!
    @IBOutlet weak var bezugsadresseTextField: UITextField!
    @IBOutlet weak var internetadresseTextField: UITextField!
    @IBOutlet weak var roestgradTextField: UITextField!
    @IBOutlet weak var saeureintensitaetTextField: UITextField!
    
    
    var session: NFCNDEFReaderSession?
    
    var hersteller = ""
    var name = ""
    var bohnenArten = ""
    var bohnenHerkunft = ""
    var roestDatum = ""
    var mahlGrad = ""
    var bezugsAdresse = ""
    var internetAdresse = ""
    var roestGrad = ""
    var saeureIntensitaet = ""
   

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.

    }

    
    // NFT Tag wird gescannt und es werden ihm Daten übergeben
    @IBAction func startScanningAndWrite(_ sender: UIButton) {
   
        guard NFCNDEFReaderSession.readingAvailable else {
               let alertController = UIAlertController(
                   title: "KaffeeTag scannen nicht verfügbar",
                   message: "Dieses Gerät kann keine KaffeeTags scannen.",
                   preferredStyle: .alert
               )
               alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
               self.present(alertController, animated: true, completion: nil)
               return
           }
        
        hersteller = herstellerTextField.text!
        name = nameTextField.text!
        bohnenArten = bohnenartenTextField.text!
        bohnenHerkunft = bohnenherkunftTextField.text!
        roestDatum = roestdatumTextField.text!
        mahlGrad = mahlgradTextField.text!
        bezugsAdresse = bezugsadresseTextField.text!
        internetAdresse = internetadresseTextField.text!
        roestGrad = roestgradTextField.text!
        saeureIntensitaet = saeureintensitaetTextField.text!
        
           session = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: true)
           session?.alertMessage = "Halte dein iPhone nahe an dein KaffeeTag um ihn hinzuzufügen."
           session?.begin()
       }
    
    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        
    }

    func readerSession(_ session: NFCNDEFReaderSession, didDetect tags: [NFCNDEFTag]) {
    
        
        var infos: String = "\(hersteller), \(name), \(bohnenArten), \(roestDatum), \(mahlGrad), \(bezugsAdresse), \(internetAdresse), \(roestGrad), \(saeureIntensitaet)"
        var infosToUint8: [UInt8] = [UInt8](infos.utf8)
//        var hersteller: String = "\(hersteller)"
//        var herstellerToUint8: [UInt8] = [UInt8](hersteller.utf8)
//
//        var name: String = "\(name)"
//        var nameToUint8: [UInt8] = [UInt8](name.utf8)
//
//        var hersteller: String = "\(hersteller)"
//        var infoToUint8: [UInt8] = [UInt8](hersteller.utf8)
//
//


        
   
        if tags.count > 1 {
                // Restart polling in 500 milliseconds.
                let retryInterval = DispatchTimeInterval.milliseconds(500)
                session.alertMessage = "Mehr als ein KaffeeTag wurde entdeckt. Du kannst nur einen KafeeTag gleichzeitig scannen."
                DispatchQueue.global().asyncAfter(deadline: .now() + retryInterval, execute: {
                    session.restartPolling()
                })
                return
            }
            
            // Connect to the found tag and write an NDEF message to it.
            let tag = tags.first!
            session.connect(to: tag, completionHandler: { (error: Error?) in
                if nil != error {
                    session.alertMessage = "Verbindung zu KaffeeTag nicht möglich."
                    session.invalidate()
                    return
                }
                
                tag.queryNDEFStatus(completionHandler: { (ndefStatus: NFCNDEFStatus, capacity: Int, error: Error?) in
                    guard error == nil else {
                        session.alertMessage = "Nicht möglich den Status des KaffeeTags auszulesen."
                        session.invalidate()
                        return
                    }

                    switch ndefStatus {
                    case .notSupported:
                        session.alertMessage = "KaffeeTag unterstützt NDEF nicht."
                        session.invalidate()
                    case .readOnly:
                        session.alertMessage = "KaffeeTag ist schreibgeschützt"
                        session.invalidate()
                    case .readWrite:
                        tag.writeNDEF(.init(records: [.init(format: .nfcWellKnown, type: Data([06]), identifier: Data([0x0C]), payload: Data(infosToUint8))]), completionHandler: { (error: Error?) in
                            if nil != error {
                                session.alertMessage = "Fehler beim schreiben der NDEF Nachricht: \(error!)"
                            } else {
                                session.alertMessage = "NDEF erfolgreich auf KaffeeTag geschrieben"
                            }
                            session.invalidate()
                        })
                       
                        
                    @unknown default:
                        session.alertMessage = "Unbekannter KaffeeTag status."
                        session.invalidate()
                    }
                })
            })
    
    }
    func readerSessionDidBecomeActive(_ session: NFCNDEFReaderSession) {
        
    }
    
    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        // Check the invalidation reason from the returned error.
           if let readerError = error as? NFCReaderError {
               // Show an alert when the invalidation reason is not because of a
               // successful read during a single-tag read session, or because the
               // user canceled a multiple-tag read session from the UI or
               // programmatically using the invalidate method call.
               if (readerError.code != .readerSessionInvalidationErrorFirstNDEFTagRead)
                   && (readerError.code != .readerSessionInvalidationErrorUserCanceled) {
                   let alertController = UIAlertController(
                       title: "Session Invalidated",
                       message: error.localizedDescription,
                       preferredStyle: .alert
                   )
                   alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                   DispatchQueue.main.async {
                       self.present(alertController, animated: true, completion: nil)
                   }
               }
           }

           // To read new tags, a new session instance is required.
           self.session = nil
    }

    


}
