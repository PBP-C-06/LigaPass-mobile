/// Centralized environment configuration (Flutter equivalent of Django's .env).
class Env {
  const Env._();

  static const String appName = 'LigaPass';
  static const String appTagline = 'Where football passion meets technology.';

  // static const String baseUrl = 'http://10.0.2.2:8000';
  static const String baseUrl = 'http://localhost:8000';
  static const bool useHttps = false;

  /// Isi hanya untuk pengembangan lokal.
  /// Untuk produksi, lebih aman gunakan --dart-define=GEMINI_API_KEY=xxx.
  static const String geminiApiKey = 'AIzaSyBiTcleixJOG-XtcOoE7kZwe2FGLHNunJI';
  static const String geminiModel = 'gemini-2.5-flash';

  /// Toggle fitur debugging tertentu di mobile.
  static const bool debugMode = true;

  // MIILRgIBAzCCCvAGCSqGSIb3DQEHAaCCCuEEggrdMIIK2TCCBbAGCSqGSIb3DQEH
  // AaCCBaEEggWdMIIFmTCCBZUGCyqGSIb3DQEMCgECoIIFQDCCBTwwZgYJKoZIhvcN
  // AQUNMFkwOAYJKoZIhvcNAQUMMCsEFBUprlKkZBY0pANn2RGYkb6KpbaeAgInEAIB
  // IDAMBggqhkiG9w0CCQUAMB0GCWCGSAFlAwQBKgQQ0IABUt4cwW0kIA1hSizgcwSC
  // BNBFRNLwWtwUozgRZ63fxdyJo/TBTmcHb3tnHRxODwQ2bxVXqskjotyMl4lRCMy+
  // ukY2mei+2Fd67gaspZcEaq7xlSXS7lpgYUzZPpdUAIfit0KUA5a3ggw/imc2hIzL
  // dzLJI1W3iWZ+/aB4OJCNkePlrUs7EMFyHauyLel/MlBPiLyb0GtNDg1EfXHbCExm
  // EEfERsxcViWwUmOLjCk5/U5NUKubhaq9fB470prGbzB1SFQybVoKi0FDAM1Bfi4t
  // kjX2fqquYaui+utq5wJAbRR5AEPvdY1VM6ymqrKRKXMeBbiztKSybnZMh2bqANzf
  // F9zyJe1Jcxn7zJF5kjsDd89qXzrawkZVG0HrXwg2FcybIP3/Nnf23pPfgHrTglPv
  // 0qLiP+ib0qGDWqKikRn64TSFG+pwQv7KD6pJ4MCJjDnlEGxETSBjbv9UAsAzNdrQ
  // ZfrFMZ8nYPgfix3MQzvhQY1HEQ1cHJYxiWnkPyu1fNtR57tgMXy6SKF4NBlVFT74
  // CQ14OsZewkiHcwbzkDMNRGU4AY81oDg4fuEsv1MlPm6odJk4GbXJtMByqj/lHF25
  // jOFy1mW/MYjqRRRSg0oOnOqN8d9KrNaGMkV6cYrcGvtZb1kWgciT+qR4mnO4Zow5
  // /FYmvdFaesNWrrZzYLoRKhr0Zk1vYlJBnQcjNqbgvrj6e3JDZaTwTZqT0of8R7UD
  // 5cYzaYhO8Y8lD5J69hQJzVU+MtwmJhzJDLlvZh5/0XQU6lMprEjJNT+p8QXCgaho
  // vrxkwIsk8rkMjb1TKbnTv5pycErqrE3fGlOP5ZcdlEXDHs/0cuESjGeUQVDnsfsq
  // Dy9YEoUWRTRt6D+yDvpqG2m6kT4kKbgt/RqaOXc37wT/A36fnVH7+/KO+xfbx2Zs
  // 1qqif8EhmIeG31eQ13ZPyo2E+ukLHUcDlVB2kfr1JMssGlq20HYPShPIUuzudG3u
  // 21gPqHXecROOwqcSt/L9bUFn9QNrAOFU+37Jbyt9cxYKfILAIIuohJom4kUTr/+8
  // KBjVj1gQgTe8+qs0Ikw5sd+UxzkjUM1RR0u94ue4IWRK8o3oV0I4ZFNv4j7BY6FC
  // qLDeR0Y+9ckKFjJ+6oLQxj0ic6D8Z3UGgHrP4V+FCvOS2EFhzbkiUDA0JGh4oHRY
  // 0cCa+7VBTVdYZalGlpeJ/RX7d2k095Zvn1iBlVlEMtYQdAVFX6nlkJbrmFgxpaS8
  // ibM0L8bGTyogRE7ygSwURNC17dvmSsarhGVJLP+/W12d6RcbxvPpZ3JqNsAOS9vu
  // GokUwwC6fUKuDAMmyobRTzSnO4YZnbBQVx9wGcM+msdl1t7D0oroIgP0pQL+HbXI
  // QePrveoa5nL6qx1qzWWUPt+DS24uu6b+PSBKH/Qza6f7qvpp2iABx4Nr0s/l73HE
  // flaPoy0zDkTb5BHKpLnaFZ6fhlxlH1GY8F2OZURdnM/HcJe7sxDNUuu/2RMsEaHK
  // kM8pJx+/V5rgsqetmLKVicWuXGy/UX6uUiHK0G+Vh1D8L0MD+6j7glT6oCczn+98
  // 30dTgFZW4kBjnp+MoGPHLKGYtDTJIHWjz5rjk5UFxv/5GkxVQ/xy0MQYA8yqaJV7
  // bLM/8hJmmgi4uMg5TuxZmSJYtnTOOiv3v+Z7CHoKiBgD9TFCMB0GCSqGSIb3DQEJ
  // FDEQHg4AcgBlAGwAZQBhAHMAZTAhBgkqhkiG9w0BCRUxFAQSVGltZSAxNzY0OTA1
  // NzMyMzc1MIIFIQYJKoZIhvcNAQcGoIIFEjCCBQ4CAQAwggUHBgkqhkiG9w0BBwEw
  // ZgYJKoZIhvcNAQUNMFkwOAYJKoZIhvcNAQUMMCsEFCfP3n5EYeE+TL8GcIJagjzu
  // cH1zAgInEAIBIDAMBggqhkiG9w0CCQUAMB0GCWCGSAFlAwQBKgQQ+Vej9+hkiKFu
  // qxH6yswXXICCBJDDURxKdRyauVwzei6fPcljFS5oQEEP0qjfPhXx1gxJjQzYjOO5
  // qGr6cIkUd2L+kV4eOFLYLL+8/oq5P1IpVW6HdOWfsksVAIQYMb5jaGtTpdv7bm2F
  // XGASgMBFDpbJNX+jG/l3qoHHA7nmcCGXLIv4T7WLB0U+RJhcXM1NeKNLvXBFaRBJ
  // WE9/61z3Vq7T6o4UcVyU2xzj2e+TswIkYuWVIwGa6rYvP90FhSMOLzsvtwEWalK8
  // YJgOz7qpPD1i+yfqaUI55239Nu3lrGh9g0BDBbf6TNDQf+UQGKixniLQGJvzwTd2
  // EXm2p8waez7aS5tsEgi4ZMacQJJN2D5JHHdqRaqUUVmTCvnFWbUxtN9bewJN/dWo
  // GfJmJh1j0e7lr9sdqs6cDrtEDSjJSpd/Vv0qbWEh1hNhWvxOUbwPzoZHKMWBgOKU
  // AEAUhNh5kEQT4e1W7Cn4yf9bIbohl6dRZNG62GpmlSBBuD9Lg5mIHghN5Nh/DkK8
  // Y/LvSFrmfhx5utYL4M7NUWwjZEPUDRAaKmhn4sditRBPQ9EgV0vepSNdzsAUELcj
  // chgNIvwrb26AZoldwucqSZ1rLz0PFDK3fD7FjmbKLZg9hLgLrEpjlK2OaNisqisX
  // JGG+9eeXg6cyjGv/SZXlCnfSxmTaoDvwGRrmJKNmwPMt9Zos313qeNoL3Qqti362
  // T1am4A4fntwhWuCE1iSdrsrbvN75riAS69AK8xuxr285KP236Dz1r2dBc9jYmKaE
  // Th3CXN1OYyFg63ngtz5AlnTzANMUQ1hnAJMOx7LuE284G+kb9dslF4LtvzSwMyYa
  // wugtybWlOl21KDDHqs9sqwh4ox6xmb6kvVoNiMWkRtzrMcHHNZ3V2cNgLxLMFFJI
  // 1SqGOr1u1gdhBuEc+F3Wy6xx1pBEpTTSmnKMWUTCpTmfNwQGIuO7pVypY1RpMaHE
  // 1sdv8X+7ldAjdJanIfpm3mf81WwBpP8ETNV8Lktg9Uh+sJLaPtwE3TeYg5uRqHzj
  // kRFuz1iCuVJxPJo9wawOKK0b7IWCQpM4NrleaC0ArDf6uPhnnD6cbFa74FQWN+FY
  // u14QbRcXfxt+9sJ4iE+eG0UMKw1gEuMJE/bF2h6nIdLeafCjgwjfgQKEUa9mBHa0
  // QczKyfNJ4iqi8JDaK6deys1jYXL9fA33mMBaaL7oMnpSr/T2BqiRduucoFFfNKMJ
  // pw5SA49syV2LYZ0p2M4UN9yEidgw9tZkOy278cZ3rFve4XbKY+RmIq0ZXSnYfFnv
  // nM8VFlGfu0aQxF3lDKEdOMNppc/L+eHY70Ur+6uX5mfTIO0kynTrmhXM1T6KenLn
  // Gz6ykrSCV7MP7QNScWnUyriKw/PCPDfWZxr4iS8niPQOqG6W6Gdx0st9tzasj9oJ
  // vUy+oD4eKaeGUDgcJy2GDl1ye7t7UzT+h3npVkvDJINbUhSU3RbJjecTthvF8MyP
  // TYps2EpxYs1T3EaNc2nmeWKs7xfWlZxN2BSWmaeVlyHUZXX++BCAc+1B1gFhqxZp
  // 44u/AVGnuaT1gakzGK6l0B9pXvd+nWiOPD7wME0wMTANBglghkgBZQMEAgEFAAQg
  // 8pOn8iVD1dj+B/sqURR6AgAMlPQvU880qNQfduEEvbAEFPhqy6Wf9prne748vjgs
  // MbwyLeaVAgInEA==
}
