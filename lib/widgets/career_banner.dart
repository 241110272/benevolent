import 'dart:ui';
import 'package:flutter/material.dart';
import '../main.dart';

class CareerBanner extends StatelessWidget {
  const CareerBanner({super.key, required this.onTap, this.compact = false});
  final VoidCallback onTap;
  final bool compact;
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: compact ? 'Lihat lowongan remote' : 'Jelajahi lowongan',
    child: GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(compact ? 19 : 24),
        child: SizedBox(
          height:
              (compact
                  ? (MediaQuery.sizeOf(context).width < 360 ? 160 : 140)
                  : (MediaQuery.sizeOf(context).width < 360 ? 260 : 246)) *
              MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 2.0),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                'assets/images/career-coworking.png',
                fit: BoxFit.cover,
                alignment: compact
                    ? const Alignment(.2, -.2)
                    : const Alignment(.55, 0),
                excludeFromSemantics: true,
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      plum.withValues(alpha: .82),
                      plum.withValues(alpha: .34),
                      plum.withValues(alpha: .02),
                    ],
                    stops: const [0, .55, 1],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(compact ? 17 : 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      compact
                          ? 'Bekerja dari\nmana saja'
                          : 'Peluang baru\nmenantimu.',
                      style: TextStyle(
                        fontSize: compact ? 22 : 29,
                        height: 1.05,
                        letterSpacing: -.9,
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      compact
                          ? 'Temukan peluang remote\ndari berbagai perusahaan.'
                          : 'Temukan pekerjaan\nsesuai minatmu.',
                      style: TextStyle(
                        color: Colors.white,
                        height: 1.35,
                        fontSize: compact ? 11 : 13,
                      ),
                    ),
                    if (!compact) ...[
                      const SizedBox(height: 15),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 13,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: .25),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: .5),
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    'Jelajahi lowongan',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 16),
                                Icon(
                                  Icons.arrow_forward,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (compact)
                Positioned(
                  right: 14,
                  bottom: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: lavender,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'REMOTE',
                      style: TextStyle(
                        color: ink,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}
