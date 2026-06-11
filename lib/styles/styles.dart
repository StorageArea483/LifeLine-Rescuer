import 'package:flutter/material.dart';

class SimpleDecoration {
  static BoxDecoration card() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
    );
  }
}

class AppColors {
  static const Color softBackground = Color(0xFFF7F5F2);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color primaryMaroon = Color(0xFFD97757);
  static const Color accentRose = Color(0xFFD97757);

  static const Color darkCharcoal = Color(
    0xFF1A1A1A,
  ); // Near-black primary text
  static const Color textPrimary = Color(0xFF1A1A1A); // Near-black primary text
  static const Color textSecondary = Color(0xFF6B6860); // Muted warm gray
  static const Color textLight = Color(0xFF6B6860); // Muted warm gray
  static const Color textFooter = Color(0xFF6B6860); // Muted warm gray

  // Border and divider colors
  static const Color borderColor = Color(0xFFE5E2DC); // Soft warm gray
  static const Color shadowLight = Color(0x0A000000); // Subtle shadow

  // Status colors
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFE53935);
  static const Color warning = Color(0xFFFFA726);
  static const Color info = Color(0xFF29B6F6);

  // Legacy aliases
  static const Color background = Color(0xFFF7F5F2);
  static const Color white = Colors.white;
  static const Color primaryBlue = Color(0xFFD97757); // Map to orange
}

// Terms of Service
const String termsOfService =
    'Welcome to LifeLine. By using our disaster relief platform, you agree to the following:\n\n'
    '1) Purpose & Scope: LifeLine is designed to efficiently maintain communication between victims, rescuers, and NGOs/hospitals to coordinate assistance during disasters.\n\n'
    '2) No Emergency Guarantee: We facilitate connections and information-sharing; we cannot guarantee response times, availability of resources, or outcomes. In an immediate life-threatening emergency, contact local authorities.\n\n'
    '3) User Responsibilities: Provide accurate information, avoid impersonation, and use respectful language. Do not misuse features (e.g., spam, false reports).\n\n'
    '4) Data Use: We process the data you provide (e.g., location, needs, contact details) to route help and to improve the service. See the Privacy Policy for details.\n\n'
    '5) Safety: Do not share sensitive personal information publicly. Meet only in safe locations and follow guidance from official responders.\n\n'
    '6) Content: You retain rights to content you submit. You grant LifeLine a limited license to use it for providing and improving services.\n\n'
    '7) Liability: LifeLine and its contributors are not liable for indirect or consequential damages arising from use of the app. The service is provided "as is".\n\n'
    '8) Changes: Terms may be updated. Continued use after updates constitutes acceptance.\n\n'
    'Our intent is to connect victims with rescuers and NGOs as quickly and clearly as possible, and we try our best to provide you the best in our hands.';

const String privacyPolicy =
    'Your privacy matters. This policy explains what we collect and how it is used.\n\n'
    '1) Information We Collect: Account details (name, phone/email), role (victim/rescuer/NGO), incident details, device and app diagnostics, and optional location data.\n\n'
    '2) How We Use Data: To maintain efficient communication between victims, rescuers, and NGOs; prioritize and route assistance; verify activity; prevent abuse; and improve reliability.\n\n'
    '3) Sharing: With responding volunteers/NGOs/authorities strictly for disaster response; with service providers that help us operate the app; when required by law or to prevent harm. We do not sell your personal data.\n\n'
    '4) Location: If you enable location, it may be shared with responders to reach you faster. You can disable it in your device settings.\n\n'
    '5) Data Security: We apply reasonable technical and organizational safeguards; however, no method is 100% secure.\n\n'
    '6) Retention: We keep data only as long as needed for response coordination and legal obligations.\n\n'
    '7) Your Choices: You may request correction or deletion of your data, subject to response record requirements.\n\n'
    '8) Updates: We may revise this policy; continued use means you accept the changes.\n\n'
    'Our intent is to facilitate safe, effective communication between victims, rescuers, and NGOs, and we try our best to provide you the best in our hands.';

class AppDecorations {
  static const double cardRadius = 16;
  static const BorderRadius cardBorderRadius = BorderRadius.all(
    Radius.circular(16),
  );
  static const double textFieldRadius = 12;
  static const BorderRadius textFieldBorderRadius = BorderRadius.all(
    Radius.circular(12),
  );
  static const double primaryButtonRadius = 12;
  static const double submitButtonRadius = 12;

  static const LinearGradient pageLinearGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFF7F5F2), Color(0xFFF7F5F2)], // Solid warm off-white
  );
}

class AppText {
  static const TextStyle base = TextStyle(fontFamily: 'SFPro');

  static const TextStyle appHeader = TextStyle(
    fontFamily: 'SFPro',
    fontWeight: FontWeight.w700,
    fontSize: 18,
    color: AppColors.darkCharcoal,
  );

