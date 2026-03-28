import 'package:flutter/material.dart';

enum ChessSurfacePattern {
  none,
  brushed,
  weave,
  facets,
  etched,
  aurora,
}

class ChessSurfaceMaterial {
  const ChessSurfaceMaterial({
    required this.surface,
    required this.highlight,
    required this.border,
    required this.shadow,
    required this.symbolColor,
    required this.pattern,
    required this.patternColor,
  });

  final List<Color> surface;
  final List<Color> highlight;
  final Color border;
  final Color shadow;
  final Color symbolColor;
  final ChessSurfacePattern pattern;
  final Color patternColor;
}

class ChessBoardMaterial {
  const ChessBoardMaterial({
    required this.frame,
    required this.border,
    required this.surface,
    required this.lightSquare,
    required this.darkSquare,
    required this.pattern,
    required this.patternColor,
    required this.glow,
  });

  final List<Color> frame;
  final Color border;
  final List<Color> surface;
  final List<Color> lightSquare;
  final List<Color> darkSquare;
  final ChessSurfacePattern pattern;
  final Color patternColor;
  final Color glow;
}

class ChessSetTheme {
  const ChessSetTheme({
    required this.id,
    required this.name,
    required this.unlockLevel,
    required this.tagline,
    required this.board,
    required this.whitePieces,
    required this.blackPieces,
    required this.accent,
  });

  final String id;
  final String name;
  final int unlockLevel;
  final String tagline;
  final ChessBoardMaterial board;
  final ChessSurfaceMaterial whitePieces;
  final ChessSurfaceMaterial blackPieces;
  final Color accent;
}

class ChessSetCatalog {
  static const ChessSetTheme chrome = ChessSetTheme(
    id: 'chrome',
    name: 'Chrome Vanguard',
    unlockLevel: 1,
    tagline: 'Mirror-bright metal with a clean studio board.',
    accent: Color(0xFF89B6E8),
    board: ChessBoardMaterial(
      frame: <Color>[
        Color(0xFFCCD6DE),
        Color(0xFF7C8793),
        Color(0xFF59626B),
      ],
      border: Color(0xFF75818D),
      surface: <Color>[
        Color(0xFFF7FAFC),
        Color(0xFFE8EEF3),
      ],
      lightSquare: <Color>[
        Color(0xFFFDFEFE),
        Color(0xFFE9EEF2),
      ],
      darkSquare: <Color>[
        Color(0xFFD8E1E9),
        Color(0xFFC2CDD7),
      ],
      pattern: ChessSurfacePattern.brushed,
      patternColor: Color(0x337D8FA0),
      glow: Color(0x6687B7FF),
    ),
    whitePieces: ChessSurfaceMaterial(
      surface: <Color>[
        Color(0xFFFFFFFF),
        Color(0xFFE7EDF2),
        Color(0xFFBCC7D3),
      ],
      highlight: <Color>[
        Color(0xFFFFFFFF),
        Color(0x66FFFFFF),
      ],
      border: Color(0xFF9FADBB),
      shadow: Color(0x770F1418),
      symbolColor: Color(0xFF182029),
      pattern: ChessSurfacePattern.brushed,
      patternColor: Color(0x4490A2B5),
    ),
    blackPieces: ChessSurfaceMaterial(
      surface: <Color>[
        Color(0xFF505A64),
        Color(0xFF25303A),
        Color(0xFF11161B),
      ],
      highlight: <Color>[
        Color(0x55FFFFFF),
        Color(0x11FFFFFF),
      ],
      border: Color(0xFF85929E),
      shadow: Color(0xAA0C1115),
      symbolColor: Color(0xFFF2F6FA),
      pattern: ChessSurfacePattern.brushed,
      patternColor: Color(0x334F5C68),
    ),
  );

  static const ChessSetTheme crystal = ChessSetTheme(
    id: 'crystal',
    name: 'Crystal Vault',
    unlockLevel: 2,
    tagline: 'Frosted glass, blue light, and hard edges.',
    accent: Color(0xFF7FE3F2),
    board: ChessBoardMaterial(
      frame: <Color>[
        Color(0xFF8CE7F6),
        Color(0xFF5B95B9),
        Color(0xFF355B7A),
      ],
      border: Color(0xFF63A8C7),
      surface: <Color>[
        Color(0xFFF4FCFF),
        Color(0xFFE1F3FA),
      ],
      lightSquare: <Color>[
        Color(0xFFF9FFFF),
        Color(0xFFDDF4FB),
      ],
      darkSquare: <Color>[
        Color(0xFFCDEAF2),
        Color(0xFFAED3E1),
      ],
      pattern: ChessSurfacePattern.facets,
      patternColor: Color(0x3388D9F6),
      glow: Color(0x7792F2FF),
    ),
    whitePieces: ChessSurfaceMaterial(
      surface: <Color>[
        Color(0xF2FFFFFF),
        Color(0xD8F4FBFF),
        Color(0xA4CFEAFF),
      ],
      highlight: <Color>[
        Color(0xAAFFFFFF),
        Color(0x4CFFFFFF),
      ],
      border: Color(0xFF88D7F2),
      shadow: Color(0x66184A68),
      symbolColor: Color(0xFF102238),
      pattern: ChessSurfacePattern.facets,
      patternColor: Color(0x5597E8FF),
    ),
    blackPieces: ChessSurfaceMaterial(
      surface: <Color>[
        Color(0xFF31465A),
        Color(0xFF0F1B26),
        Color(0xFF050A10),
      ],
      highlight: <Color>[
        Color(0x44FFFFFF),
        Color(0x11FFFFFF),
      ],
      border: Color(0xFF78C3E8),
      shadow: Color(0xBB081019),
      symbolColor: Color(0xFFF2FBFF),
      pattern: ChessSurfacePattern.facets,
      patternColor: Color(0x336ADAF8),
    ),
  );

