class ApiResponse<T> {
  final bool isSuccess;
  final T? data;
  final String? errorMessage;

  ApiResponse({required this.isSuccess, this.data, this.errorMessage});

  factory ApiResponse.success(T data) {
    return ApiResponse(isSuccess: true, data: data);
  }

  factory ApiResponse.error(String message) {
    return ApiResponse(isSuccess: false, errorMessage: message);
  }
}
