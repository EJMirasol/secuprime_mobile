import 'dart:math';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class PasswordGenerationResult {
  final String password;
  final Map<String, String> metrics;

  PasswordGenerationResult(this.password, this.metrics);
}

class PasswordGenerator {
  static const highComplexityChars =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz2357!@#\$%^&*()';
  static const mediumComplexityChars =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz2357';
  static const lowComplexityChars =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';

  bool isPrime(int number) {
    if (number < 2) return false;
    if (number == 2) return true;
    if (number % 2 == 0) return false;

    // Only check odd numbers up to square root
    for (int i = 3; i <= sqrt(number).toInt(); i += 2) {
      if (number % i == 0) return false;
    }
    return true;
  }

  PasswordGenerationResult generateSecurePassword(
      int length, String complexity) {
    final allowedPrimes = [2, 3, 5, 7];
    final primeNumbers = List.generate(length,
        (index) => allowedPrimes[Random().nextInt(allowedPrimes.length)]);

    // Shuffle the prime numbers for added randomness
    primeNumbers.shuffle();

    // Combine primes into a single string and hash them for extra security
    final combinedPrimes = primeNumbers.join();
    final hashedBytes = sha256.convert(utf8.encode(combinedPrimes)).bytes;

    final chars = complexity == 'High'
        ? highComplexityChars
        : complexity == 'Medium'
            ? mediumComplexityChars
            : lowComplexityChars;

    final random = Random();
    final password = List.generate(length, (index) {
      return chars[
          hashedBytes[random.nextInt(hashedBytes.length)] % chars.length];
    }).join();

    // Enforce exactly one prime number in the password
    final passwordChars = password.split('');
    final primeChars = ['2', '3', '5', '7'];
    var primeIndices = <int>[];

    // Find existing primes
    for (int i = 0; i < passwordChars.length; i++) {
      if (primeChars.contains(passwordChars[i])) {
        primeIndices.add(i);
      }
    }

    // Add or replace primes as needed
    if (primeIndices.isEmpty) {
      // Add a prime at random position
      final newPos = random.nextInt(length);
      passwordChars[newPos] = primeChars[random.nextInt(primeChars.length)];
    } else if (primeIndices.length > 1) {
      // Keep one random prime, replace others
      final keepIndex = primeIndices[random.nextInt(primeIndices.length)];
      for (final index in primeIndices) {
        if (index != keepIndex) {
          String replacement;
          do {
            replacement = chars[random.nextInt(chars.length)];
          } while (primeChars.contains(replacement));
          passwordChars[index] = replacement;
        }
      }
    }

    final finalPassword = passwordChars.join();

    final metrics = {
      'Entropy':
          '${(log(chars.length) / log(2) * length).toStringAsFixed(2)} bits',
      'Strength': complexity,
    };

    return PasswordGenerationResult(finalPassword, metrics);
  }
}
