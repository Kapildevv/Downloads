/// The Howealthy Universal Banking API Interface
///
/// This architectural blueprint connects the local AGI engine to the global banking grid.
/// By enforcing an interface, the app can swap out banking data providers (e.g., HDFC, SBI,
/// or international grids) instantly without breaking the Riverpod pipeline or local Hive persistence.
abstract interface class RemoteTransactionProvider {
  /// Authenticates with the institutional server using quantum-encrypted tokens.
  Future<bool> authenticateGrid(String apiKey, String secret);

  /// Fetches a raw, unclassified ledger stream from the external provider.
  /// The local [IngestionEngine] will then process this payload.
  Future<List<Map<String, dynamic>>> fetchRawLedger({required DateTime since});

  /// Establishes an indestructible WebSocket connection for sub-millisecond live syncing.
  Stream<Map<String, dynamic>> openLiveLedgerStream();

  /// securely flushes the external connection to prevent data leakage.
  Future<void> severConnection();
}
