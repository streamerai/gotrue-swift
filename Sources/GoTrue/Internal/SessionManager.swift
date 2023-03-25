import Foundation
import KeychainAccess

public struct StoredSession: Codable {
  public var session: Session
  public var expirationDate: Date

  public var isValid: Bool {
    expirationDate > Date().addingTimeInterval(-60)
  }

  public init(session: Session, expirationDate: Date? = nil) {
    self.session = session
    self.expirationDate = expirationDate ?? Date().addingTimeInterval(session.expiresIn)
  }
}

struct SessionManager {
  var session: () async throws -> Session
  var update: (_ session: Session) async throws -> Void
  var remove: () async -> Void
}

extension SessionManager {
  static var live: Self {
    let instance = LiveSessionManager()
    return Self(
      session: { try await instance.session() },
      update: { try await instance.update($0) },
      remove: { await instance.remove() }
    )
  }
}

private actor LiveSessionManager {
  private var task: Task<Session, Error>?

  func session() async throws -> Session {
    if let task = task {
      return try await task.value
    }

    guard let currentSession = try Env.localStorage.getSession() else {
      throw GoTrueError.sessionNotFound
    }

    if currentSession.isValid {
      return currentSession.session
    }

    task = Task {
      defer { self.task = nil }

      let session = try await Env.sessionRefresher(currentSession.session.refreshToken)
      try update(session)
      return session
    }

    return try await task!.value
  }

  func update(_ session: Session) throws {
    try Env.localStorage.storeSession(StoredSession(session: session))
  }

  func remove() {
    Env.localStorage.deleteSession()
  }
}

public extension GoTrueLocalStorage {
  func getSession() throws -> StoredSession? {
    try retrieve(key: "supabase.session").flatMap {
      try JSONDecoder.goTrue.decode(StoredSession.self, from: $0)
    }
  }

  func storeSession(_ session: StoredSession) throws {
    try store(key: "supabase.session", value: JSONEncoder.goTrue.encode(session))
  }

  func deleteSession() {
    try? remove(key: "supabase.session")
  }
}
