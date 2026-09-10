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
    func playExplosion() { play(Self.explosion) }

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
            if players.count > 16 {
                players.removeFirst(players.count - 16)
            }
        } catch {
            return
        }
    }

    private static let shoot = Synth.gunshot()
    private static let dry = Synth.tone(frequency: 140, duration: 0.05, volume: 0.12)
    private static let hit = Synth.noise(duration: 0.06, volume: 0.22, color: 0.72)
    private static let step = Synth.noise(duration: 0.05, volume: 0.09, color: 0.88)
    private static let reload = Synth.reload()
    private static let beep = Synth.tone(frequency: 920, duration: 0.08, volume: 0.15)
    private static let win = Synth.chord(frequencies: [523, 659, 784], duration: 0.28, volume: 0.14)
    private static let lose = Synth.fall(from: 220, to: 90, duration: 0.36, volume: 0.16)
    private static let ui = Synth.tone(frequency: 660, duration: 0.05, volume: 0.1)
    private static let explosion = Synth.explosion()
}

private enum Synth {
    static func gunshot() -> Data {
        mix(
            noise(duration: 0.09, volume: 0.28, color: 0.22),
            tone(frequency: 78, duration: 0.12, volume: 0.2),
            tone(frequency: 190, duration: 0.05, volume: 0.1)
        )
    }

    static func reload() -> Data {
        mix(
            click(at: 0, frequency: 340, duration: 0.18),
            click(at: 0.09, frequency: 210, duration: 0.18)
        )
    }

    static func explosion() -> Data {
        mix(
            noise(duration: 0.42, volume: 0.32, color: 0.55),
            tone(frequency: 55, duration: 0.4, volume: 0.22)
        )
    }

    static func tone(frequency: Float, duration: Double, volume: Float) -> Data {
        wav(toneSamples(frequency: frequency, duration: duration, volume: volume))
    }

    static func noise(duration: Double, volume: Float, color: Float) -> Data {
        wav(noiseSamples(duration: duration, volume: volume, color: color))
    }

    static func chord(frequencies: [Float], duration: Double, volume: Float) -> Data {
        var acc = [Float](repeating: 0, count: Int(22050 * duration))
        for f in frequencies {
            let s = toneSamples(frequency: f, duration: duration, volume: volume / Float(max(1, frequencies.count)))
            add(&acc, s)
        }
        return wav(acc)
    }

    static func fall(from: Float, to: Float, duration: Double, volume: Float) -> Data {
        let rate: Float = 22050
        let count = Int(Double(rate) * duration)
        var samples = [Float](repeating: 0, count: count)
        for i in 0..<count {
            let t = Float(i) / Float(max(1, count - 1))
            let freq = from + (to - from) * t
            let env = 1 - t
            samples[i] = sin(2 * .pi * freq * Float(i) / rate) * volume * env
        }
        return wav(samples)
    }

    private static func click(at offset: Double, frequency: Float, duration: Double) -> Data {
        let rate = 22050
        let count = Int(Double(rate) * duration)
        var samples = [Float](repeating: 0, count: count)
        let start = Int(Double(rate) * offset)
        let clickLen = Int(0.045 * Double(rate))
        for i in 0..<clickLen {
            let idx = start + i
            guard idx < count else { break }
            let env = 1 - Float(i) / Float(clickLen)
            samples[idx] = sin(2 * .pi * frequency * Float(i) / Float(rate)) * 0.16 * env
        }
        return wav(samples)
    }

    private static func toneSamples(frequency: Float, duration: Double, volume: Float) -> [Float] {
        let rate: Float = 22050
        let count = Int(Double(rate) * duration)
        var samples = [Float](repeating: 0, count: count)
        for i in 0..<count {
            let t = Float(i) / rate
            let env = 1 - Float(i) / Float(max(1, count))
            samples[i] = sin(2 * .pi * frequency * t) * volume * env
        }
        return samples
    }

    private static func noiseSamples(duration: Double, volume: Float, color: Float) -> [Float] {
        let count = Int(22050 * duration)
        var samples = [Float](repeating: 0, count: count)
        var prev: Float = 0
        for i in 0..<count {
            let white = Float.random(in: -1...1)
            prev = prev * color + white * (1 - color)
            let env = 1 - Float(i) / Float(max(1, count))
            samples[i] = prev * volume * env
        }
        return samples
    }

    private static func mix(_ layers: Data...) -> Data {
        var acc: [Float] = []
        for layer in layers {
            let samples = pcm(from: layer)
            if samples.count > acc.count {
                acc.append(contentsOf: repeatElement(0, count: samples.count - acc.count))
            }
            add(&acc, samples)
        }
        return wav(acc)
    }

    private static func add(_ acc: inout [Float], _ extra: [Float]) {
        if extra.count > acc.count {
            acc.append(contentsOf: repeatElement(0, count: extra.count - acc.count))
        }
        for i in extra.indices {
            acc[i] += extra[i]
        }
    }

    private static func pcm(from wavData: Data) -> [Float] {
        let header = 44
        guard wavData.count > header else { return [] }
        let payload = wavData.dropFirst(header)
        var samples = [Float]()
        samples.reserveCapacity(payload.count / 2)
        var i = payload.startIndex
        while i + 1 < payload.endIndex {
            let lo = UInt16(payload[i])
            let hi = UInt16(payload[i + 1]) << 8
            let value = Int16(bitPattern: lo | hi)
            samples.append(Float(value) / Float(Int16.max))
            i = payload.index(i, offsetBy: 2)
        }
        return samples
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
