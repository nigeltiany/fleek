import 'package:dating/constants.dart';
import 'package:dating/services/helper.dart';
import 'package:flutter/material.dart';

class OrientationSelector extends StatefulWidget {

  final TabController tabController;

  const OrientationSelector({
    Key key,
    @required this.tabController,
  }) : assert(tabController.length == 3), super(key: key);

  @override
  _OrientationSelectorState createState() => _OrientationSelectorState();
}

class _OrientationSelectorState extends State<OrientationSelector> {

  int activeTabIndex;

  @override
  void initState() {
    super.initState();
    activeTabIndex = widget.tabController.index;
    widget.tabController.addListener(() {
      setState(() {
        activeTabIndex = widget.tabController.index;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Interested in",
          style: TextStyle(
            color: isDarkMode(context) ? Colors.white : Colors.black,
            fontSize: 18,
          ),
        ),
        SizedBox(height: 12,),
        TabBar(
          controller: widget.tabController,
          unselectedLabelColor: Color(COLOR_PRIMARY),
          indicatorSize: TabBarIndicatorSize.tab,
          indicator: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(COLOR_PRIMARY_DARK), Color(COLOR_PRIMARY)],
              ),
              borderRadius: BorderRadius.circular(50),
              color: Color(COLOR_PRIMARY_DARK)
          ),
          tabs: [
            Tab(
              child: Align(
                alignment: Alignment.center,
                child: Text("Guys",
                  style: TextStyle(
                    color: isDarkMode(context) ? (activeTabIndex == 0 ? Colors.white : Color(COLOR_PRIMARY_DARK)) : Colors.black,
                  ),
                ),
              ),
            ),
            Tab(
              child: Align(
                alignment: Alignment.center,
                child: Text("Ladies",
                  style: TextStyle(
                    color: isDarkMode(context) ? (activeTabIndex == 1 ? Colors.white : Color(COLOR_PRIMARY_DARK)) : Colors.black,
                  ),
                ),
              ),
            ),
            Tab(
              child: Align(
                alignment: Alignment.center,
                child: Text("Everyone",
                  style: TextStyle(
                    color: isDarkMode(context) ? (activeTabIndex == 2 ? Colors.white : Color(COLOR_PRIMARY_DARK)) : Colors.black,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
