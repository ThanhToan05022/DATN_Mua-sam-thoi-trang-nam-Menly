enum ViewStatus { initial, loading, success, error }

class ViewState<T> {
  final ViewStatus status;
  final T? data;
  final String? message;

  const ViewState({
    this.status = ViewStatus.initial,
    this.data,
    this.message,
  });

  bool get isInitial => status == ViewStatus.initial;
  bool get isLoading => status == ViewStatus.loading;
  bool get isSuccess => status == ViewStatus.success;
  bool get isError => status == ViewStatus.error;

  factory ViewState.initial() => const ViewState(status: ViewStatus.initial);

  factory ViewState.loading([T? previousData]) => ViewState(
        status: ViewStatus.loading,
        data: previousData,
      );

  factory ViewState.success(T data) => ViewState(
        status: ViewStatus.success,
        data: data,
      );

  factory ViewState.error(String message, [T? previousData]) => ViewState(
        status: ViewStatus.error,
        message: message,
        data: previousData,
      );

  R when<R>({
    required R Function() initial,
    required R Function() loading,
    required R Function(T data) success,
    required R Function(String message) error,
  }) {
    switch (status) {
      case ViewStatus.initial:
        return initial();
      case ViewStatus.loading:
        return loading();
      case ViewStatus.success:
        return success(data as T);
      case ViewStatus.error:
        return error(message ?? 'Đã xảy ra lỗi không xác định');
    }
  }
}
