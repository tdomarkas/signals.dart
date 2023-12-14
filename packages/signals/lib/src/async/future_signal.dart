import 'async_signal.dart';
import 'async_state.dart';

class FutureSignal<T> extends AsyncSignal<T> {
  Future<T> Function()? _future;
  final bool fireImmediately;
  bool _fetching = false;

  FutureSignal({
    Future<T> Function()? future,
    this.fireImmediately = false,
    super.debugLabel,
    T? initialValue,
  })  : _future = future,
        super(
            initialValue != null ? AsyncState.data(initialValue) : AsyncState.loading()) {
    if (fireImmediately) init();
  }

  Future<void> _execute() async {
    if (_future == null) return;
    if (_fetching) return;
    _fetching = true;
    try {
      final result = await _future!();
      setValue(result);
    } catch (error, stackTrace) {
      setError(error, stackTrace);
    }
  }

  /// Reload the future
  Future<void> reload() async {
    value = switch (value) {
      AsyncData<T> data => AsyncLoading<T>(
          value: data.requireValue,
          hasValue: true,
          isLoading: false,
        ),
      AsyncError<T> err => AsyncLoading<T>(
          error: (err.error!, err.stackTrace),
          hasError: true,
          isLoading: false,
        ),
      AsyncLoading<T>() => AsyncLoading<T>(),
    };
    _fetching = false;
    await _execute();
  }

  /// Refresh the future
  Future<void> refresh() async {
    value = switch (value) {
      AsyncData<T> data => AsyncData<T>(
          data.requireValue,
          isLoading: true,
        ),
      AsyncError<T> err => AsyncError<T>(
          err.error!,
          err.stackTrace,
          isLoading: true,
        ),
      AsyncLoading<T>() => AsyncLoading<T>(),
    };
    _fetching = false;
    await _execute();
  }

  @override
  void init() {
    super.init();
    _execute().ignore();
  }

  @override
  void reset() {
    super.reset();
    _fetching = false;
    if (fireImmediately) init();
  }

  void resetFuture(Future<T> Function() future) {
    _future = future;
    reset();
  }
}

FutureSignal<T> futureSignal<T>(
  Future<T> Function() future, {
  T? initialValue,
  String? debugLabel,
  bool fireImmediately = false,
}) {
  return FutureSignal(
    future: future,
    initialValue: initialValue,
    debugLabel: debugLabel,
    fireImmediately: fireImmediately,
  );
}
