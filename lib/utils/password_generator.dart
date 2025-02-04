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
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#\$%^&*()';
  static const mediumComplexityChars =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
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
    final primeNumbers = <int>[];
    int number = 1000000; // Start from 1 million

    // Generate a list of prime numbers
    while (primeNumbers.length < length) {
      if (isPrime(number)) {
        primeNumbers.add(number);
      }
      number +=
          Random().nextInt(1000) + 1; // Add random increment to speed up search
    }

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

    final metrics = {
      'Entropy':
          '${(log(chars.length) / log(2) * length).toStringAsFixed(2)} bits',
      'Strength': complexity,
    };

    return PasswordGenerationResult(password, metrics);
  }
}
