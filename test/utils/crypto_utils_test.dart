import 'package:flutter_test/flutter_test.dart';
import 'package:tax_flow_pro/utils/crypto_utils.dart';

void main() {
  group('CryptoUtils Tests', () {
    test('encryptData should return a base64 string', () {
      final input = 'secret_data_123';
      final encrypted = CryptoUtils.encryptData(input);
      
      expect(encrypted, isNotNull);
      expect(encrypted, isNotEmpty);
      expect(encrypted, isNot(input)); // The encrypted string should not be the plaintext
    });

    test('decryptData should decrypt the base64 string back to original data', () {
      final input = 'secret_data_123';
      final encrypted = CryptoUtils.encryptData(input);
      final decrypted = CryptoUtils.decryptData(encrypted);
      
      expect(decrypted, equals(input));
    });

    test('encryptData and decryptData handle null input', () {
      expect(CryptoUtils.encryptData(null), isNull);
      expect(CryptoUtils.decryptData(null), isNull);
    });

    test('encryptData and decryptData handle empty input', () {
      expect(CryptoUtils.encryptData(''), equals(''));
      expect(CryptoUtils.decryptData(''), equals(''));
    });
    
    test('decryptData returns original string if decryption fails', () {
      final invalidBase64 = 'not_a_valid_base64_or_encrypted_string';
      final result = CryptoUtils.decryptData(invalidBase64);
      
      // According to current implementation, it catches errors and returns the input.
      expect(result, equals(invalidBase64));
    });
  });
}
