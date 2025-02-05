import AVFoundation
import Foundation

class RecorderFileDelegate: NSObject, AudioRecordingFileDelegate, AVAudioRecorderDelegate {
  private var audioRecorder: AVAudioRecorder?
  private var path: String?
  private var parentRecorder: Recorder?
    
  func getParentRecorder()-> Recorder? {
    return parentRecorder
  } 
    

  func start(config: RecordConfig, path: String, parentRecorder: Recorder) throws {
    try deleteFile(path: path)

    try initAVAudioSession(config: config)

    let url = URL(fileURLWithPath: path)

    let recorder = try AVAudioRecorder(url: url, settings: getOutputSettings(config: config))

    recorder.delegate = self
    recorder.isMeteringEnabled = true
    recorder.prepareToRecord()
    
    recorder.record()
    
    audioRecorder = recorder
    self.parentRecorder = parentRecorder
    self.path = path
  }

  func stop(completionHandler: @escaping (String?) -> ()) {
    audioRecorder?.stop()
    audioRecorder = nil

    completionHandler(path)
    
    path = nil
  }
  
  func pause() {
    print("xxxx pause called")
    guard let recorder = audioRecorder, recorder.isRecording else {
      return
    }
    print("xxxx pause call executed")
    recorder.pause()
  }
  
  func resume() {
    audioRecorder?.record()
  }

  func cancel() throws {
    guard let path = path else { return }
    
    stop { path in }
    
    try deleteFile(path: path)
  }
  
  func getAmplitude() -> Float {
    audioRecorder?.updateMeters()
    return audioRecorder?.averagePower(forChannel: 0) ?? -160
  }
  
  func dispose() {
    stop { path in }
  }

  func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
      // Audio recording has stopped
  }
  
  private func deleteFile(path: String) throws {
    do {
      let fileManager = FileManager.default
      
      if fileManager.fileExists(atPath: path) {
        try fileManager.removeItem(atPath: path)
      }
    } catch {
      throw RecorderError.error(message: "Failed to delete previous recording", details: error.localizedDescription)
    }
  }
}
