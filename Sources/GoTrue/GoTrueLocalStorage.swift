import Foundation
import KeychainAccess

public protocol GoTrueLocalStorage {
  func store(key: String, value: Data) throws
  func retrieve(key: String) throws -> Data?
  func remove(key: String) throws
}

public struct KeychainLocalStorage: GoTrueLocalStorage {
  let keychain: Keychain

  public init(service: String, accessGroup: String?) {
    if let accessGroup = accessGroup {
      keychain = Keychain(service: service, accessGroup: accessGroup)
    } else {
      keychain = Keychain(service: service)
    }
  }

  public func store(key: String, value: Data) throws {
    try keychain.set(value, key: key)
  }

  public func retrieve(key: String) throws -> Data? {
    try keychain.getData(key)
  }

  public func remove(key: String) throws {
    try keychain.remove(key)
  }
}
