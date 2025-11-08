import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About This App'),
        backgroundColor: Colors.green.shade800,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App Icon / Logo Placeholder

            // Title
            const Text(
              'CEDAR App',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 10),

            const Text(
              'Version 1.0.0',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 30),

            // Description
            const Text(
              'About This App',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'CEDAR App lets you explore a detailed map of tree species across Lebanon. Discover where different trees grow, contributed by researchers and the community.',
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 20),

            // Contribution Section
            const Text(
              'You Can Contribute!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Help your community by drawing polygons around trees near you. Your contributions will help expand the map and protect local biodiversity.',
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 20),

            // Technology Section
            const Text(
              'Technology',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'This app is powered by MapTiler for beautiful, reliable map tiles and geospatial rendering. Data is stored securely in the cloud and updated in real time.',
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 20),

            // Credits
            const Text(
              'Credits',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              '• Map Data & Tiles: MapTiler\n',
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 40),

            // Footer
            Center(
              child: Text(
                'Thank you for helping protect our environment 🌳',
                style: TextStyle(
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                  color: Colors.green.shade700,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
