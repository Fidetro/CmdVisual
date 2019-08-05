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
                if var url = openPanel.directoryURL {
                    let process = Process()
                    let outputPipe = Pipe()
                    NotificationCenter.default.addObserver(forName: NSNotification.Name.NSFileHandleDataAvailable, object: outputPipe.fileHandleForReading, queue: nil) { [weak self] (notification) in
                        let data = outputPipe.fileHandleForReading.availableData
                        self?.log(data: data)
                        let outputString = String(data: data, encoding: String.Encoding.utf8) ?? ""
                        if outputString != ""{
                            DispatchQueue.main.async(execute: {
                                self?.ffmpeg(with: outputString.components(separatedBy: "\n"), path: url.path)
                            })
                        }
                    }
                    
                    process.standardOutput = outputPipe
                    process.launchPath = "/bin/bash"
                    process.arguments = ["-c","cd \(url.path);ls;"]
                    process.launch()
                    process.waitUntilExit()
                    outputPipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
                }
            }
        }

        
    }
    
    func ffmpeg(with files: [String], path: String) {
        var cmds = String()
        
        for file in files {
            if file.contains(beforeTextField.stringValue) {
                let newFile = file.replacingOccurrences(of: beforeTextField.stringValue, with: afterTextField.stringValue)
                let cmd = "ffmpeg -i " + path.appending("/"+file) + " " + path.appending("/"+newFile) + ";"
                cmds.append(cmd)
            }
        }
        let process = Process()
        let outputPipe = Pipe()
        NotificationCenter.default.addObserver(forName: NSNotification.Name.NSFileHandleDataAvailable, object: outputPipe.fileHandleForReading, queue: nil) { [weak self] (notification) in
            let data = outputPipe.fileHandleForReading.availableData
            self?.log(data: data)     
        }
        
        process.standardOutput = outputPipe
        process.launchPath = "/usr/local/bin/ffmpeg"
//        process.arguments = ["-c",cmds]
        process.arguments = ["-c","ffmpeg","-i",path.appending("/"+files.first!),path.appending("/"+"1.mp3;")]
        process.launch()
        process.waitUntilExit()
        outputPipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
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
    
    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}

