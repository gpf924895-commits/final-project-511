/// Compatibility shims for Firebase Firestore types in offline mode
/// These classes provide the same API as Firebase types but work locally

class Timestamp {
  final DateTime _dt;
  Timestamp._(this._dt);

  static Timestamp now() => Timestamp._(DateTime.now().toUtc());
  static Timestamp fromDate(DateTime dt) => Timestamp._(dt.toUtc());
  static Timestamp fromMillisecondsSinceEpoch(int milliseconds) => Timestamp._(
    DateTime.fromMillisecondsSinceEpoch(milliseconds, isUtc: true),
  );

  DateTime toDate() => _dt.toUtc();
  int get millisecondsSinceEpoch => _dt.millisecondsSinceEpoch;

  int compareTo(Timestamp other) => _dt.compareTo(other._dt);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Timestamp && _dt == other._dt;

  @override
  int get hashCode => _dt.hashCode;
}

class FieldValue {
  const FieldValue._();
  static const FieldValue _serverTimestamp = FieldValue._();
  static FieldValue serverTimestamp() => _serverTimestamp;
}

/// Query shim (minimal stub for compilation)
class Query {
  Query();
}

/// DocumentSnapshot shim
class DocumentSnapshot {
  final Map<String, dynamic>? data;
  final String id;
  final bool exists;

  DocumentSnapshot({this.data, required this.id, this.exists = true});

  Map<String, dynamic>? get() => data;
  dynamic operator [](String key) => data?[key];
}

/// QuerySnapshot shim
class QuerySnapshot {
  final List<DocumentSnapshot> docs;
  QuerySnapshot(this.docs);
}

/// FirebaseAuthException shim
class FirebaseAuthException implements Exception {
  final String code;
  final String? message;

  FirebaseAuthException({required this.code, this.message});

  @override
  String toString() => message ?? code;
}

/// FirebaseException shim
class FirebaseException implements Exception {
  final String code;
  final String? message;

  FirebaseException({required this.code, this.message});

  @override
  String toString() => message ?? code;
}

/// FieldPath shim
class FieldPath {
  final String _fieldPath;
  FieldPath(this._fieldPath);

  static FieldPath documentId = FieldPath('__name__');
  String get path => _fieldPath;
}

/// SetOptions shim
class SetOptions {
  final bool merge;
  SetOptions({this.merge = false});
}

/// DocumentChangeType shim
enum DocumentChangeType { added, modified, removed }

/// FirebaseFirestore shim (minimal stub)
class FirebaseFirestore {
  static FirebaseFirestore get instance => FirebaseFirestore._();
  FirebaseFirestore._();

  Query collection(String path) => Query();

  CollectionReference collectionGroup(String collectionId) =>
      CollectionReference._();
}

/// CollectionReference shim
class CollectionReference {
  CollectionReference._();

  DocumentReference doc([String? path]) => DocumentReference._();
  Future<DocumentReference> add(Map<String, dynamic> data) async =>
      DocumentReference._();
  Query where(String field, {Object? isEqualTo, Object? isGreaterThan}) =>
      Query();
  Query orderBy(String field, {bool descending = false}) => Query();
  Query limit(int limit) => Query();
  Future<QuerySnapshot> get() async => QuerySnapshot([]);
  Stream<QuerySnapshot> snapshots() => Stream.value(QuerySnapshot([]));
}

/// DocumentReference shim
class DocumentReference {
  DocumentReference._();

  String get id => '';
  CollectionReference collection(String path) => CollectionReference._();
  Future<void> set(Map<String, dynamic> data, {SetOptions? options}) async {}
  Future<void> update(Map<String, dynamic> data) async {}
  Future<void> delete() async {}
  Future<DocumentSnapshot> get() async => DocumentSnapshot(data: {}, id: '');
  Stream<DocumentSnapshot> snapshots() =>
      Stream.value(DocumentSnapshot(data: {}, id: ''));
}

/// FirebaseAuth shim (minimal stub)
class FirebaseAuth {
  static FirebaseAuth get instance => FirebaseAuth._();
  FirebaseAuth._();

  User? get currentUser => null;
  Stream<User?> get authStateChanges => Stream.value(null);
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async => throw UnimplementedError('Offline mode: Firebase Auth disabled');
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async => throw UnimplementedError('Offline mode: Firebase Auth disabled');
  Future<void> signOut() async {}
  Future<void> sendPasswordResetEmail({required String email}) async {}
}

/// User shim
class User {
  String? get uid => null;
  String? get email => null;
  Future<void> updatePassword(String newPassword) async {}
  Future<UserCredential> reauthenticateWithCredential(
    AuthCredential credential,
  ) async => throw UnimplementedError('Offline mode: Firebase Auth disabled');
}

/// UserCredential shim
class UserCredential {
  User? get user => null;
}

/// AuthCredential shim
class AuthCredential {}

/// EmailAuthProvider shim
class EmailAuthProvider {
  static AuthCredential credential({
    required String email,
    required String password,
  }) => AuthCredential();
}
