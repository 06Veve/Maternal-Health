import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Admin Dashboard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'Roboto',
      ),
      home: AdminDashboard(),
    );
  }
}

class AdminDashboard extends StatefulWidget {
  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
    with TickerProviderStateMixin {
  int _selectedIndex = 0;
  bool _isCollapsed = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _animationController.reset();
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          AnimatedContainer(
            duration: Duration(milliseconds: 200),
            width: _isCollapsed ? 80 : 280,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.pinkAccent,
                    Colors.pink,
                    Colors.pink.shade200,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: Offset(2, 0),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    height: 100,
                    padding: EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.blue[400]!, Colors.purple[400]!],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.admin_panel_settings,
                              color: Colors.white, size: 24),
                        ),
                        if (!_isCollapsed) ...[
                          SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Admin Panel',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Dashboard',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        IconButton(
                          icon: Icon(
                            _isCollapsed ? Icons.menu : Icons.menu_open,
                            color: Colors.white70,
                          ),
                          onPressed: () {
                            setState(() {
                              _isCollapsed = !_isCollapsed;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  Divider(color: Colors.white24, height: 1),
                  // Menu Items
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      children: [
                        _buildMenuItem(
                          icon: Icons.people,
                          title: 'Manage Users',
                          index: 0,
                        ),
                        _buildMenuItem(
                          icon: Icons.content_copy,
                          title: 'Manage Content',
                          index: 1,
                        ),
                      ],
                    ),
                  ),
                  // Footer
                  if (!_isCollapsed)
                    Container(
                      padding: EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Divider(color: Colors.white24),
                          SizedBox(height: 10),
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundImage:
                                NetworkImage('https://via.placeholder.com/40'),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Admin User',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      'Administrator',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          // Main Content
          Expanded(
            child: Container(
              color: Color(0xFFF8F9FA),
              child: Column(
                children: [
                  // Top Bar
                  Container(
                    height: 80,
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Text(
                          _getPageTitle(),
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        Spacer(),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.blue[400]!, Colors.purple[400]!],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.notifications, color: Colors.white, size: 18),
                              SizedBox(width: 8),
                              Text(
                                '3',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Page Content
                  Expanded(
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Container(
                        padding: EdgeInsets.all(30),
                        child: _buildPageContent(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required int index,
  }) {
    bool isSelected = _selectedIndex == index;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _onItemTapped(index),
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isSelected
                ? Colors.white.withOpacity(0.1)
                : Colors.transparent,
            border: isSelected
                ? Border.all(color: Colors.white.withOpacity(0.2))
                : null,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : Colors.white70,
                size: 22,
              ),
              if (!_isCollapsed) ...[
                SizedBox(width: 20),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.blue[400],
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _getPageTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'Manage Users';
      case 1:
        return 'Manage Content';
      default:
        return 'Dashboard';
    }
  }

  Widget _buildPageContent() {
    switch (_selectedIndex) {
      case 0:
        return _buildUsersPage();
      case 1:
        return _buildContentPage();
      default:
        return Container();
    }
  }

  Widget _buildUsersPage() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats Cards
          Row(
            children: [
              Expanded(child: _buildStatCard('Total Users', '1,234', Icons.people, Colors.blue)),
              SizedBox(width: 20),
              Expanded(child: _buildStatCard('Active Users', '987', Icons.people_alt, Colors.green)),
              SizedBox(width: 20),
              Expanded(child: _buildStatCard('New Users', '45', Icons.person_add, Colors.orange)),
              SizedBox(width: 20),
              Expanded(child: _buildStatCard('Blocked Users', '12', Icons.block, Colors.red)),
            ],
          ),
          SizedBox(height: 30),
          // Users Table
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.all(25),
                  child: Row(
                    children: [
                      Text(
                        'Users List',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                      Spacer(),
                      ElevatedButton.icon(
                        onPressed: () {},
                        icon: Icon(Icons.add),
                        label: Text('Add User'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[400],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1),
                ..._buildUserRows(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentPage() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats Cards
          Row(
            children: [
              Expanded(child: _buildStatCard('Total Content', '567', Icons.article, Colors.purple)),
              SizedBox(width: 20),
              Expanded(child: _buildStatCard('Published', '432', Icons.check_circle, Colors.green)),
              SizedBox(width: 20),
              Expanded(child: _buildStatCard('Draft', '89', Icons.drafts, Colors.orange)),
              SizedBox(width: 20),
              Expanded(child: _buildStatCard('Archived', '46', Icons.archive, Colors.grey)),
            ],
          ),
          SizedBox(height: 30),
          // Content Table
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.all(25),
                  child: Row(
                    children: [
                      Text(
                        'Content List',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                      Spacer(),
                      ElevatedButton.icon(
                        onPressed: () {},
                        icon: Icon(Icons.add),
                        label: Text('Add Content'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple[400],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1),
                ..._buildContentRows(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              Spacer(),
              Icon(Icons.trending_up, color: Colors.green, size: 20),
            ],
          ),
          SizedBox(height: 20),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
          SizedBox(height: 5),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildUserRows() {
    List<Map<String, dynamic>> users = [
      {'name': 'John Doe', 'email': 'john@example.com', 'role': 'Admin', 'status': 'Active'},
      {'name': 'Jane Smith', 'email': 'jane@example.com', 'role': 'Editor', 'status': 'Active'},
      {'name': 'Mike Johnson', 'email': 'mike@example.com', 'role': 'User', 'status': 'Inactive'},
      {'name': 'Sarah Wilson', 'email': 'sarah@example.com', 'role': 'Moderator', 'status': 'Active'},
    ];

    return users.map((user) => Container(
      padding: EdgeInsets.symmetric(horizontal: 25, vertical: 15),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.blue[100],
            child: Text(user['name'][0], style: TextStyle(color: Colors.blue[600])),
          ),
          SizedBox(width: 15),
          Expanded(
            flex: 2,
            child: Text(user['name'], style: TextStyle(fontWeight: FontWeight.w500)),
          ),
          Expanded(
            flex: 3,
            child: Text(user['email'], style: TextStyle(color: Colors.grey[600])),
          ),
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(15),
              ),
              child: Text(
                user['role'],
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.blue[600], fontSize: 12),
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: user['status'] == 'Active' ? Colors.green[50] : Colors.red[50],
                borderRadius: BorderRadius.circular(15),
              ),
              child: Text(
                user['status'],
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: user['status'] == 'Active' ? Colors.green[600] : Colors.red[600],
                  fontSize: 12,
                ),
              ),
            ),
          ),
          PopupMenuButton(
            icon: Icon(Icons.more_vert),
            itemBuilder: (context) => [
              PopupMenuItem(child: Text('Edit'), value: 'edit'),
              PopupMenuItem(child: Text('Delete'), value: 'delete'),
            ],
          ),
        ],
      ),
    )).toList();
  }

  List<Widget> _buildContentRows() {
    List<Map<String, dynamic>> content = [
      {'title': 'Getting Started Guide', 'type': 'Article', 'status': 'Published', 'date': '2024-01-15'},
      {'title': 'Product Update v2.1', 'type': 'News', 'status': 'Draft', 'date': '2024-01-14'},
      {'title': 'User Tutorial Video', 'type': 'Video', 'status': 'Published', 'date': '2024-01-13'},
      {'title': 'FAQ Section', 'type': 'Documentation', 'status': 'Published', 'date': '2024-01-12'},
    ];

    return content.map((item) => Container(
      padding: EdgeInsets.symmetric(horizontal: 25, vertical: 15),
      child: Row(
        children: [
          Icon(
            item['type'] == 'Video' ? Icons.play_circle : Icons.article,
            color: Colors.purple[400],
          ),
          SizedBox(width: 15),
          Expanded(
            flex: 3,
            child: Text(item['title'], style: TextStyle(fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.purple[50],
                borderRadius: BorderRadius.circular(15),
              ),
              child: Text(
                item['type'],
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.purple[600], fontSize: 12),
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: item['status'] == 'Published' ? Colors.green[50] : Colors.orange[50],
                borderRadius: BorderRadius.circular(15),
              ),
              child: Text(
                item['status'],
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: item['status'] == 'Published' ? Colors.green[600] : Colors.orange[600],
                  fontSize: 12,
                ),
              ),
            ),
          ),
          Expanded(
            child: Text(
              item['date'],
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
          PopupMenuButton(
            icon: Icon(Icons.more_vert),
            itemBuilder: (context) => [
              PopupMenuItem(child: Text('Edit'), value: 'edit'),
              PopupMenuItem(child: Text('Archive'), value: 'archive'),
              PopupMenuItem(child: Text('Delete'), value: 'delete'),
            ],
          ),
        ],
      ),
    )).toList();
  }
}