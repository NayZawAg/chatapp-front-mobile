import 'package:flutter/material.dart';
import 'package:flutter_frontend/constants.dart';
import 'package:flutter_frontend/model/SessionStore.dart';
import 'package:flutter_frontend/componnets/customlogout.dart';
import 'package:flutter_frontend/screens/Mention/MentionWidget/group_mention.dart';
import 'package:flutter_frontend/screens/Mention/MentionWidget/group_thread_mention.dart';

class MentionBody extends StatefulWidget {
  const MentionBody({Key? key}) : super(key: key);

  @override
  State<MentionBody> createState() => _MentionBodyState();
}

class _MentionBodyState extends State<MentionBody> {
  static List<Widget> pages = [
    const GroupMessages(),
    const GroupThreads(),
  ];

  int? isSelected = 1;

  @override
  void dispose() {
    // Dispose any resources here
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if(SessionStore.sessionData!.currentUser!.memberStatus == true){
      return Scaffold(
      backgroundColor: kPriamrybackground,
      appBar: AppBar(
        title: const Text("Mention Lists",style: TextStyle(color: kPriamrybackground,fontWeight: FontWeight.bold),),
        backgroundColor: navColor,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: FilledButton(
                      onPressed: () {
                        setState(() {
                          isSelected = 1;
                        });
                      },
                      style: ButtonStyle(
                        backgroundColor: isSelected ==1?
                        MaterialStateProperty.all<Color>(navColor):
                        MaterialStateProperty.all<Color>(kbtn),
                        minimumSize: MaterialStateProperty.all(const Size(120, 50))
                      ),
                      child: const  Padding(
                        padding:  EdgeInsets.all(15.0),
                        child:  Text("Group Mentions"),
                      )
                      ),
                ),
                const SizedBox(width: 20,),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: FilledButton(
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
                        child:  Text("Group Thread Mentions"),
                      )),
                )
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
