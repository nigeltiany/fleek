import 'package:dating/constants.dart';
import 'package:dating/services/helper.dart';
import 'package:flutter/material.dart';

class InterestSelector extends StatefulWidget {

  final TabController tabController;

  const InterestSelector({
    Key key,
    @required this.tabController,
  }) : assert(tabController.length == 3), super(key: key);

  @override
  _InterestSelectorState createState() => _InterestSelectorState(this.tabController);
  
}

class _InterestSelectorState extends State<InterestSelector> {

  int activeTabIndex;
  final TabController tabController;

  _InterestSelectorState(this.tabController);

  @override
  void initState() {
    super.initState();
    activeTabIndex = tabController.index;
    tabController.addListener(() {
      if (mounted) {
        setState(() {
          activeTabIndex = tabController.index;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Looking for",
          style: TextStyle(
            color: isDarkMode(context) ? Colors.white : Colors.black,
            fontSize: 18,
          ),
        ),
        SizedBox(height: 12,),
        Flexible(
          fit: FlexFit.loose,
          child: TabBar(
            controller: tabController,
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
                  child: Text("Dates",
                    style: TextStyle(
                      color: isDarkMode(context) ? (activeTabIndex == 0 ? Colors.white : Color(COLOR_PRIMARY_DARK)) : Colors.black,
                    ),
                  ),
                ),
              ),
              Tab(
                child: Align(
                  alignment: Alignment.center,
                  child: Text("Friends",
                    style: TextStyle(
                      color: isDarkMode(context) ? (activeTabIndex == 1 ? Colors.white : Color(COLOR_PRIMARY_DARK)) : Colors.black,
                    ),
                  ),
                ),
              ),
              Tab(
                child: Align(
                  alignment: Alignment.center,
                  child: Text("Roommates",
                    style: TextStyle(
                      color: isDarkMode(context) ? (activeTabIndex == 2 ? Colors.white : Color(COLOR_PRIMARY_DARK)) : Colors.black,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
