//
//  ToneEngine.swift
//  GuitarTuner
//
//  Created by albertma on 2024/11/4.
//
import AVFoundation
import AVFAudio
import Accelerate
enum EngineState:String{
    case AudioFrequencyDone = "audio frequence analysis"
    case AudioCaptureNull = "audio captured nothing"
    case AudioFrequencyAnalyseError = "audio analysis error"
}

class ToneEngine{
    
    var frequence:Float
    var volume:Float
    let audioEngine = AVAudioEngine()
    init() {
        self.frequence = 0.0
        self.volume = 0.0
    }
    
    func startCapture(callback:@escaping(EngineState, Float, Float)->Void)-> Bool{
        audioEngine.stop()
        audioEngine.reset()
        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            if buffer.frameLength > 0 {
                logger.logWithDetails("Got something from audio buffer")
                self.processAudioBuffer(buffer: buffer)
                if(self.frequence != 0.0){
                    callback(EngineState.AudioFrequencyDone, self.frequence, self.volume)
                    return
                }else{
                    callback(EngineState.AudioFrequencyAnalyseError, self.frequence, self.volume)
                }
               
            }else{
                logger.logWithDetails("Got nothing from audio buffer")
                callback(EngineState.AudioCaptureNull, self.frequence, self.volume)
            }
        }
            
        audioEngine.prepare()
        do {
            try audioEngine.start()
            logger.logWithDetails("Audio engine was started")
            return true
        } catch {
            logger.logWithDetails("Audio engine was not started: \(error.localizedDescription)", level:.error)
        }
        return false
    }
    
    func stopCapture(){
        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()
    }
    
    
    private func processAudioBuffer(buffer: AVAudioPCMBuffer){
        //process audio here.
        let frequence = analyzeFrequence(buffer: buffer)
        let volume = analyseAudioVolume(buffer: buffer)
        logger.logWithDetails("Got analyzed audio volume:\(volume) frequence: \(frequence)")
        self.frequence = frequence
        self.volume = volume

    }
    
    private func analyseAudioVolume(buffer: AVAudioPCMBuffer) -> Float{
        guard let channelData = buffer.floatChannelData?[0] else { return 0.0}
        let channelDataArray = Array(UnsafeBufferPointer(start: channelData, count: Int(buffer.frameLength)))
               
        // 计算 RMS（Root Mean Square，均方根）
        let rms = sqrt(channelDataArray.map { $0 * $0 }.reduce(0, +) / Float(channelDataArray.count))
               
        // 将 RMS 转换为分贝
        let db = 20 * log10(rms)
               
        // 检查是否超过阈值
        return db
    }
    
    private func padOrTrimBufferToPowerOfTwo(buffer: AVAudioPCMBuffer) -> [Float] {
        guard let channelData = buffer.floatChannelData?[0] else { return [] }
        
        // 获取最接近的 2 的幂次长度
        let frameLength = Int(buffer.frameLength)
        let targetLength = 1 << Int(ceil(log2(Float(frameLength))))

        // 如果长度已经是 2 的幂，直接转换为数组返回
        if frameLength == targetLength {
            return Array(UnsafeBufferPointer(start: channelData, count: frameLength))
        }
        
        // 如果长度不足则补零
        var paddedData = [Float](repeating: 0.0, count: targetLength)
        for i in 0..<min(frameLength, targetLength) {
            paddedData[i] = channelData[i]
        }
        
        return paddedData
    }
    
    private func analyzeFrequence(buffer: AVAudioPCMBuffer) -> Float {
        // 使用 padOrTrimBufferToPowerOfTwo 函数确保缓冲区大小为 2 的幂
        let paddedData = padOrTrimBufferToPowerOfTwo(buffer: buffer)
        let frameCount = paddedData.count

        // 设置 FFT 参数
        let log2n = vDSP_Length(log2(Float(frameCount)))
        guard let fftSetup = vDSP_create_fftsetup(log2n, FFTRadix(kFFTRadix2)) else {
            
            return 0.0
        }
                
        // 准备 FFT 输入和输出
        var realp = [Float](repeating: 0.0, count: frameCount / 2)
        var imagp = [Float](repeating: 0.0, count: frameCount / 2)
        var complexBuffer = DSPSplitComplex(realp: &realp, imagp: &imagp)
                
        // 将输入数据转换为复数形式
        paddedData.withUnsafeBufferPointer { dataPointer in
            dataPointer.baseAddress?.withMemoryRebound(to: DSPComplex.self, capacity: frameCount) { typeConvertedPointer in
                        vDSP_ctoz(typeConvertedPointer, 2, &complexBuffer, 1, vDSP_Length(frameCount / 2))
            }
        }
                
        // 执行 FFT
        vDSP_fft_zrip(fftSetup, &complexBuffer, 1, log2n, FFTDirection(FFT_FORWARD))
                
        // 计算幅值
        var fftMagnitudes = [Float](repeating: 0.0, count: frameCount / 2)
        vDSP.absolute(complexBuffer, result: &fftMagnitudes)
                
        vDSP_destroy_fftsetup(fftSetup)
                
        // 找到主频率
        return findDominantFrequence(fftMagnitudes, sampleRate: 44100)
    }
    
    private func findDominantFrequence(_ magnitudes: [Float], sampleRate: Float) -> Float {
        guard let maxIndex = magnitudes.firstIndex(of: magnitudes.max() ?? 0) else {
            logger.logWithDetails("firstIndex has error.", level: .error)
            return 0.0
        }
       
        let binFrequency = sampleRate / Float(magnitudes.count * 2)
        return Float(maxIndex) * binFrequency
    }
    
}
