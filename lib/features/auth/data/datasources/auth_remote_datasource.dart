import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/user_model.dart';

/// Hasil login dari server: user + token pair. Cuma dipakai internal di
/// layer data (bukan bagian dari domain), makanya nggak ditaruh di entities/.
class AuthSession {
  const AuthSession({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
  });

  final UserModel user;
  final String accessToken;
  final String refreshToken;
}

abstract class AuthRemoteDataSource {
  Future<AuthSession> login({required String identifier, required String password});

  Future<UserModel> register({
    required String name,
    required String phone,
    required String email,
    required String password,
    required String role,
  });

  Future<void> logout();

  // Update 2026-09-08: "Ubah Password"/"Lupa Password" self-designed —
  // lihat catatan lengkap di `AuthRepository`.
  Future<void> changePassword({required String oldPassword, required String newPassword});

  Future<void> requestPasswordReset({required String identifier});

  Future<void> resetPassword({required String identifier, required String newPassword});

  // Update 2026-09-08: "Edit Profil" self-designed — lihat catatan di
  // `AuthRepository`.
  // Update 2026-09-09: param institusi jadi opsional + 6 param baru buat
  // Responden — lihat catatan lengkap di `AuthRepository`.
  Future<UserModel> updateProfile({
    required String name,
    required String phone,
    String institution = '',
    String academicRole = '',
    String researchField = '',
    String gender = '',
    String birthDate = '',
    String respondentStatus = '',
    String domicile = '',
    String education = '',
    String fieldOfWork = '',
  });
}

/// Implementasi Dio — endpoint persis PROMPT_SPEC.md §3.1 & §8.
///
/// CATATAN: backend beneran (kerjaan Ammar) belum live saat kode ini
/// ditulis, jadi call ini bakal gagal dengan NetworkException sampai
/// integrasi backend jalan (CPMK 5). Struktur request/response udah
/// disiapin persis sesuai kontrak di PROMPT_SPEC.md biar tinggal pasang
/// begitu backend siap.
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  const AuthRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<AuthSession> login({required String identifier, required String password}) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiConstants.login,
        data: {'email': identifier, 'password': password},
      );
      final data = response.data!;
      return AuthSession(
        user: UserModel.fromJson(data['user'] as Map<String, dynamic>),
        accessToken: data['accessToken'] as String,
        refreshToken: data['refreshToken'] as String,
      );
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  @override
  Future<UserModel> register({
    required String name,
    required String phone,
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiConstants.register,
        data: {
          'name': name,
          'phone': phone,
          'email': email,
          'password': password,
          'role': role,
        },
      );
      final data = response.data!;
      return UserModel.fromJson(data['user'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _dio.post<void>(ApiConstants.logout);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  @override
  Future<void> changePassword({required String oldPassword, required String newPassword}) async {
    try {
      await _dio.post<void>(
        ApiConstants.changePassword,
        data: {'oldPassword': oldPassword, 'newPassword': newPassword},
      );
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  @override
  Future<void> requestPasswordReset({required String identifier}) async {
    try {
      await _dio.post<void>(ApiConstants.forgotPassword, data: {'identifier': identifier});
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  @override
  Future<void> resetPassword({required String identifier, required String newPassword}) async {
    try {
      await _dio.post<void>(
        ApiConstants.resetPassword,
        data: {'identifier': identifier, 'newPassword': newPassword},
      );
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  @override
  Future<UserModel> updateProfile({
    required String name,
    required String phone,
    String institution = '',
    String academicRole = '',
    String researchField = '',
    String gender = '',
    String birthDate = '',
    String respondentStatus = '',
    String domicile = '',
    String education = '',
    String fieldOfWork = '',
  }) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        ApiConstants.updateProfile,
        data: {
          'name': name,
          'phone': phone,
          'institution': institution,
          'academicRole': academicRole,
          'researchField': researchField,
          'gender': gender,
          'birthDate': birthDate,
          'respondentStatus': respondentStatus,
          'domicile': domicile,
          'education': education,
          'fieldOfWork': fieldOfWork,
        },
      );
      final data = response.data!;
      return UserModel.fromJson(data['user'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Exception _mapDioException(DioException e) {
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return const NetworkException();
    }

    final status = e.response?.statusCode;
    final responseData = e.response?.data;
    final serverMessage =
        responseData is Map && responseData['message'] is String ? responseData['message'] as String : null;

    if (status == 400) return ValidationException(serverMessage ?? 'Data yang dikirim tidak valid.');
    if (status == 401) return AuthException(serverMessage ?? 'Email/No. HP atau password salah.');
    if (status != null && status >= 500) return const ServerException();
    return ServerException(serverMessage ?? 'Terjadi kesalahan. Coba lagi.');
  }
}
