//
//  SessionHandler.swift
//  DlibTester
//
//  Created by Vicki Larkin on 05/07/2018.
//  Copyright © 2018 Vicki Hardy. All rights reserved.
//


import AVFoundation
import Foundation
import UIKit
import CoreImage


class SessionHandler : NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureMetadataOutputObjectsDelegate, AVCaptureAudioDataOutputSampleBufferDelegate {
    
    // AVFoundation video recording properties
    var session = AVCaptureSession()
    var videoCaptureDevice: AVCaptureDevice?
    let layer = AVSampleBufferDisplayLayer()
    let sampleQueue = DispatchQueue(label: "com.zweigraf.DisplayLiveSamples.sampleQueue", attributes: [])
    let faceQueue = DispatchQueue(label: "com.zweigraf.DisplayLiveSamples.faceQueue", attributes: [])
    var videoDataOutput = AVCaptureVideoDataOutput()
    var audioDataOutput = AVCaptureAudioDataOutput()
    
    // Dlib
    let wrapper = DlibWrapper()
    
    // AVAssetWriter
    var isRecording = false
    var videoWriter: AVAssetWriter!
    var videoWriterInput: AVAssetWriterInput!
    var audioWriterInput: AVAssetWriterInput!
    var sessionAtSourceTime: CMTime?
    var outputUrl: URL?
    
    // face detector
    var faceDetector = CIDetector(ofType: CIDetectorTypeFace, context: nil, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh,
                                                                                      CIDetectorTracking: true])!
    
    var currentMetadata: [AnyObject]
    
    override init() {
        currentMetadata = []
        super.init()
    }
    
    // File Manager
    func videoFileLocation() -> URL {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString
        let videoOutputUrl = URL(fileURLWithPath: documentsPath.appendingPathComponent("videoFile")).appendingPathExtension("mp4")
        do {
            if FileManager.default.fileExists(atPath: videoOutputUrl.path) {
                try FileManager.default.removeItem(at: videoOutputUrl)
                print("file removed")
            }
        } catch {
            print(error)
        }
        
        return videoOutputUrl
    }

    // MARK: Set up camera
    func openSession() {
        
        // size of the output video will be 720x1280
        session.sessionPreset = .hd1280x720
        
        // set up camera
        videoCaptureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: AVMediaType.video, position: .front)
        
        if videoCaptureDevice != nil {
            do {
                // add the input from the device
                try session.addInput(AVCaptureDeviceInput(device: videoCaptureDevice!))
                // set up the microphone
                if let audioInput = AVCaptureDevice.default(for: AVMediaType.audio) {
                    try session.addInput(AVCaptureDeviceInput(device: audioInput))
                }
                
                // define video output
                videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
                ]
                videoDataOutput.alwaysDiscardsLateVideoFrames = true

                let metaOutput = AVCaptureMetadataOutput()
                
                if session.canAddOutput(videoDataOutput) {
                    videoDataOutput.setSampleBufferDelegate(self, queue: sampleQueue)
                    print("videodataoutput added")
                    session.addOutput(videoDataOutput)
                }
                
//                if session.canAddOutput(audioDataOutput) {
//                    audioDataOutput.setSampleBufferDelegate(self, queue: sampleQueue)
//                    session.addOutput(audioDataOutput)
//                    print("audiodataoutput added")
//                }
                
                // define metadata output
                if session.canAddOutput(metaOutput) {
                    metaOutput.setMetadataObjectsDelegate(self, queue: faceQueue)
                    session.addOutput(metaOutput)
                    print("metaoutput added")
                }
                
                // availableMetadataObjectTypes change when output is added to session.
                // before it is added, availableMetadataObjectTypes is empty
                metaOutput.metadataObjectTypes = [AVMetadataObject.ObjectType.face]

                session.commitConfiguration()

                // prepare the dlib face detection
                wrapper?.prepare()

                // start the session
                session.startRunning()
                
            } catch {
                print(error)
            }
        }
    }

        ////////////////////////
        
