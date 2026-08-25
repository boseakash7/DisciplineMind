class V2ApiResponse<T> {
  final bool isSuccess;
  final T? data;
  final String? errorMessage;

  V2ApiResponse({
    required this.isSuccess,
    this.data,
    this.errorMessage,
  });

  factory V2ApiResponse.success(T data) {
    return V2ApiResponse(
      isSuccess: true,
      data: data,
    );
  }

  factory V2ApiResponse.error(String message) {
    return V2ApiResponse(
      isSuccess: false,
      errorMessage: message,
    );
  }
}
