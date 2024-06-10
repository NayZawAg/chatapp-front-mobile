import 'package:flutter/material.dart';
import 'package:flutter_frontend/constants.dart';
import 'package:flutter_frontend/screens/unreadMessage/unreadWidget/un_read_msg.dart';
import 'package:flutter_frontend/screens/unreadMessage/unreadWidget/un_read_thread.dart';

class unreadMessage extends StatefulWidget {
  const unreadMessage ({Key? key}) : super(key: key);

  @override
  State<unreadMessage> createState() => _unreadMessageState();
}

class _unreadMessageState extends State<unreadMessage> {
  int? isSelected  = 1;
  static List<Widget> pages = [
    
    const UnReadDirectMsg(),
    const UnReadDirectThread(),
    // const unReadDirectGp()
  ];

  @override
  void dispose() {
    // Dispose any resources here
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
       return Scaffold(
        backgroundColor: kPriamrybackground,
      appBar: AppBar(
        title: const Text("Unread Messages",style: TextStyle(color: Colors.white),),
        backgroundColor: navColor, // Corrected typo here
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
                      isSelected = 1;
                    });
                  },
                   style: ButtonStyle(
                    backgroundColor:isSelected==1 ? 
                    MaterialStateProperty.all<Color>(navColor):
                    MaterialStateProperty.all<Color>(kbtn)),
                  child:const  Padding(
                    padding:  EdgeInsets.all(15.0),
                    child:  Text("Unread Direct Message"),
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
                        isSelected = 2;
                      });
                    },
                     style: ButtonStyle(
                      backgroundColor:isSelected==2 ? 
                      MaterialStateProperty.all<Color>(navColor):
                      MaterialStateProperty.all<Color>(kbtn)),
                    child:const  Padding(
                      padding:  EdgeInsets.all(15.0),
                      child:  Text("Unread Direct Threads"),
                    ),
                  ),
                ),
                const SizedBox(
                  width: 20.0,
                ),
                // Padding(
                //   padding: const EdgeInsets.all(8.0),
                //   child: FilledButton(
                //     onPressed: () {
                //       setState(() {
                //         isSelected = 3;
                //       });
                //     },
                //      style: ButtonStyle(
                //       backgroundColor:isSelected==3 ? 
                //       MaterialStateProperty.all<Color>(navColor):
                //       MaterialStateProperty.all<Color>(kPrimarybtnColor)),
                //     child: const  Padding(
                //       padding:  EdgeInsets.all(15.0),
                //       child:  Text("Unread Group Message",style: TextStyle(fontSize: 17)),
                //     ),
                //   ),
                // ),
                
                
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
}