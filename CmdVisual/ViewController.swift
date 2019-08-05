//
//  ViewController.swift
//  CmdVisual
//
//  Created by Fidetro on 2019/8/4.
//  Copyright © 2019 karim. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
    
    @IBOutlet weak var beforeTextField: NSTextField!
    @IBOutlet var logTextView: NSTextView!
    @IBOutlet weak var afterTextField: NSTextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        logTextView.isEditable = false
    }
  

    @IBAction func selectFileDocAction(_ sender: NSButton) {
        
        guard beforeTextField.stringValue.contains(".") ||
            afterTextField.stringValue.contains(".") else {
                log(text: "输入正确的格式名")
            return
        }
        let openPanel = NSOpenPanel()
        let dURL = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).last!
        openPanel.directoryURL = dURL
        openPanel.message = "选择路径"
        openPanel.canChooseDirectories = true
        guard let window = NSApp.mainWindow else {
            return
        }
        openPanel.beginSheetModal(for: window) { (response) in
            if response == .OK {
                if let url = openPanel.directoryURL {
                    let process = Process()
                    let outputPipe = Pipe()
                    if url.path.contains(" ") {
                        self.log(text: "文件夹路径不要带空格")
                        return
                    }
                    process.standardOutput = outputPipe
                    process.launchPath = "/bin/bash"
                    process.arguments = ["-c","cd \(url.path);ls;"]
                    process.launch()
                    let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
                    process.waitUntilExit()
                    self.log(data: data)
                    let outputString = String(data: data, encoding: String.Encoding.utf8) ?? ""
                    if outputString != ""{
                        DispatchQueue.main.async(execute: {
                            let files = outputString.components(separatedBy: "\n")
                            for file in files {
                                if file.contains(self.beforeTextField.stringValue ) {
                                    self.ffmpeg(with: file, path: url.path)
                                }
                            }                            
                        })
                    }
                }
            }
        }

        
    }
    
    func ffmpeg(with file: String, path: String) {
        
        let process = Process()
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        let inputPipe = Pipe()
        let newFile = file.replacingOccurrences(of: beforeTextField.stringValue, with: afterTextField.stringValue)

        
        process.standardOutput = outputPipe
        process.standardError = errorPipe
        
        errorPipe.fileHandleForReading.readabilityHandler = { handler in
            let data = handler.availableData
            self.log(data: data)
        }
        outputPipe.fileHandleForReading.readabilityHandler = { handler in
            let data = handler.availableData
            self.log(data: data)
        }
        
        process.standardOutput = outputPipe
        process.standardInput = inputPipe
        process.launchPath = "/usr/local/bin/ffmpeg"
        process.arguments = ["-i",path.appending("/"+file),path.appending("/"+newFile)]
        do{
            try process.run()
        }catch{
            log(text: error.localizedDescription)
        }
        
    }
    
    
    func log(data: Data) {
        let output = data
        let outputString = String(data: output, encoding: String.Encoding.utf8) ?? ""
        
        if outputString != ""{
            DispatchQueue.main.async(execute: {
                let previousOutput = self.logTextView.string
                let nextOutput = previousOutput + "\n" + outputString
                self.logTextView.string = nextOutput
                let range = NSRange(location:nextOutput.count,length:0)
                self.logTextView.scrollRangeToVisible(range)
            })
        }
    }
    
    func log(text: String) {
        let outputString = text
        
        if outputString != ""{
            DispatchQueue.main.async(execute: {
                let previousOutput = self.logTextView.string
                let nextOutput = previousOutput + "\n" + outputString
                self.logTextView.string = nextOutput
                let range = NSRange(location:nextOutput.count,length:0)
                self.logTextView.scrollRangeToVisible(range)
            })
        }
    }
    
    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}

