import 'package:flutter/material.dart';

import '../data/parent_unlock_repository.dart';
import '../domain/parent_unlock_config.dart';
import '../domain/parent_unlock_request.dart';
import '../domain/parent_unlock_state.dart';

class ParentUnlockViewModel extends ChangeNotifier {
  final ParentUnlockRepository _repository = ParentUnlockRepository.instance;

  bool _isLoading = true;
  String? _error;

  ParentUnlockConfig _config = ParentUnlockConfig.initial();
  ParentUnlockState _state = ParentUnlockState.initial();
  ParentUnlockRequest _request = ParentUnlockRequest.initial();

  bool get isLoading => _isLoading;
  String? get error => _error;
  ParentUnlockConfig get config => _config;
  ParentUnlockState get state => _state;
  ParentUnlockRequest get request => _request;

  Future<void> initialize() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.ensureInitialized();
      await refresh();
    } catch (e) {
      _error = 'Failed to load parent unlock controls: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    _config = await _repository.getConfig();
    _state = await _repository.getState();
    _request = await _repository.getRequest();
    notifyListeners();
  }

  Future<bool> validatePin(String pin) {
    return _repository.validateParentPin(pin);
  }

  Future<void> setEnabled(bool value) async {
    await _repository.updateConfig(_config.copyWith(enabled: value));
    await refresh();
  }

  Future<void> setParentPin(String pin) async {
    await _repository.updateConfig(_config.copyWith(parentPin: pin.trim()));
    await refresh();
  }

  Future<void> setTokensPerApproval(int value) async {
    await _repository.updateConfig(_config.copyWith(tokensPerApproval: value.clamp(1, 20)));
    await refresh();
  }

  Future<void> approvePendingRequest({int? tokenCount}) async {
    await _repository.approveRequest(tokenCount: tokenCount);
    await refresh();
  }

  Future<void> rejectPendingRequest() async {
    await _repository.rejectRequest();
    await refresh();
  }

  Future<void> grantTokens(int amount) async {
    await _repository.grantTokens(amount);
    await refresh();
  }

  Future<void> clearRequest() async {
    await _repository.clearRequest();
    await refresh();
  }
}