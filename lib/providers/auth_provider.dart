import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../models/founder_model.dart';
import '../models/investor_model.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  UserModel? _user;
  FounderModel? _founder;
  InvestorModel? _investor;
  bool _isLoading = false;
  String? _error;

  UserModel? get user => _user;
  FounderModel? get founder => _founder;
  InvestorModel? get investor => _investor;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  AuthProvider() {
    _init();
  }

  void _init() {
    _auth.authStateChanges().listen((User? firebaseUser) async {
      if (firebaseUser != null) {
        await _loadUserData(firebaseUser.uid);
      } else {
        _user = null;
        _founder = null;
        _investor = null;
        notifyListeners();
      }
    });
  }

  Future<void> _loadUserData(String uid) async {
    try {
      // For now, create a simple user model without Firestore
      final firebaseUser = _auth.currentUser;
      if (firebaseUser != null) {
        _user = UserModel(
          id: firebaseUser.uid,
          email: firebaseUser.email!,
          name: firebaseUser.displayName ?? firebaseUser.email!.split('@')[0],
          profileImageUrl: null,
          userType: UserType.founder, // Default to founder for now
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
        );
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to load user data: $e';
      notifyListeners();
    }
  }

  Future<bool> signInWithEmailPassword(
    String email,
    String password,
    UserType userType,
  ) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final UserCredential userCredential = await _auth
          .signInWithEmailAndPassword(email: email, password: password);
      final User? firebaseUser = userCredential.user;

      if (firebaseUser != null) {
        // Create user model without Firestore for now
        final newUser = UserModel(
          id: firebaseUser.uid,
          email: firebaseUser.email!,
          name: firebaseUser.displayName ?? email.split('@')[0],
          profileImageUrl: null,
          userType: userType,
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
        );
        _user = newUser;

        // Create role-specific model without Firestore
        if (userType == UserType.founder) {
          final newFounder = FounderModel(
            id: firebaseUser.uid,
            userId: firebaseUser.uid,
            fullName: firebaseUser.displayName ?? email.split('@')[0],
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          _founder = newFounder;
        } else {
          final newInvestor = InvestorModel(
            id: firebaseUser.uid,
            userId: firebaseUser.uid,
            fullName: firebaseUser.displayName ?? email.split('@')[0],
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          _investor = newInvestor;
        }
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Sign in failed: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> createAccountWithEmailPassword(
    String email,
    String password,
    String name,
    UserType userType,
  ) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);
      final User? firebaseUser = userCredential.user;

      if (firebaseUser != null) {
        // Update display name
        await firebaseUser.updateDisplayName(name);

        // Create new user without Firestore
        final newUser = UserModel(
          id: firebaseUser.uid,
          email: firebaseUser.email!,
          name: name,
          profileImageUrl: null,
          userType: userType,
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
        );
        _user = newUser;

        // Create role-specific model without Firestore
        if (userType == UserType.founder) {
          final newFounder = FounderModel(
            id: firebaseUser.uid,
            userId: firebaseUser.uid,
            fullName: name,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          _founder = newFounder;
        } else {
          final newInvestor = InvestorModel(
            id: firebaseUser.uid,
            userId: firebaseUser.uid,
            fullName: name,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          _investor = newInvestor;
        }
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Account creation failed: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      _user = null;
      _founder = null;
      _investor = null;
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Sign out failed: $e';
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
