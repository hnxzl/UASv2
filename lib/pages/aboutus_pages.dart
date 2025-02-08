import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tododo/auth/auth_service.dart';

class AboutUsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("About Us"),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Icon(
                Icons.info_outline,
                size: 80,
                color: Colors.blueAccent,
              ),
            ),
            SizedBox(height: 20),
            Text(
              "Tentang Kami",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),
            SizedBox(height: 10),
            Text(
              "Kami adalah platform yang menyediakan berita terbaru seputar Anime dan E-sport. "
              "Kami berkomitmen untuk memberikan informasi yang akurat dan menarik bagi para penggemar.",
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.justify,
            ),
            SizedBox(height: 20),
            Text(
              "Hubungi Kami:",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.email, color: Colors.blueAccent),
                SizedBox(width: 10),
                Text("contact@animeesport.com"),
              ],
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.web, color: Colors.blueAccent),
                SizedBox(width: 10),
                Text("www.animeesport.com"),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
