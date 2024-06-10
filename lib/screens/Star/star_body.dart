import 'package:flutter/material.dart';
import 'package:flutter_frontend/constants.dart';
import 'package:flutter_frontend/model/SessionState.dart';
import 'package:flutter_frontend/model/SessionStore.dart';
import 'package:flutter_frontend/componnets/customlogout.dart';
import 'package:flutter_frontend/screens/Star/starsWidget/group_star.dart';
import 'package:flutter_frontend/screens/Star/starsWidget/direct_star.dart';
import 'package:flutter_frontend/screens/Star/starsWidget/group_thread_star.dart';
import 'package:flutter_frontend/screens/Star/starsWidget/direct_thread_star.dart';

class StarBody extends StatefulWidget {
  const StarBody({Key? key}) : super(key: key);

  @override
  State<StarBody> createState() => _StarBodyState();
}

class _StarBodyState extends State<StarBody> {
  int? isSelected = 1;
  static List<Widget> pages = [
    const DirectStars(),
    const DirectThreadStars(),
    const GroupStarWidget(),
    const GroupThreadStar()
  ];
  @override
  void dispose() {
    // Dispose any resources here
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if(SessionStore.sessionData!.currentUser!.memberStatus == true ) {
      return Scaffold(
      backgroundColor: kPriamrybackground,
      appBar: AppBar(
        title: const Text("Stars Lists",style: TextStyle(color: kPriamrybackground,fontWeight: FontWeight.bold),),
        backgroundColor: navColor, // Corrected typo here
        automaticallyImplyLeading: false,
        
      ),
      body: Column(
        children: [
          const SizedBox(height: 10,),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilledButton(
                  onPressed: () {
                    setState(() {
                      isSelected = 1;
                    });
                  },style: ButtonStyle(
                        backgroundColor: isSelected ==1?
                        MaterialStateProperty.all<Color>(navColor):
                        MaterialStateProperty.all<Color>(kbtn),
                        minimumSize: MaterialStateProperty.all(const Size(120, 50))
                      ),
                  child: const  Padding(
                        padding:  EdgeInsets.all(15.0),
                        child:  Text("Direct Star"),
                      )
                ),
                const SizedBox(
                  width: 20.0,
                ),
                FilledButton(
                  onPressed: () {
                    setState(() {
                      isSelected = 2;
                    });
                  },
                  style: ButtonStyle(
                        backgroundColor: isSelected ==2?
                        MaterialStateProperty.all<Color>(navColor):
                        MaterialStateProperty.all<Color>(kbtn),
                        minimumSize: MaterialStateProperty.all(const Size(120, 50))
                      ),
                 child: const  Padding(
                        padding:  EdgeInsets.all(15.0),
                        child:  Text("Direct Thread Star"),
                      )
                ),
                const SizedBox(
                  width: 20.0,
                ),
                FilledButton(
                  onPressed: () {
                    setState(() {
                      isSelected = 3;
                    });
                  },
                  style: ButtonStyle(
                        backgroundColor: isSelected ==3?
                        MaterialStateProperty.all<Color>(navColor):
                        MaterialStateProperty.all<Color>(kbtn),
                        minimumSize: MaterialStateProperty.all(const Size(120, 50))
                      ),
                  child: const  Padding(
                        padding: const EdgeInsets.all(15.0),
                        child: const Text("Group Star"),
                      )
                ),
                const SizedBox(
                  width: 20.0,
                ),
                FilledButton(
                  onPressed: () {
                    setState(() {
                      isSelected = 4;
                    });
                  },style: ButtonStyle(
                        backgroundColor: isSelected ==4?
                        MaterialStateProperty.all<Color>(navColor):
                        MaterialStateProperty.all<Color>(kbtn),
                        minimumSize: MaterialStateProperty.all(const Size(120, 50))
                      ),
                  child: const  Padding(
                        padding: const EdgeInsets.all(15.0),
                        child: const Text("Group Thread Star"),
                      )
                ),
              ],
            ),
          ),
          if (isSelected != null)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: pages[isSelected! - 1],
              ),
            )
        ],
      ),
    );
    }
    else {
      return CustomLogOut();
    }
    
  }
}
