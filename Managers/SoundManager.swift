import AVFoundation
import SwiftUI

final class SoundManager: ObservableObject {
    @AppStorage("soundEnabled") var soundEnabled = true

    private var players: [AVAudioPlayer] = []

    func playShoot() { play(Self.shoot) }
    func playDry() { play(Self.dry) }
    func playHit() { play(Self.hit) }
    func playStep() { play(Self.step) }
    func playReload() { play(Self.reload) }
    func playPlantBeep() { play(Self.beep) }
    func playWin() { play(Self.win) }
    func playLose() { play(Self.lose) }
    func playUI() { play(Self.ui) }

    func setEnabled(_ enabled: Bool) {
        soundEnabled = enabled
    }

    private func play(_ data: Data) {
        guard soundEnabled else { return }
        do {
            let player = try AVAudioPlayer(data: data)
            player.prepareToPlay()
            player.play()
            players.append(player)
            if players.count > 12 {
                players.removeFirst(players.count - 12)
            }
        } catch {
            return
        }
    }

    private static let shoot = Synth.noise(duration: 0.07, volume: 0.22, color: 0.35)
    private static let dry = Synth.tone(frequency: 140, duration: 0.05, volume: 0.12)
    private static let hit = Synth.noise(duration: 0.05, volume: 0.2, color: 0.8)
    private static let step = Synth.tone(frequency: 90, duration: 0.06, volume: 0.1)
    private static let reload = Synth.tone(frequency: 220, duration: 0.09, volume: 0.12)
    private static let beep = Synth.tone(frequency: 880, duration: 0.1, volume: 0.14)
    private static let win = Synth.tone(frequency: 523, duration: 0.22, volume: 0.16)
    private static let lose = Synth.tone(frequency: 196, duration: 0.28, volume: 0.16)
    private static let ui = Synth.tone(frequency: 660, duration: 0.05, volume: 0.1)
}

private enum Synth {
    static func tone(frequency: Float, duration: Double, volume: Float) -> Data {
        let rate = 22050
        let count = Int(Double(rate) * duration)
        var samples = [Float](repeating: 0, count: count)
        for i in 0..<count {
            let t = Float(i) / Float(rate)
            let env = 1 - Float(i) / Float(max(1, count))
            samples[i] = sin(2 * .pi * frequency * t) * volume * env
        }
        return wav(samples)
    }

    static func noise(duration: Double, volume: Float, color: Float) -> Data {
        let rate = 22050
        let count = Int(Double(rate) * duration)
        var samples = [Float](repeating: 0, count: count)
        var prev: Float = 0
        for i in 0..<count {
            let white = Float.random(in: -1...1)
            prev = prev * color + white * (1 - color)
            let env = 1 - Float(i) / Float(max(1, count))
            samples[i] = prev * volume * env
        }
        return wav(samples)
    }

    private static func wav(_ samples: [Float]) -> Data {
        let dataSize = UInt32(samples.count * 2)
        var data = Data()
        func ascii(_ s: String) { data.append(contentsOf: s.utf8) }
        func u16(_ v: UInt16) {
            var x = v.littleEndian
            data.append(Data(bytes: &x, count: 2))
        }
        func u32(_ v: UInt32) {
            var x = v.littleEndian
            data.append(Data(bytes: &x, count: 4))
        }
        ascii("RIFF")
        u32(36 + dataSize)
        ascii("WAVEfmt ")
        u32(16)
        u16(1)
        u16(1)
        u32(22050)
        u32(44100)
        u16(2)
        u16(16)
        ascii("data")
        u32(dataSize)
        for sample in samples {
            let clipped = max(-1, min(1, sample))
            let value = Int16(clipped * Float(Int16.max))
            var x = value.littleEndian
            data.append(Data(bytes: &x, count: 2))
        }
        return data
    }
}