//        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: AVMediaType.video, position: .front) else { return }
//
//        let input = try! AVCaptureDeviceInput(device: device)
//
//        videoDataOutput.setSampleBufferDelegate(self, queue: sampleQueue)
//
//        let metaOutput = AVCaptureMetadataOutput()
//        metaOutput.setMetadataObjectsDelegate(self, queue: faceQueue)
//
//        session.beginConfiguration()
//
//        if session.canAddInput(input) {
//            session.addInput(input)
//        }
//        if session.canAddOutput(videoDataOutput) {
//            session.addOutput(videoDataOutput)
//        }
//        if session.canAddOutput(metaOutput) {
//            session.addOutput(metaOutput)
//        }
//
//        session.commitConfiguration()
//
//        let settings: [AnyHashable: Any] = [kCVPixelBufferPixelFormatTypeKey as AnyHashable: Int(kCVPixelFormatType_32BGRA)]
//        videoDataOutput.videoSettings = settings as! [String : Any]
//
//        // availableMetadataObjectTypes change when output is added to session.
//        // before it is added, availableMetadataObjectTypes is empty
//        metaOutput.metadataObjectTypes = [AVMetadataObject.ObjectType.face]
//
//        wrapper?.prepare()
//
//        session.startRunning()
//    }
    
    func closeSession() {
        session.stopRunning()
    }
    
    // Mark: Create AVAssetWriter
    func createAssetWriter() {
        
        do {
            outputUrl = videoFileLocation()
            videoWriter = try AVAssetWriter(outputURL: outputUrl!, fileType: AVFileType.mov)
            
            // add video input
            videoWriterInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: [
                AVVideoCodecKey : AVVideoCodecType.h264,
                AVVideoWidthKey : 480,
                AVVideoHeightKey : 853,
                AVVideoCompressionPropertiesKey : [
                    AVVideoAverageBitRateKey : 1000000,
                ],
                ])
            
            
            //  var pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: videoWriterInput!, sourcePixelBufferAttributes: [ kCVPixelBufferPixelFormatTypeKey as String : Int(kCVPixelFormatType_32BGRA)])
            
            videoWriterInput.expectsMediaDataInRealTime = true
            
            if videoWriter.canAdd(videoWriterInput) {
                videoWriter.add(videoWriterInput)
                print("video input added")
            } else {
                print("no input added")
            }
            
            // add audio input
            audioWriterInput = AVAssetWriterInput(mediaType: AVMediaType.audio, outputSettings: [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVNumberOfChannelsKey: 1,
                AVSampleRateKey: 44100,
                AVEncoderBitRateKey: 64000,
                ])
            
            audioWriterInput.expectsMediaDataInRealTime = true
            
            if videoWriter.canAdd(audioWriterInput!) {
                videoWriter.add(audioWriterInput!)
                print("audio input added")
            }
            
            videoWriter.startWriting()
            
        } catch let error {
            debugPrint(error.localizedDescription)
        }
    }
    
    // MARK: Helper functions
    func canWrite() -> Bool {
        return isRecording && videoWriter != nil && videoWriter?.status == .writing
    }
    
    // start the AVAssetWriter
    func start() {
        guard !isRecording else { return }
        isRecording = true
        sessionAtSourceTime = nil
        createAssetWriter()

        if videoWriter.status == .writing {
            print("status writing")
        } else if videoWriter.status == .failed {
            print("status failed")
        } else if videoWriter.status == .cancelled {
            print("status cancelled")
        } else if videoWriter.status == .unknown {
            print("status unknown")
        } else {
            print("status completed")
        }
        
    }
    
    // Stop the AVAssetWriter
    func stop() {
        guard isRecording else { return }
        isRecording = false
        videoWriterInput.markAsFinished()
        print("marked as finished")
        videoWriter.finishWriting { [weak self] in
            self?.sessionAtSourceTime = nil
            //self?.outputUrl = self?.videoWriter.outputURL
            //guard let url = self?.videoWriter.outputURL else { return }
            //print("This is the url: \(url)")
            //self?.outputUrl = url    
        }
        
        session.stopRunning()
    }
    
    
    // MARK: AVCaptureVideoDataOutputSampleBufferDelegate
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        
        
        // Convert current frame to CIImage
//        let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
//        let attachments = CMCopyDictionaryOfAttachments(kCFAllocatorDefault, pixelBuffer!, CMAttachmentMode(kCMAttachmentMode_ShouldPropagate)) as? [String:Any]
//        let ciImage = CIImage(cvImageBuffer: pixelBuffer!, options: attachments)
//
//        // Detects faces based on your ciimage
//        let features = faceDetector.features(in: ciImage, options: [
//            CIDetectorSmile: true,
//            CIDetectorEyeBlink: true,
//            ]).compactMap ({ $0 as? CIFaceFeature })
//
//        let bounds = faceDetector
//
//        // Retreive frame of your buffer
//        let desc = CMSampleBufferGetFormatDescription(sampleBuffer)
//        let bufferFrame = CMVideoFormatDescriptionGetCleanAperture(desc!, false)
        
        if output == videoDataOutput {
            //print("videodata")
            if !currentMetadata.isEmpty {
                let boundsArray = currentMetadata
                    .compactMap { $0 as? AVMetadataFaceObject }
                    .map { (faceObject) -> NSValue in
                        let convertedObject = output.transformedMetadataObject(for: faceObject, connection: connection)
                        return NSValue(cgRect: convertedObject!.bounds)
                }
                
                wrapper?.doWork(on: sampleBuffer, inRects: boundsArray)
            }
            layer.enqueue(sampleBuffer)
        }
        
        let writable = canWrite()
        
        if writable,
            sessionAtSourceTime == nil {
            // start writing
            sessionAtSourceTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
            videoWriter.startSession(atSourceTime: sessionAtSourceTime!)
            //print("Writing")
        }

        if writable,
            output == videoDataOutput,
            videoWriterInput.isReadyForMoreMediaData  {
            // write video buffer
            videoWriterInput.append(sampleBuffer)
            //print("video buffering")
        }
//        } else if writable,
//            output == audioDataOutput,
//            (audioWriterInput.isReadyForMoreMediaData) {
//            // write audio buffer
//            audioWriterInput?.append(sampleBuffer)
//            print("audio buffering")
//        }
        
    }
    
    // MARK: AVCaptureVideoDataOutputSampleBufferDelegate Frames Discarded
    func captureOutput(_ output: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        //print("DidDropSampleBuffer")
        
        connection.videoOrientation = AVCaptureVideoOrientation.portrait
        
        if connection.isVideoMirroringSupported {
            connection.isVideoMirrored = true
        }
        
        
        
    }
    
    // MARK: AVCaptureMetadataOutputObjectsDelegate
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        currentMetadata = metadataObjects as [AnyObject]
        
        
    }
}
