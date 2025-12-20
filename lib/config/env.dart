/// Centralized environment configuration (Flutter equivalent of Django's .env).
class Env {
  const Env._();

  static const String appName = 'LigaPass';
  static const String appTagline = 'Where football passion meets technology.';

  // static const String baseUrl = 'http://10.0.2.2:8000';
  static const String baseUrl =
      'https://jaysen-lestari-ligapass.pbp.cs.ui.ac.id';
  static const bool useHttps = true;

  /// Google OAuth client ID used across Android/iOS/Web.
  /// Override in production with: --dart-define=GOOGLE_CLIENT_ID=xxx
  static const String googleClientId = String.fromEnvironment(
    'GOOGLE_CLIENT_ID',
    defaultValue:
        '496589546073-lhasinbg2db22bkti40suvgaqjqti4t2.apps.googleusercontent.com',
  );

  /// Midtrans public client key (use dart-define: MIDTRANS_CLIENT_KEY=xxx)
  static const String midtransClientKey = String.fromEnvironment(
    'MIDTRANS_CLIENT_KEY',
    defaultValue: '',
  );

  /// Isi hanya untuk pengembangan lokal.
  /// Untuk produksi, lebih aman gunakan --dart-define=GEMINI_API_KEY=xxx.
  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );
  static const String geminiModel = 'gemini-2.5-flash';

  /// Toggle fitur debugging tertentu di mobile.
  static const bool debugMode = true;

  // MIILBgIBAzCCCrAGCSqGSIb3DQEHAaCCCqEEggqdMIIKmTCCBbAGCSqGSIb3DQEH
  // AaCCBaEEggWdMIIFmTCCBZUGCyqGSIb3DQEMCgECoIIFQDCCBTwwZgYJKoZIhvcN
  // AQUNMFkwOAYJKoZIhvcNAQUMMCsEFEvlHa1xx23DB+yCBir/Js2rI6lTAgInEAIB
  // IDAMBggqhkiG9w0CCQUAMB0GCWCGSAFlAwQBKgQQ9NdZ4dzXGT9OV3FNjh7t6wSC
  // BNBiY7NNQjPrTdlV1sIl+tD9syZvP6nBPh9ckse9w15aYCXjDUHxItSS10rldb3p
  // YIoC4p+hyhi5fYiIFit0ZwjWtUDg/QF1toRglQOFj88Dm8Zz52BQ4a/VWdYxuJXC
  // DJ38E92mQAWAGhTLew685BHQhqVBKGJEYoMO6g1aVORKP1lo4smBJ/8qDM1VDSC6
  // B6RNLVuMwf28Sc3ZmymM2arcF5Zt/QWgONUJSCielkRfjvzozhv1fvw2wUicr+ws
  // YByCW5iqMm2/4zFjl21oLh1McNde4OioauoB6uJLM1nvGimjnLZeiiPrsho0k/LK
  // xNPy4QvMRcv8dTQCRIeiOMJxgoIMjSTuwm9JmjHpYIyuwHsV33wrFGiJYz/lcqdi
  // cb/KYbZjc44pIqczZ+UVwvune1mWbl/1xkPrD2l7N3Xgb2Oa4J66gDCDwjCjpklq
  // GoUVvOtB4uTBdaC4qR64S9SAsFKFXxU1WeQC5MnHNnkyut8UwOGfkhWmEDEhy7Xh
  // RzBvkP+hK5fimS0Nw/66YjryzocTwIn1UlYNpMnZc/s0vvIGpCBK/zIV3Z2b/q4m
  // iUPEYMqH0bmEXqOZIRiqMaLsRz0b12nqWWvvXmfrtZjdjgG1/fOA23YaDrOmfmQT
  // 7insZ6Cy/wwjeZqqBkyz2pyqKvDobsmbRRaJhWXuNliHxj0UTALCpnLz5RZCKazk
  // b2L9HumYactcdUVWX4ZG1icQVasueFMvIAZBniT9gdcBb406k0nmarWg8It4zFVt
  // 4gSJeHxZ9Z0XiVFSMuL7x/OgA6BeFinO2i/VkvGdbKYxfXWcmd736Ib3F8F5Kxvt
  // IBNgvG6LYpsjNR52w2a5s64t82jdWDdTobluv/rTjOQoZeBcwLySOPrVez82p/Su
  // SarpnP90MkDjznDR3jj/ijTKujAvJZlu8Sl06rsj8NmgxHjfWrk0o0J0Tw3WLFU+
  // a5jNfcWrrrDKW4WUlmksDip82lGdDRcHNGGaJ5MG+L8V9faQXXsQp/G0ilS0vsNY
  // a/Jm3Hq5XqHOXq0WtqJrY0nvh9q/p5R8/bui8QfXczXfZeUWf2GvQg1wpoB27uD4
  // J1iIVrNudvBo5ck24zCvYqXsLj2oiKNJ7zEJGoLlKqfnt+bXA8p5NxlOaIgAhnpv
  // +brzH7CJxV8VUncKwmuA6La20xyFZPbI3RbmRN6d+3Mc6TA6OwznD7ZMlZlHKncO
  // LHXHHpfR7m1DdHG+I9u6wIFUuotMG/HuznHwR4NNWY1qSly1ARMGqpV678PND5c9
  // qIdReSS/Cb3lZ5L8cwRSNNe6W6JDQLHNYVAnf2cyW8F2C+2jKz8qGmUcA0wdaEEc
  // RyKCEAoRfnTv/bKilzBT3hKfFKwurmL8yOTg9dNX5Jb68d0ZAcCMDq8HVctfxTZW
  // Qs9bdVqm3N4kOstBzxt+AUFccfDEmVQI93yjIJ3MThkT/YuAHcP03RYlwBV364ND
  // P99uD+1FNdqwc3QK5fmjf1yNjrBswNQi2qEiy7x3y6mrgfDqVYfg3Wv8huvHfgjI
  // Dii00c9fAmMEBvNVHJ0DjFyMMXoLIST22DqEpYFR5mCzFM7Xn9xWfVFQTQKZUQO3
  // ydSM0+/M0VfvuCvlaBNk59Ua950ye07zhog7ruXPlhN+yjFCMB0GCSqGSIb3DQEJ
  // FDEQHg4AcgBlAGwAZQBhAHMAZTAhBgkqhkiG9w0BCRUxFAQSVGltZSAxNzY1MTgx
  // NzczMzU2MIIE4QYJKoZIhvcNAQcGoIIE0jCCBM4CAQAwggTHBgkqhkiG9w0BBwEw
  // ZgYJKoZIhvcNAQUNMFkwOAYJKoZIhvcNAQUMMCsEFAVSQMmiMETsl3Mck99MgDkJ
  // VPyCAgInEAIBIDAMBggqhkiG9w0CCQUAMB0GCWCGSAFlAwQBKgQQgG4qlyJvpUJK
  // OIxBjYIHaYCCBFCm/IaJlR7N9HJJdj40ZlWXaNYCrWL/tu27BclIXD54rH8U4kqK
  // AT285TgZGu82HyMyT1MYm/Q0RoGgexzBPJq9Izv/93TB2ZKtJDkrNZW4QFrbiSmq
  // e0lcco1SQfGfT/cfzmicpWNs1izmByT4qV3u64nQMsFYsarnSMw+gEfoysoRPXJO
  // 0GNpodG1VA2GpwioEJFESC+ToCHt3JCmzUDIFsiWZR27C6eUHcMq6WAqnssb3ss0
  // R4BXFlI3yEswY6FbjPSFNRDwaInsZ1DqzQV9yVzYZ1Y7WKQ0g3WNiCvqWd/9hHyK
  // CJNbOtlREpC5Rz/85Igtb0bg0K38dstl0CwR7JWlLotP9hTfuEuU3sjMfiJuuRQu
  // OgDDnRQDPFYnAr89ZwDgDeNqnsK/hZB96dMnG7U4AolXnDAFhQzwsf0CFvZc7RJV
  // 9jt9IjJxlUqJGGW0FdzwkBsmxhLIo/1H7AKr6gCPSSQejS/gnTO0mHlqNcKw+w+9
  // Aumt3O9DqpNeU27pG28sxlGZkT30CSO+DAgH4bu80zLvg2+Gykixltk2w3tEatvh
  // tV8/GkHNUqsvc84YFX0cxq12aNdL8BFTb77gnbgxSvPcSFgISVjR77m6KDPH8M/w
  // 1YcFAc6opDYtkpYfZCNclJ/qvkhlJ8bT6TLfEsMkTbkdbKB7Ba/0cItxWaUsn/4K
  // jwAbeEhcBaA5YsCkmT9h4A4rDc6XXHB4aBcitx1a4w80ArKAp86+8jd09EtO1lRt
  // MJ6NFSD9hLZJ87cAeAk8VVPRXKRCQDH5GC6D5AJTsgVg5sStLLVLNa9ETJZ66QHP
  // dUfh8wuHJgXf2ydoOmADsCQvtgrzm4uhNUMJs+2b0ge5HsBNbfG+Slt6T7zS4KZZ
  // namtVJJTTA02CJUfGXmZaXopd1tL2ZRTdu7ieSUYtcfLyJYZu76xoc/GTcfdOKa2
  // xfiQpZHa+ZTiRPVhrgjr3q3M9LebfFlA9Rr9X/bPmVdpJS3RhdqaTFZyOXFowo+n
  // sLKbbe98WvGQQkrUsLW7YOyAXAYv/XkYMlbrC2KvNhtN8adV9HxsM3JWp8LP5HmK
  // hVefqJRREAt7EGIcPEPQC6/f9h/pZbCh9DQ0OPH2SgyTn6C/jyzukRVY/PVbGZTh
  // iZEg7Ws+8oM5NPS/rBDn1Uu44s1K8kP9ZfMUKzV6DX5yM6nHNY0Nf+69MZZ6FZPR
  // qXrRW7iiVL6bmsQJCwrWvFtAsxrdk28YDDEvzKI7FFv9VZLkixg7p6EETFbznvkx
  // wWQjU09b5cB+Af4yNvrPfJNQ4SOfJTOjT0HIrfzxDhSn+pmNo+Uau9zKn1U3Jz54
  // fCr6MPauqx+G/LhfqnaBCxYuOn9ztuanxv4cam+5MOEpX4jAUpZOEO0dJsLEDkEQ
  // 9Lnx8iRVRmMTZZWRGtPhN40HHSeK4ZKjZTndLzq+IMmB1pAjChndWVo2iZ6Vo0R1
  // zsKAkciZCg9iQgIwTTAxMA0GCWCGSAFlAwQCAQUABCCion/V0xADuT4H8D9f6+oB
  // o3FT+H1I2/y4JElzvNqR3gQUiyOld13GGr7Q8+fNOD5YOXh6M2oCAicQ
}
