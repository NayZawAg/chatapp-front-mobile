import 'package:flutter/material.dart';
import 'package:flutter_frontend/constants.dart';
import 'package:flutter_frontend/model/SessionState.dart';
import 'package:flutter_frontend/model/SessionStore.dart';
import 'package:flutter_frontend/componnets/customlogout.dart';
import 'package:flutter_frontend/screens/threadMessage/threadWidget/GroupThread.dart';
import 'package:flutter_frontend/screens/threadMessage/threadWidget/directThread.dart';

class ThreadList extends StatefulWidget {
  const ThreadList({Key? key}) : super(key: key);

  @override
  State<ThreadList> createState() => _ThreadListState();
}

class _ThreadListState extends State<ThreadList> {
  int? selectedIndex = 1;
  static List<Widget> pages = [
    const DirectThread(),
    const GroupThread(),
  ];
  @override
  void dispose() {
    // Dispose any resources here
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // final screenSize = MediaQuery.of(context).size;
    if(SessionStore.sessionData!.currentUser!.memberStatus == false){
      return CustomLogOut();
    }
    else {
      
      return Scaffold(
     backgroundColor: kPriamrybackground,
      appBar: AppBar(
        title: const Text(
          "Thread List",
          style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold),
        ),
        backgroundColor: navColor,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilledButton(
                  onPressed: () {
                    setState(() {
                      selectedIndex = 1;
                    });
                  },
                  style: ButtonStyle(
                      backgroundColor: selectedIndex == 1
                          ? MaterialStateProperty.all<Color>(navColor)
                          : MaterialStateProperty.all<Color>(
                              kbtn),
                      minimumSize:
                          MaterialStateProperty.all(const Size(120, 50))),
                  child: const Padding(
                    padding:  EdgeInsets.all(15.0),
                    child:  Text(
                      "Direct Threads",
                    
                    ),
                  ),
                ),
                const SizedBox(
                  width: 20.0,
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: FilledButton(
                    onPressed: () {
                      setState(() {
                        selectedIndex = 2;
                      });
                    },
                    style: ButtonStyle(
                      backgroundColor: selectedIndex == 2
                          ? MaterialStateProperty.all<Color>(navColor)
                          : MaterialStateProperty.all<Color>(
                              kbtn),
                    ),
                    child: const  Padding(
                      padding:  EdgeInsets.all(15.0),
                      child:  Text(
                        "Group Threads",
                        
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (selectedIndex != null)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: pages[selectedIndex! - 1],
              ),
            )
        ],
      ),
    );
    }
  }
}
