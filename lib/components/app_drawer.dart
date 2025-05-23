import 'package:flutter/material.dart';
import 'package:habitap/pages/analytics_page.dart';
import 'package:habitap/pages/settings_page.dart';
import 'package:habitap/themes/theme_provider.dart';
import 'package:provider/provider.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          // Header Section with SVG
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, _) => Container(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 0),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // SVG Logo - Replace with your own SVG
                  /*SvgPicture.asset(
                    'assets/icon/Activity_Logo.svg',  // Replace with your SVG path
                    height: 80,
                    width: 80,
                    colorFilter: ColorFilter.mode(
                      Colors.green,
                      BlendMode.srcIn,
                    ),
                  ),*/
                  const SizedBox(height: 16),
                  Image.asset(
                    'assets/icon/ic_launcher.png',
                    width: 100,
                    height: 100,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'HABITAP',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.inversePrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3,
                    ),
                  ),
                  Text(
                    'BUILD BETTER HABITS',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 50,),
          // Menu Items List
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // HOME menu item
                ListTile(
                  leading: const Icon(
                    Icons.home,
                    color: Colors.grey,
                    size: 28,
                  ),
                  title: Text(
                    'H O M E',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.inversePrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    // Add navigation action here
                  },
                ),

                // SETTINGS menu item
                ListTile(
                  leading: const Icon(
                    Icons.settings,
                    color: Colors.grey,
                    size: 28,
                  ),
                  title: Text(
                    'S E T T I N G S',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.inversePrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    // Add navigation action here
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SettingsScreen()),
                    );
                  },
                ),

                // ANALYTICS menu item
                ListTile(
                  leading: const Icon(
                    Icons.bar_chart,
                    color: Colors.grey,
                    size: 28,
                  ),
                  title: Text(
                    'A N A L Y T I C S',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.inversePrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    // Navigate to analytics page
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AnalyticsPage()),
                    );
                  },
                ),

                /*ListTile(
                  leading: const Icon(
                    Icons.code,
                    color: Colors.grey,
                    size: 28,
                  ),
                  title: Text(
                    'A B O U T',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.inversePrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),*/
              ],
            ),
          ),

          // Theme toggle at bottom (replacing LOGOUT)
          Padding(
            padding: const EdgeInsets.only(bottom: 40.0),
            child: ListTile(
              leading: Consumer<ThemeProvider>(
                builder: (context, themeProvider, _) => Icon(
                  themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                  color: Colors.grey,
                  size: 28,
                ),
              ),
              title: Text(
                'THEME',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.inversePrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              trailing: Consumer<ThemeProvider>(
                builder: (context, themeProvider, _) => Switch(
                  activeTrackColor: Colors.green,
                  value: themeProvider.isDarkMode,
                  onChanged: (value) {
                    themeProvider.toggleTheme();
                  },
                  activeColor: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}