  static const TextStyle welcomeTitle = TextStyle(
    fontFamily: 'SFPro',
    fontWeight: FontWeight.w700,
    fontSize: 32,
    color: AppColors.darkCharcoal,
  );

  static const TextStyle formTitle = TextStyle(
    fontFamily: 'SFPro',
    fontWeight: FontWeight.w700,
    fontSize: 24,
    color: AppColors.darkCharcoal,
  );

  static const TextStyle subtitle = TextStyle(
    fontFamily: 'SFPro',
    fontWeight: FontWeight.w500,
    fontSize: 16,
    color: AppColors.textSecondary,
  );

  static const TextStyle formDescription = TextStyle(
    fontFamily: 'SFPro',
    fontSize: 14,
    color: AppColors.textSecondary,
  );

  static const TextStyle fieldLabel = TextStyle(
    fontFamily: 'SFPro',
    fontWeight: FontWeight.w600,
    fontSize: 14,
    color: AppColors.darkCharcoal,
  );

  static const TextStyle small = TextStyle(
    fontFamily: 'SFPro',
    fontSize: 14,
    color: AppColors.textSecondary,
  );

  static const TextStyle link = TextStyle(
    fontFamily: 'SFPro',
    fontSize: 14,
    color: AppColors.primaryMaroon,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle submitButton = TextStyle(
    fontFamily: 'SFPro',
    fontWeight: FontWeight.w600,
    fontSize: 16,
    color: Colors.white,
  );

  static const TextStyle textFieldHint = TextStyle(
    fontFamily: 'SFPro',
    color: AppColors.textSecondary,
  );

  // Added from second code (AppTextStyles)
  static const TextStyle title = TextStyle(
    fontFamily: 'SFPro',
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
  );

  static const TextStyle button = TextStyle(
    fontFamily: 'SFPro',
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle footer = TextStyle(
    fontFamily: 'SFPro',
    fontSize: 12,
    color: AppColors.textFooter,
    height: 1.5,
  );

  static const TextStyle footerLink = TextStyle(
    fontFamily: 'SFPro',
    fontSize: 12,
    color: AppColors.textFooter,
    decoration: TextDecoration.underline,
    height: 1.5,
  );

  static const TextStyle sosButton = TextStyle(
    fontFamily: 'SFPro',
    fontSize: 56,
    fontWeight: FontWeight.w900,
    color: AppColors.white,
    letterSpacing: 2,
  );
}

class AppButtons {
  static final ButtonStyle primary = ElevatedButton.styleFrom(
    backgroundColor: AppColors.primaryMaroon,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(9999),
    ), // Pill-shaped
    foregroundColor: Colors.white,
  );

  static final ButtonStyle submit = ElevatedButton.styleFrom(
    backgroundColor: AppColors.primaryMaroon,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(9999),
    ), // Pill-shaped
    foregroundColor: Colors.white,
  );

  static final ButtonStyle dialogAgree = FilledButton.styleFrom(
    backgroundColor: Colors.white,
    foregroundColor: AppColors.primaryMaroon,
    side: const BorderSide(color: AppColors.borderColor, width: 1),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(9999),
    ), // Pill-shaped
  );
}

class AppContainers {
  static const BoxDecoration pageContainer = BoxDecoration(
    gradient: AppDecorations.pageLinearGradient,
  );

  static BoxDecoration get cardContainer => SimpleDecoration.card();
}

class AppTextFields {
  static InputDecoration textFieldDecoration(String hintText) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: AppText.textFieldHint,
      filled: true,
      fillColor: Colors.white,
      border: const OutlineInputBorder(
        borderRadius: AppDecorations.textFieldBorderRadius,
        borderSide: BorderSide(color: AppColors.borderColor, width: 1),
      ),
      enabledBorder: const OutlineInputBorder(
        borderRadius: AppDecorations.textFieldBorderRadius,
        borderSide: BorderSide(color: AppColors.borderColor, width: 1),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: AppDecorations.textFieldBorderRadius,
        borderSide: BorderSide(color: AppColors.primaryMaroon, width: 1),
      ),
      errorBorder: const OutlineInputBorder(
        borderRadius: AppDecorations.textFieldBorderRadius,
        borderSide: BorderSide(color: AppColors.error, width: 1),
      ),
      focusedErrorBorder: const OutlineInputBorder(
        borderRadius: AppDecorations.textFieldBorderRadius,
        borderSide: BorderSide(color: AppColors.error, width: 1),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}

class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double xxxxl = 40;
}

class AppSizes {
  static const double primaryButtonHeight = 56;
  static const double submitButtonHeight = 48;
  static const double iconSize = 24;
  static const double primaryIconSize = 26;
}
