import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/app_header.dart';

class NewScreen extends StatelessWidget {
  const NewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const AppHeader(),
        Expanded(
          child: Center(
            child: Text(
              'New Screen',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
