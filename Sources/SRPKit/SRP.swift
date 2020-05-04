import BigNum
import Crypto
import Foundation

/// Wrapper for keys used by SRP
public struct SRPKey {
    public let bytes: [UInt8]
    public var number: BigNum? { return BigNum(bytes: bytes) }
    
    public init(_ bytes: [UInt8]) {
        self.bytes = bytes
    }
    
    public init(_ number: BigNum) {
        self.bytes = number.bytes
    }
}

/// Contains common code used by both client and server SRP code
struct SRP<H: HashFunction> {

    /// pad to a certain size by prefixing with zeros
    static func pad(_ data: [UInt8], to size: Int) -> [UInt8] {
        let padSize = size - data.count
        guard padSize > 0 else { return data }
        // create prefix and return prefix + data
        let prefix: [UInt8] = (1...padSize).reduce([]) { result,_ in return result + [0] }
        return prefix + data
    }
    
    /// calculate u = H(clientPublicKey | serverPublicKey)
    static func calculateU(clientPublicKey: [UInt8], serverPublicKey: [UInt8], pad: Int) -> BigNum {
        BigNum(bytes: [UInt8].init(H.hash(data: SRP<H>.pad(clientPublicKey, to: pad) + SRP<H>.pad(serverPublicKey, to: pad))))
    }
    
    /// Calculate client verification code
    static func calculateClientVerification(
        configuration: SRPConfiguration<H>,
        username: String,
        salt: [UInt8],
        clientPublicKey: SRPKey,
        serverPublicKey: SRPKey,
        hashSharedSecret: [UInt8]) -> [UInt8]
    {
        // calculate shared secret proof M
        // M = H(H(N)^ H(g)) | H(username) | salt | client key | server key | shared secret)
        let N_xor_g = [UInt8](H.hash(data: configuration.N.bytes)) ^ [UInt8](H.hash(data: configuration.g.bytes))
        let hashUser = H.hash(data: [UInt8](username.utf8))
        let M = H.hash(data: [UInt8](N_xor_g) + hashUser + salt + clientPublicKey.bytes + serverPublicKey.bytes + hashSharedSecret)
        return [UInt8](M)
    }

    /// Calculate server verification code
    static func calculateServerVerification(clientPublicKey: SRPKey, clientVerifyCode: [UInt8], sharedSecret: [UInt8]) -> [UInt8] {
        let HAMK = H.hash(data: clientPublicKey.bytes + clientVerifyCode + sharedSecret)
        return [UInt8](HAMK)
    }
}
