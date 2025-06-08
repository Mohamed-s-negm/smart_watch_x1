import 'package:flutter/material.dart';
import '../widgets/feature_card.dart';
import '../widgets/health_stats.dart';
import '../widgets/quick_actions.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            floating: true,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Smart Watch X1',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF4EA8DE),
                      Color(0xFF22223B),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const HealthStats(),
                  const SizedBox(height: 24),
                  Text(
                    'Features',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    children: const [
                      FeatureCard(
                        title: 'Music',
                        icon: Icons.music_note,
                        color: Color(0xFF4EA8DE),
                      ),
                      FeatureCard(
                        title: 'Alarm',
                        icon: Icons.alarm,
                        color: Color(0xFFE57373),
                      ),
                      FeatureCard(
                        title: 'Settings',
                        icon: Icons.settings,
                        color: Color(0xFF81C784),
                      ),
                      FeatureCard(
                        title: 'Health',
                        icon: Icons.favorite,
                        color: Color(0xFFFFB74D),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const QuickActions(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
} 