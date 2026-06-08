import 'package:bebezen/mood.dart';
import 'package:bebezen/profile.dart';
import 'package:flutter/material.dart';

class Insights extends StatefulWidget {
  const Insights({super.key});

  @override
  State<Insights> createState() => _InsightsState();
}

class _InsightsState extends State<Insights> with TickerProviderStateMixin {
  static const Color pinkStart = Color(0xFFFFE6F0);
  static const Color pinkMid = Color(0xFFF9D7EB);
  static const Color purple = Color(0xFF6B2E8D);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color primaryText = Color(0xFF1A1A2E);
  static const Color secondaryText = Color(0xFF6B7280);
  static const Color accentPink = Color(0xFFE91E63);
  static const Color accentPurple = Color(0xFF9C27B0);

  late AnimationController _animationController;
  late List<AnimationController> _cardAnimations;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _cardAnimations = List.generate(4, (index) =>
        AnimationController(
          duration: Duration(milliseconds: 600 + (index * 100)),
          vsync: this,
        )
    );

    _animationController.forward();
    for (var controller in _cardAnimations) {
      controller.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    for (var controller in _cardAnimations) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final width = mq.size.width;
    final height = mq.size.height;
    final scale = (width / 375).clamp(0.85, 1.25);

    return Scaffold(

      appBar: _buildModernAppBar(),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFE6F0),
              Color(0xFFF9D7EB),
              Color(0xFFE1BEE7),
            ],
            stops: [0.0, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 520,
                  maxHeight: height - 32,
                ),
                child: _buildCardPanel(context, scale),
              ),
            ),
          ),
        ),
      ),
      //floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      //floatingActionButton: _buildModernFAB(),
    );
  }

  PreferredSizeWidget _buildModernAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child:
      IconButton(onPressed: (){
        Navigator.push(context, MaterialPageRoute(builder: (context) => ProfilePage()));
      },
          icon: Icon(Icons.person_pin_circle_rounded, size: 24, color: accentPink,))
      ),
      title: Container(
        height: 45,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextFormField(
          decoration: InputDecoration(
            hintText: "Search insights...",
            hintStyle: TextStyle(color: secondaryText.withOpacity(0.7)),
            prefixIcon: const Icon(Icons.search, size: 20, color: accentPink),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ),
    );
  }


  Widget _buildCardPanel(BuildContext context, double scale) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        return AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, 50 * (1 - _animationController.value)),
              child: Opacity(
                opacity: _animationController.value,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 80),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(scale),
                      const SizedBox(height: 16),
                      _buildSubtitle(scale),
                      const SizedBox(height: 28),
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            children: [
                              _buildAnimatedCard(0, _buildInsightCard(
                                icon: Icons.analytics_outlined,
                                title: "Cycle Trends",
                                subtitle: "Discover patterns & insights",
                                gradient: [const Color(0xFF667eea), const Color(0xFFFFE6F0)],
                                scale: scale,
                                onTap: () => _navigateToPage("Cycle Trends"),
                              )),
                              const SizedBox(height: 16),
                              _buildAnimatedCard(1, _buildInsightCard(
                                icon: Icons.restaurant_menu_outlined,
                                title: "Nutrition & Wellness",
                                subtitle: "Track your healthy habits",
                                gradient: [const Color(0xFF11998e), const Color(0xFF38ef7d)],
                                scale: scale,
                                onTap: () => _navigateToPage("Nutrition & Wellness"),
                              )),
                              const SizedBox(height: 16),
                              _buildAnimatedCard(2, _buildInsightCard(
                                icon: Icons.psychology_outlined,
                                title: "Mood & Symptoms",
                                subtitle: "Monitor emotional wellness",
                                gradient: [const Color(0xFFfc466b), const Color(0xFF3f5efb)],
                                scale: scale,
                                onTap: (){Navigator.push(context, MaterialPageRoute(builder: (context) => Mood()));}
                              )),
                              const SizedBox(height: 16),
                              _buildAnimatedCard(3, _buildInsightCard(
                                icon: Icons.lightbulb_outline,
                                title: "Personalized Tips",
                                subtitle: "AI-powered recommendations",
                                gradient: [const Color(0xFFf093fb), const Color(0xFFf5576c)],
                                scale: scale,
                                onTap: () => _navigateToPage("Personalized Tips"),
                              )),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAnimatedCard(int index, Widget card) {
    return AnimatedBuilder(
      animation: _cardAnimations[index],
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - _cardAnimations[index].value)),
          child: Opacity(
            opacity: _cardAnimations[index].value,
            child: card,
          ),
        );
      },
    );
  }

  Widget _buildHeader(double scale) {
    return Row(
      children: [
        Hero(
          tag: "insights_icon",
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [accentPink, accentPurple],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: accentPink.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.insights,
                size: 26,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        const Text(
          "Insights",
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: primaryText,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildSubtitle(double scale) {
    return const Text(
      "Your health, your journey ✨",
      style: TextStyle(
        fontWeight: FontWeight.w500,
        fontSize: 16,
        color: secondaryText,
        letterSpacing: 0.2,
      ),
    );
  }

  Widget _buildInsightCard({
    required IconData icon,
    required String title,
    String? subtitle,
    required List<Color> gradient,
    required double scale,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        splashColor: gradient[0].withOpacity(0.1),
        highlightColor: gradient[1].withOpacity(0.05),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: gradient[0].withOpacity(0.1),
                blurRadius: 30,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: gradient[0].withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: primaryText,
                        letterSpacing: -0.2,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 14,
                          color: secondaryText,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: gradient[0].withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.arrow_forward_ios,
                  color: gradient[0],
                  size: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToPage(String pageName) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            DetailPage(title: pageName),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;
          var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text("Add New Insight"),
        content: const Text("What would you like to track today?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: accentPink,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text("Add", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// Detail page for navigation
class DetailPage extends StatelessWidget {
  final String title;

  const DetailPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF1A1A2E),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Hero(
              tag: "insights_icon",
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE91E63), Color(0xFF9C27B0)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE91E63).withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.insights,
                  size: 40,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              title,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "This is your detailed page!\nImplement your specific functionality here.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }
}