  static const ChessSetTheme gold = ChessSetTheme(
    id: 'gold',
    name: 'Gilded Court',
    unlockLevel: 4,
    tagline: 'Warm gold with a museum-grade polish.',
    accent: Color(0xFFE3C15A),
    board: ChessBoardMaterial(
      frame: <Color>[
        Color(0xFFF0D36A),
        Color(0xFFB57D2A),
        Color(0xFF805317),
      ],
      border: Color(0xFF9F7125),
      surface: <Color>[
        Color(0xFFFFF8E9),
        Color(0xFFEFD9A7),
      ],
      lightSquare: <Color>[
        Color(0xFFFFF7E8),
        Color(0xFFF6E3B7),
      ],
      darkSquare: <Color>[
        Color(0xFFE9C97C),
        Color(0xFFC99234),
      ],
      pattern: ChessSurfacePattern.brushed,
      patternColor: Color(0x33FFFFFF),
      glow: Color(0x66F6D57A),
    ),
    whitePieces: ChessSurfaceMaterial(
      surface: <Color>[
        Color(0xFFFFF4C9),
        Color(0xFFF1D690),
        Color(0xFFC9962C),
      ],
      highlight: <Color>[
        Color(0xCCFFF7D9),
        Color(0x66FFFFFF),
      ],
      border: Color(0xFFBC8B2A),
      shadow: Color(0x77120E08),
      symbolColor: Color(0xFF4B3516),
      pattern: ChessSurfacePattern.brushed,
      patternColor: Color(0x44FFF9D6),
    ),
    blackPieces: ChessSurfaceMaterial(
      surface: <Color>[
        Color(0xFF483716),
        Color(0xFF22160B),
        Color(0xFF090603),
      ],
      highlight: <Color>[
        Color(0x33FFF0B4),
        Color(0x11FFFFFF),
      ],
      border: Color(0xFF9E7330),
      shadow: Color(0xCC090603),
      symbolColor: Color(0xFFFFE9B0),
      pattern: ChessSurfacePattern.brushed,
      patternColor: Color(0x33F0DFA4),
    ),
  );

  static const ChessSetTheme carbon = ChessSetTheme(
    id: 'carbon',
    name: 'Carbon Night',
    unlockLevel: 6,
    tagline: 'Matte weave, hard contrast, and clean edges.',
    accent: Color(0xFF5BD3FF),
    board: ChessBoardMaterial(
      frame: <Color>[
        Color(0xFF52606A),
        Color(0xFF1E262C),
        Color(0xFF0E1318),
      ],
      border: Color(0xFF2D3740),
      surface: <Color>[
        Color(0xFF1D2329),
        Color(0xFF0F1419),
      ],
      lightSquare: <Color>[
        Color(0xFF293239),
        Color(0xFF20262C),
      ],
      darkSquare: <Color>[
        Color(0xFF12171C),
        Color(0xFF090C10),
      ],
      pattern: ChessSurfacePattern.weave,
      patternColor: Color(0x22444F58),
      glow: Color(0x6648C8FF),
    ),
    whitePieces: ChessSurfaceMaterial(
      surface: <Color>[
        Color(0xFFF4F8FB),
        Color(0xFFD1DADF),
        Color(0xFF8E9AA4),
      ],
      highlight: <Color>[
        Color(0xEEFFFFFF),
        Color(0x44FFFFFF),
      ],
      border: Color(0xFF626D76),
      shadow: Color(0x8811181D),
      symbolColor: Color(0xFF12171C),
      pattern: ChessSurfacePattern.weave,
      patternColor: Color(0x445E6B76),
    ),
    blackPieces: ChessSurfaceMaterial(
      surface: <Color>[
        Color(0xFF262D33),
        Color(0xFF11161B),
        Color(0xFF06080B),
      ],
      highlight: <Color>[
        Color(0x22FFFFFF),
        Color(0x08FFFFFF),
      ],
      border: Color(0xFF404A53),
      shadow: Color(0xDD05070A),
      symbolColor: Color(0xFFE8F4FB),
      pattern: ChessSurfacePattern.weave,
      patternColor: Color(0x22485B66),
    ),
  );

  static const ChessSetTheme obsidian = ChessSetTheme(
    id: 'obsidian',
    name: 'Obsidian Relic',
    unlockLevel: 8,
    tagline: 'Dark stone, violet glass, and old magic.',
    accent: Color(0xFFAC86FF),
    board: ChessBoardMaterial(
      frame: <Color>[
        Color(0xFF7850B4),
        Color(0xFF2C2137),
        Color(0xFF12101A),
      ],
      border: Color(0xFF563D7A),
      surface: <Color>[
        Color(0xFF191420),
        Color(0xFF0B0B12),
      ],
      lightSquare: <Color>[
        Color(0xFF31293C),
        Color(0xFF221B2A),
      ],
      darkSquare: <Color>[
        Color(0xFF120F18),
        Color(0xFF08070D),
      ],
      pattern: ChessSurfacePattern.etched,
      patternColor: Color(0x335A4A8F),
      glow: Color(0x667E55FF),
    ),
    whitePieces: ChessSurfaceMaterial(
      surface: <Color>[
        Color(0xFFF7F4FF),
        Color(0xFFDDD5F8),
        Color(0xFFB8ADEF),
      ],
      highlight: <Color>[
        Color(0xDDFFFFFF),
        Color(0x55FFFFFF),
      ],
      border: Color(0xFF9B8DE1),
      shadow: Color(0x9923183C),
      symbolColor: Color(0xFF171324),
      pattern: ChessSurfacePattern.facets,
      patternColor: Color(0x55946DE2),
    ),
    blackPieces: ChessSurfaceMaterial(
      surface: <Color>[
        Color(0xFF22172D),
        Color(0xFF0B0912),
        Color(0xFF020205),
      ],
      highlight: <Color>[
        Color(0x448E73FF),
        Color(0x11FFFFFF),
      ],
      border: Color(0xFF5A4D8B),
      shadow: Color(0xE8000205),
      symbolColor: Color(0xFFF6F0FF),
      pattern: ChessSurfacePattern.etched,
      patternColor: Color(0x335A3D8D),
    ),
  );

  static const ChessSetTheme aurora = ChessSetTheme(
    id: 'aurora',
    name: 'Aurora Myth',
    unlockLevel: 10,
    tagline: 'Iridescent midnight with a soft spectral glow.',
    accent: Color(0xFF55F2D9),
    board: ChessBoardMaterial(
      frame: <Color>[
        Color(0xFF55F2D9),
        Color(0xFF2D5FBE),
        Color(0xFF101B31),
      ],
      border: Color(0xFF356A88),
      surface: <Color>[
        Color(0xFF0F1728),
        Color(0xFF07101A),
      ],
      lightSquare: <Color>[
        Color(0xFF17253A),
        Color(0xFF101A2A),
      ],
      darkSquare: <Color>[
        Color(0xFF090E18),
        Color(0xFF04070B),
      ],
      pattern: ChessSurfacePattern.aurora,
      patternColor: Color(0x3355F2D9),
      glow: Color(0x6655F2D9),
    ),
    whitePieces: ChessSurfaceMaterial(
      surface: <Color>[
        Color(0xFFF5FCFF),
        Color(0xFFD9EEFF),
        Color(0xFFAFD7FF),
      ],
      highlight: <Color>[
        Color(0xA8FFFFFF),
        Color(0x55FFFFFF),
      ],
      border: Color(0xFF84C8FF),
      shadow: Color(0x88101225),
      symbolColor: Color(0xFF07101A),
      pattern: ChessSurfacePattern.aurora,
      patternColor: Color(0x5597E8FF),
    ),
    blackPieces: ChessSurfaceMaterial(
      surface: <Color>[
        Color(0xFF161C28),
        Color(0xFF0A1018),
        Color(0xFF020408),
      ],
      highlight: <Color>[
        Color(0x3355F2D9),
        Color(0x11FFFFFF),
      ],
      border: Color(0xFF2C6F8E),
      shadow: Color(0xEE020306),
      symbolColor: Color(0xFFEAFBFF),
      pattern: ChessSurfacePattern.aurora,
      patternColor: Color(0x336CE8FF),
    ),
  );

  static const List<ChessSetTheme> all = <ChessSetTheme>[
    chrome,
    crystal,
    gold,
    carbon,
    obsidian,
    aurora,
  ];

  static ChessSetTheme byId(String id) {
    for (final theme in all) {
      if (theme.id == id) {
        return theme;
      }
    }
    return chrome;
  }

  static ChessSetTheme themeForLevel(int level) {
    ChessSetTheme chosen = chrome;
    for (final theme in all) {
      if (level >= theme.unlockLevel) {
        chosen = theme;
      }
    }
    return chosen;
  }

  static List<ChessSetTheme> unlockedForLevel(int level) {
    return all
        .where((theme) => level >= theme.unlockLevel)
        .toList(growable: false);
  }

  static ChessSetTheme? nextLockedTheme(int level) {
    for (final theme in all) {
      if (level < theme.unlockLevel) {
        return theme;
      }
    }
    return null;
  }
}
